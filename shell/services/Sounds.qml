pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import QtMultimedia
import Quickshell
import Quickshell.Io
import qs.components.misc
import qs.services

// Shell-wide UI sound service. Call `Sounds.play("event")` from anywhere.
// Soft & organic pack lives in assets/sounds/ui/<pack>/. Designed to be
// non-invasive: per-event cooldowns, a startup guard, and suppression during
// game mode / do-not-disturb.
Singleton {
    id: root

    // ---- config (backed by ~/.config/caelestia/sounds.json) ---------------
    property bool enabled: true
    property real volume: 0.6
    property string pack: "keys"
    property var categories: ({
            hover: 0.7,
            ui: 1.0,
            osd: 0.8,
            system: 1.0
        })

    readonly property url dir: Qt.resolvedUrl("../assets/sounds/ui/" + pack + "/")

    // event -> [category, cooldownMs, gain, variants]. Cooldown throttles
    // machine-gunning; gain trims individual cues; variants>1 round-robins
    // <event>_0..<event>_(n-1).wav so rapid repeats don't sound identical.
    readonly property var events: ({
            "hover": ["hover", 45, 0.9, 4],
            "click": ["ui", 22, 1.0, 3],
            "tick": ["osd", 22, 0.9, 3],
            "toggle-on": ["ui", 30, 1.0, 1],
            "toggle-off": ["ui", 30, 1.0, 1],
            "panel-open": ["ui", 40, 1.0, 1],
            "panel-close": ["ui", 40, 1.0, 1],
            "lock": ["system", 200, 1.0, 1],
            "unlock": ["system", 200, 1.0, 1],
            "screenshot": ["system", 150, 1.0, 1],
            "charge-plug": ["system", 300, 1.0, 1],
            "charge-unplug": ["system", 300, 1.0, 1],
            "error": ["ui", 150, 1.0, 1]
        })

    // ---- internals --------------------------------------------------------
    property bool ready: false
    property var _sfx: ({})   // event -> [SoundEffect, ...] pool
    property var _rr: ({})    // event -> round-robin index
    property var _last: ({})  // event -> last-played ms

    // flat list "event|file" expanding variants, used to build the pools
    readonly property var _files: {
        const out = [];
        for (const name in events) {
            const v = events[name][3] ?? 1;
            if (v > 1)
                for (let i = 0; i < v; i++)
                    out.push(name + "|" + name + "_" + i);
            else
                out.push(name + "|" + name);
        }
        return out;
    }

    function play(name: string): void {
        if (!ready || !enabled)
            return;
        const e = events[name];
        if (!e)
            return;
        const cat = e[0];
        const cv = categories[cat] ?? 1.0;
        if (cv <= 0)
            return;
        // non-invasive: stay silent while gaming
        if (GameMode.enabled)
            return;
        const now = Date.now();
        if (now - (_last[name] ?? 0) < (e[1] ?? 40))
            return;
        _last[name] = now;
        const pool = _sfx[name];
        if (!pool || !pool.length)
            return;
        const idx = (_rr[name] ?? 0) % pool.length;
        _rr[name] = idx + 1;
        const s = pool[idx];
        s.volume = Math.max(0, Math.min(1, volume * cv * (e[2] ?? 1.0)));
        s.play();
    }

    // preload every variant into its event's pool for instant, overlap-safe play
    Instantiator {
        model: root._files
        delegate: SoundEffect {
            required property string modelData
            readonly property string event: modelData.split("|")[0]
            source: root.dir + modelData.split("|")[1] + ".wav"
            Component.onCompleted: {
                if (!root._sfx[event])
                    root._sfx[event] = [];
                root._sfx[event].push(this);
            }
        }
    }

    // ignore the binding storm while the shell initialises
    Timer {
        running: true
        interval: 1200
        onTriggered: root.ready = true
    }

    // ---- config file ------------------------------------------------------
    FileView {
        id: cfg

        printErrors: false
        path: `${Quickshell.env("HOME")}/.config/caelestia/sounds.json`
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root._apply(text())
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound)
                Qt.callLater(() => setText(root._defaults()));
        }
    }

    function _apply(t: string): void {
        try {
            const d = JSON.parse(t);
            if (typeof d.enabled === "boolean")
                enabled = d.enabled;
            if (typeof d.volume === "number")
                volume = d.volume;
            if (typeof d.pack === "string")
                pack = d.pack;
            if (d.categories)
                categories = Object.assign({
                    hover: 0.7,
                    ui: 1.0,
                    osd: 0.8,
                    system: 1.0
                }, d.categories);
        } catch (e) {}
    }

    function _defaults(): string {
        return JSON.stringify({
            enabled: true,
            volume: 0.6,
            pack: "keys",
            categories: {
                hover: 0.7,
                ui: 1.0,
                osd: 0.8,
                system: 1.0
            }
        }, null, 2);
    }

    // ---- control surface --------------------------------------------------
    IpcHandler {
        target: "sounds"

        function play(name: string): void {
            root.play(name);
        }
        function toggle(): bool {
            root.enabled = !root.enabled;
            return root.enabled;
        }
        function setVolume(v: real): void {
            root.volume = Math.max(0, Math.min(1, v));
        }
        function isEnabled(): bool {
            return root.enabled;
        }
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "toggleSounds"
        description: "Toggle UI sounds"
        onPressed: root.enabled = !root.enabled
    }
}
