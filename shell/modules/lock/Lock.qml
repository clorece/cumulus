pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.components.misc

Scope {
    id: root

    property alias lock: lock

    // Shell-start timestamp: a lock engaged within `bootWindow` ms of startup is
    // treated as the boot lock (and greets); later locks (idle/manual) don't.
    readonly property double startTime: Date.now()
    readonly property int bootWindow: 25000

    // Latched per-lock: should the surface greet the moment it appears? Only the
    // boot lock does. Recomputed on each fresh lock so it stays stable for the
    // surface's lifetime (a mid-session flip would spuriously re-run initAnim).
    property bool greetOnShow: false

    WlSessionLock {
        id: lock

        signal unlock
        // Emitted when the screen powers back on (dpms) or the system resumes
        // from sleep while locked — the LockSurface replays the greeter.
        signal wake

        property bool greetOnShow: root.greetOnShow

        onLockedChanged: if (locked)
            root.greetOnShow = (Date.now() - root.startTime) < root.bootWindow

        LockSurface {
            lock: lock
            pam: pam
        }
    }

    Pam {
        id: pam

        lock: lock
    }

    Loader {
        asynchronous: true
        active: true
        onLoaded: active = false

        // Force a load of a screencopy so the one in the lock works
        // My guess is the ICC backend loads async on first request, which if the lock is
        // the first request it fails to capture (because it's async and the compositor
        // refuses capture when locked)
        sourceComponent: ScreencopyView {
            captureSource: Quickshell.screens[0]
        }
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "lock"
        description: "Lock the current session"
        onPressed: lock.locked = true
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "unlock"
        description: "Unlock the current session"
        onPressed: lock.unlock()
    }

    IpcHandler {
        function lock(): void {
            lock.locked = true;
        }

        function unlock(): void {
            lock.unlock();
        }

        function isLocked(): bool {
            return lock.locked;
        }

        target: "lock"
    }
}
