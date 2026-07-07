pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import QtMultimedia
import Quickshell
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.nexus.common

// Wake greeter — a dim scrim over the (blurred) wallpaper, a small logo
// reveal, then a typewriter "Welcome, <user>" with per-character mechanical
// key-click SFX. On completion it emits `finished`, which the LockSurface
// uses to kick off the normal login-element entrance (initAnim).
Item {
    id: root

    // ---- public API -------------------------------------------------------
    // Flip `active` true to (re)play the greeter. Emits `finished` when the
    // typing + hold are done (or when skipped via any key/click).
    property bool active: false
    signal finished

    // ---- tunables ---------------------------------------------------------
    property string username: Quickshell.env("USER") ?? "user"
    property string prefix: "Welcome, "
    readonly property string fullText: prefix + username

    property int charInterval: 62      // base ms between characters
    property int charJitter: 26        // + up to this many ms of randomness
    property int leadIn: 850           // ms before typing starts (logo settle)
    property int holdAfter: 520        // ms to linger after last character

    property bool showLogo: true
    property bool soundEnabled: true
    property real volume: 0.9
    // holypanda | cream | cream-deep | blackink | blackink-deep | topre | mxblack
    property string switchName: "blackink-deep"

    // frosted backdrop
    property real blurAmount: 1.0
    property real dimTint: 0.42          // dark tint over the blur for text contrast

    readonly property url sndDir: Qt.resolvedUrl("../../assets/sounds/keyboard/" + switchName + "/")

    // ---- internal state ---------------------------------------------------
    property int _shown: 0
    property bool _typing: false
    property int _genericIdx: 0

    anchors.fill: parent
    opacity: 0
    visible: opacity > 0

    onActiveChanged: active ? _start() : _reset()

    function _start(): void {
        _reset();
        showAnim.restart();
        leadTimer.restart();
    }

    function _reset(): void {
        typeTimer.stop();
        leadTimer.stop();
        holdTimer.stop();
        _shown = 0;
        _typing = false;
    }

    // Any input during the greeter fast-forwards to the login screen.
    function skip(): void {
        if (!root.active)
            return;
        _shown = fullText.length;
        _typing = false;
        typeTimer.stop();
        leadTimer.stop();
        holdTimer.stop();
        root._finish();
    }

    function _beginTyping(): void {
        _typing = true;
        typeTimer.interval = root.charInterval;
        typeTimer.restart();
    }

    function _finish(): void {
        hideAnim.restart();
        root.finished();
    }

    function _playChar(ch: string): void {
        if (!root.soundEnabled)
            return;
        if (ch === " ")
            spaceSfx.play();
        else {
            const s = genericPool.objectAt(root._genericIdx % 5);
            root._genericIdx++;
            if (s)
                s.play();
        }
    }

    // ---- frosted backdrop: blurred current-preset wallpaper ---------------
    Image {
        id: wall
        anchors.fill: parent
        source: Wallpapers.current
        fillMode: Image.PreserveAspectCrop
        cache: false
        asynchronous: true

        layer.enabled: true
        layer.effect: MultiEffect {
            autoPaddingEnabled: false
            blurEnabled: true
            blur: root.blurAmount
            blurMax: 64
            blurMultiplier: 1
        }
    }

    // dark tint over the frost for text contrast
    Rectangle {
        id: scrim
        anchors.fill: parent
        color: Colours.palette.m3scrim
        opacity: 1
    }

    // ---- centre content ---------------------------------------------------
    ColumnLayout {
        id: col
        anchors.centerIn: parent
        spacing: Tokens.spacing.large * 2

        scale: 0.96
        opacity: 0

        AnimatedLogo {
            Layout.alignment: Qt.AlignHCenter
            visible: root.showLogo
            implicitWidth: 132
            implicitHeight: 132 * (90.38 / 128)
        }

        // frosted-glass nameplate behind the typed line
        Rectangle {
            id: glass
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: nameRow.implicitWidth + Tokens.padding.large * 3
            implicitHeight: nameRow.implicitHeight + Tokens.padding.large * 1.6
            radius: Tokens.rounding.large
            color: Qt.alpha(Colours.palette.m3surface, 0.34)
            border.width: 1
            border.color: Qt.alpha(Colours.palette.m3outline, 0.35)

            RowLayout {
                id: nameRow
                anchors.centerIn: parent
                spacing: 0

                StyledText {
                    id: line
                    text: root.fullText.substring(0, root._shown)
                    color: Colours.palette.m3onSurface
                    font.family: Tokens.font.mono.medium.family
                    font.pointSize: 34
                    font.weight: Font.Medium
                }

                // block caret
                Rectangle {
                    id: caret
                    Layout.alignment: Qt.AlignVCenter
                    Layout.leftMargin: 4
                    implicitWidth: line.font.pointSize * 0.55
                    implicitHeight: line.font.pointSize * 1.3
                    radius: 2
                    color: Colours.palette.m3primary

                    SequentialAnimation on opacity {
                        running: root.visible
                        loops: Animation.Infinite
                        NumberAnimation { to: 0; duration: 260; easing.type: Easing.InOutQuad }
                        PauseAnimation { duration: 270 }
                        NumberAnimation { to: 1; duration: 260; easing.type: Easing.InOutQuad }
                        PauseAnimation { duration: 270 }
                    }
                }
            }
        }
    }

    // Click anywhere to fast-forward to the login screen. Does not take
    // keyboard focus, so the lock's password field keeps receiving keys.
    MouseArea {
        anchors.fill: parent
        enabled: root.active
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onPressed: root.skip()
    }

    // ---- sound pool -------------------------------------------------------
    Instantiator {
        id: genericPool
        model: 5
        delegate: SoundEffect {
            required property int index
            source: root.sndDir + "r" + index + ".wav"
            volume: root.volume
        }
    }
    SoundEffect {
        id: spaceSfx
        source: root.sndDir + "space.wav"
        volume: root.volume
    }
    SoundEffect {
        id: enterSfx
        source: root.sndDir + "enter.wav"
        volume: root.volume
    }

    // ---- timers -----------------------------------------------------------
    Timer {
        id: leadTimer
        interval: root.leadIn
        onTriggered: root._beginTyping()
    }

    Timer {
        id: typeTimer
        repeat: true
        interval: root.charInterval
        running: false
        onTriggered: {
            if (root._shown >= root.fullText.length) {
                stop();
                root._typing = false;
                holdTimer.restart();
                return;
            }
            root._shown++;
            root._playChar(root.fullText[root._shown - 1]);
            interval = root.charInterval + Math.round(Math.random() * root.charJitter);
        }
    }

    Timer {
        id: holdTimer
        interval: root.holdAfter
        onTriggered: root._finish()
    }

    // ---- entrance / exit --------------------------------------------------
    ParallelAnimation {
        id: showAnim
        Anim {
            target: scrim
            property: "opacity"
            from: 1
            to: root.dimTint
            type: Anim.StandardLarge
        }
        Anim {
            target: root
            property: "opacity"
            from: 0
            to: 1
            type: Anim.DefaultEffects
        }
        Anim {
            target: col
            property: "opacity"
            to: 1
            type: Anim.StandardLarge
        }
        Anim {
            target: col
            property: "scale"
            to: 1
            type: Anim.FastSpatial
        }
    }

    ParallelAnimation {
        id: hideAnim
        Anim {
            target: root
            property: "opacity"
            to: 0
            type: Anim.Standard
        }
        Anim {
            target: col
            property: "scale"
            to: 1.03
            type: Anim.Standard
        }
    }
}
