-- Focused Transparency: dim unfocused windows relative to the normal
-- configured window opacity.
--
-- Offset 0-100 lives in ~/.local/state/caelestia/focus-sizing. That filename
-- is kept for compatibility with the old slider state; the feature no longer
-- resizes windows.
-- At 0 all managed windows use the normal base opacity. At 100 unfocused
-- windows are reduced down to MIN_OPACITY; the cursor-hovered/focused window
-- stays at the base opacity.
--
-- NB: the previous implementation used max_size. We only ever clear that
-- legacy property numerically; do not use "unset" here.

local ok_vars, vars = pcall(require, "variables")

local M = { offset = 0 }
_G.FocusTransparency = M

local STATE_FILE = os.getenv("HOME") .. "/.local/state/caelestia/focus-sizing"
local LEGACY_HUGE = "99999 99999"
local BASE_OPACITY = tonumber(ok_vars and vars and vars.windowOpacity) or 1
local MIN_OPACITY = 0.45

BASE_OPACITY = math.max(0.05, math.min(1, BASE_OPACITY))
MIN_OPACITY = math.max(0.05, math.min(BASE_OPACITY, MIN_OPACITY))

local function read_state()
    local f = io.open(STATE_FILE)
    if not f then return 0 end
    local n = tonumber(f:read("*a"))
    f:close()
    return math.max(0, math.min(100, math.floor(n or 0)))
end

local function write_state(n)
    local f = io.open(STATE_FILE, "w")
    if f then
        f:write(tostring(n))
        f:close()
    end
end

local function xy(v)
    if type(v) ~= "table" then return nil, nil end
    return tonumber(v.x or v[1]), tonumber(v.y or v[2])
end

local function eligible(win)
    local ok, r = pcall(function()
        return win.mapped and not win.hidden and not win.pinned and win.fullscreen == 0
    end)
    return ok and r
end

local function window_workspace_id(win)
    local ok, id = pcall(function() return win.workspace and win.workspace.id end)
    if ok then return id end
end

local function cursor_workspace_id()
    local ok, mon = pcall(hl.get_monitor_at_cursor)
    if ok and mon and mon.active_workspace then
        local id = mon.active_workspace.id
        if id and id > 0 then return id end
    end

    ok, mon = pcall(hl.get_active_monitor)
    if ok and mon and mon.active_workspace then
        local id = mon.active_workspace.id
        if id and id > 0 then return id end
    end
end

local function active_window()
    local ok, win = pcall(hl.get_active_window)
    if ok and win then return win end
end

local function active_workspace_id()
    local active = active_window()
    local id = active and window_workspace_id(active)
    if id and id > 0 then return id end
    return cursor_workspace_id()
end

local function workspace_windows(ws_id)
    local ok, wins = pcall(hl.get_workspace_windows, ws_id)
    if ok and type(wins) == "table" then return wins end
    return {}
end

local function window_under_cursor(ws_id)
    local ok, pos = pcall(hl.get_cursor_pos)
    local cx, cy = xy(ok and pos or nil)
    if not cx or not cy then return nil end

    for _, w in ipairs(workspace_windows(ws_id)) do
        if eligible(w) then
            local x, y = xy(w.at)
            local sx, sy = xy(w.size)
            if x and y and sx and sy and cx >= x and cx < x + sx and cy >= y and cy < y + sy then
                return w
            end
        end
    end
end

local function focused_for_workspace(ws_id)
    if active_workspace_id() == ws_id then
        local hovered = window_under_cursor(ws_id)
        if hovered then return hovered.address end
    end

    local active = active_window()
    if active and window_workspace_id(active) == ws_id then
        return active.address
    end
end

local function opacity_for_unfocused()
    local range = BASE_OPACITY - MIN_OPACITY
    return math.max(MIN_OPACITY, BASE_OPACITY - range * (M.offset / 100))
end

local function set_opacity(win, value)
    local v = string.format("%.3f override", value)

    pcall(hl.dispatch, hl.dsp.window.set_prop({
        prop = "opacity",
        value = v,
        window = "address:" .. win.address,
    }))
end

local function clear_legacy_size_limit(win)
    pcall(hl.dispatch, hl.dsp.window.set_prop({
        prop = "max_size",
        value = LEGACY_HUGE,
        window = "address:" .. win.address,
    }))
end

local function apply(ws_id, focused)
    if focused == nil then focused = focused_for_workspace(ws_id) end
    local unfocused_opacity = opacity_for_unfocused()

    for _, w in ipairs(workspace_windows(ws_id)) do
        if eligible(w) then
            if M.offset == 0 or w.address == focused then
                set_opacity(w, BASE_OPACITY)
            else
                set_opacity(w, unfocused_opacity)
            end
        end
    end
end

local function each_workspace(fn)
    local ok, wss = pcall(hl.get_workspaces)
    if not ok or type(wss) ~= "table" then return end
    for _, ws in ipairs(wss) do
        local okid, id = pcall(function() return ws.id end)
        if okid and id and id > 0 then fn(id) end
    end
end

local function apply_all()
    each_workspace(apply)
end

local function dim_workspace(ws_id)
    if ws_id then apply(ws_id, false) end
end

local function reset_all()
    local ok, wins = pcall(hl.get_windows)
    if not ok or type(wins) ~= "table" then return end

    for _, w in ipairs(wins) do
        if eligible(w) then
            set_opacity(w, BASE_OPACITY)
        end
        pcall(clear_legacy_size_limit, w)
    end
end

local function on_state_changed(n)
    M.offset = n
    if n == 0 then
        reset_all()
    else
        apply_all()
        M.focus_key = nil
    end
end

local function apply_current_focus(force)
    if M.offset == 0 then return end
    local ws_id = active_workspace_id()
    if not ws_id then return end

    if M.current_ws and M.current_ws ~= ws_id then
        dim_workspace(M.current_ws)
    end

    local focused = focused_for_workspace(ws_id)
    local active = active_window()
    local active_addr = active and active.address or ""
    local key = tostring(ws_id) .. ":" .. tostring(focused or "") .. ":" .. tostring(active_addr)
    if not force and key == M.focus_key then return end

    M.current_ws = ws_id
    M.focus_key = key
    apply(ws_id, focused)
end

function M.set(n)
    n = math.max(0, math.min(100, math.floor(tonumber(n) or 0)))
    write_state(n)
    on_state_changed(n)
end

hl.on("window.active", function()
    apply_current_focus(true)
end)

hl.on("window.open", function(win)
    if not win then return end
    pcall(clear_legacy_size_limit, win)

    local ws = window_workspace_id(win)
    if ws then apply(ws) end
    apply_current_focus(true)
end)

hl.on("window.close", function()
    if M.offset > 0 then
        M.focus_key = nil
        apply_all()
        apply_current_focus(true)
    end
end)

hl.on("window.move_to_workspace", function()
    if M.offset > 0 then
        M.focus_key = nil
        apply_all()
        apply_current_focus(true)
    end
end)

hl.on("workspace.active", function(ws)
    if M.current_ws then dim_workspace(M.current_ws) end
    local ok, id = pcall(function() return ws and ws.id end)
    if ok and id then apply(id) end
    apply_current_focus(true)
end)

hl.on("window.fullscreen", function(win)
    if not win then return end
    if eligible(win) then
        local ws = window_workspace_id(win)
        if ws then apply(ws) end
    else
        set_opacity(win, BASE_OPACITY)
    end
end)

M.offset = read_state()
reset_all()
if M.offset > 0 then
    apply_all()
    apply_current_focus(true)
    hl.timer(function()
        apply_all()
        apply_current_focus(true)
    end, { type = "oneshot", timeout = 1000 })
end

hl.timer(function()
    local n = read_state()
    if n ~= M.offset then on_state_changed(n) end
    apply_current_focus(false)
end, { type = "repeat", timeout = 200 })

hl.timer(function()
    if M.offset == 0 then return end
    apply_all()
    apply_current_focus(true)
end, { type = "repeat", timeout = 1000 })
