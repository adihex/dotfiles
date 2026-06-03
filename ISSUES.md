# Quickshell Bar Setup — Issue Report & Root Cause Analysis

## Environment
- **OS:** Nobara Linux 43 (Fedora-based)
- **Compositor:** Niri (wlroots Wayland)
- **Bar:** Quickshell 0.2.1
- **Font:** JetBrainsMono Nerd Font
- **Theme:** Catppuccin Mocha

---

## Issue 1: Qt ABI Mismatch (Critical)

**Symptom:** Persistent warning on every launch:
```
WARN: Quickshell was built against Qt 6.10.2 but the system has updated to Qt 6.10.3
```
Caused random crashes, silent Process API failures, and unreliable native module behavior (PipeWire, SystemTray).

**Root Cause:** The `quickshell` RPM from the `terra` repo was compiled against Qt 6.10.2. A subsequent `dnf update` upgraded Qt to 6.10.3 without rebuilding quickshell. The QML plugin loader (`Quickshell.Io`, `Quickshell.Services.Pipewire`, etc.) linked against the old Qt ABI, causing undefined behavior at runtime.

**Fix:** Built quickshell from source (v0.2.1 tag) against the system's Qt 6.10.3. Required installing 15+ development packages (`qt6-qtbase-devel`, `qt6-qtbase-private-devel`, `qt6-qtdeclarative-devel`, `qt6-qtdeclarative-private-devel`, `qt6-qtwayland-devel`, `qt6-qtshadertools-devel`, `wayland-protocols-devel`, `libdrm-devel`, `mesa-libgbm-devel`, `jemalloc-devel`, `breakpad-devel`, `pam-devel`, `pipewire-devel`, `cli11-devel`). Installed to `~/.local/` to avoid needing `sudo`. Disabled crash reporter (`-DCRASH_REPORTER=OFF`) because Fedora's `breakpad` package ships only headers, not shared libraries.

**Lesson:** Always rebuild QML-based binaries after Qt minor-version upgrades. ABI compatibility is not guaranteed across even patch releases.

---

## Issue 2: Nerd Font Icon Rendering — Codepoint Truncation

**Symptom:** Volume/brightness/power icons showed wrong glyphs or garbage characters.

**Root Cause:** Nerd Font Material Design Icons reside in Unicode's Supplementary Private Use Area-A (U+F0000–U+FFFFF). These are 5-digit hex codepoints. In QML/JavaScript, the `\uXXXX` escape sequence reads exactly **4 hex digits**. Writing `"\uF057E"` was parsed as `\uF057` (a random BMP PUA character) followed by the literal character `E`.

**Fix:** Replaced all `"\uXXXXX"` string literals with `String.fromCodePoint(0xFXXXX)` which correctly handles 5-digit supplementary-plane codepoints.

**Lesson:** When using Nerd Fonts in QML, always use `String.fromCodePoint()`. The `\u` escape is BMP-only.

---

## Issue 3: Process API — Silent `onStreamFinished` Failures

**Symptom:** `Process` objects with `running: true` and `StdioCollector` on `stdout` would launch but `onStreamFinished` never fired for certain commands (notably `nmcli`, any `sh -c` pipeline).

Commands that worked:
- `brightnessctl -m` ✓
- `wpctl get-volume @DEFAULT_AUDIO_SINK@` ✓

Commands that silently failed:
- `nmcli -t -f SSID,ACTIVE dev wifi` ✗
- `sh -c "nmcli ... | grep ... | cut ..."` ✗
- `cat /tmp/file` ✗

**Root Cause:** Not definitively isolated. Possible factors:
1. Pre-rebuild: Qt ABI mismatch may have broken the `Quickshell.Io` module's subprocess handling for specific binary types or argument counts.
2. Post-rebuild: The issue persisted, suggesting a deeper problem with how the Process type handles stdout buffering. `nmcli` outputs many lines quickly; maybe the `StdioCollector` has a race condition with rapid stdout closure.
3. Shell pipelines (`sh -c "..."`) may behave differently due to subshell stdout inheritance.

**Workaround:** Two approaches that bypass Process entirely:
1. **Background shell loop → file → XMLHttpRequest:** A `while sleep N` loop writes data to `/tmp/niri_<name>`; QML uses `XMLHttpRequest` to `GET file:///tmp/niri_<name>` every 3s. Requires `QML_XHR_ALLOW_FILE_READ=1` environment variable.
2. **Native PipeWire API:** For volume, `Pipewire.defaultAudioSink.audio` provides real-time push without any Process dependency.

**Lesson:** Don't rely on `Process` + `StdioCollector` for production polling. It's fragile. Prefer native APIs (PipeWire) or file-based polling via XHR.

---

## Issue 4: FileView.text() Returns Cached Data

**Symptom:** After a `FileView` was set up to watch `/tmp/niri_network`, calling `text()` always returned the initial (or stale) content, even after the file was overwritten by the background loop.

**Root Cause:** `FileView` (a QML wrapper around the C++ `FileViewInternal`) uses `__text` as an internal cache. The `text()` function reads `this.__text` which is populated on initial async load. It does **not** re-read from disk unless `reload()` is explicitly called. The `onFileChanged` signal fires on inotify events, but `text()` still returns the cache. Even `reload()` had inconsistent behavior.

**Fix:** Abandoned `FileView` for network polling. Used `XMLHttpRequest` instead, which performs a fresh HTTP GET on every call.

**Lesson:** `FileView` is suitable for static configuration files, not for polling dynamic data. The `text()` method name is misleading — it doesn't read from disk.

---

## Issue 5: Sysfs Backlight — inotify Doesn't Fire

**Symptom:** After setting `FileView` with `watchChanges: true` on `/sys/class/backlight/amdgpu_bl2/brightness`, `onFileChanged` never fired when brightness changed via `brightnessctl` or keyboard keys.

**Root Cause:** Sysfs files are virtual kernel interfaces, not real filesystem files. The kernel does not update `mtime` or emit inotify events when sysfs attributes are written. This is by design — sysfs is a RAM-based pseudo-filesystem.

**Fix:** Replaced `FileView` with `Process` polling via `brightnessctl -m` every 500ms. For scroll-triggered changes, `brightnessctl -m set +/-5%` outputs the new value in its stdout — parsed instantly in `onStreamFinished`.

**Lesson:** Never rely on inotify for `/sys` or `/proc` files. Always poll.

---

## Issue 6: Volume Always Showing "Muted" / NaN

**Symptom:** Volume displayed as "muted" or "NaN%" despite PipeWire running correctly (`wpctl get-volume` showed normal values).

**Root Cause (Phase 1 — missing tracker):** The `Pipewire` singleton's `defaultAudioSink` returns a `PwNode` that may be **unbound** (not yet fully connected to the PipeWire server). Without `PwObjectTracker { objects: [Pipewire.defaultAudioSink] }`, accessing `.audio.volume` on an unbound node returns `undefined` → `NaN` in calculations.

**Root Cause (Phase 2 — actual mute):** The volume **was** genuinely muted (`[MUTED]` in `wpctl` output). The middleware-click mute toggle may have been triggered accidentally. Fixed with `wpctl set-mute @DEFAULT_AUDIO_SINK@ 0`.

**Fix:** Added `PwObjectTracker { objects: [Pipewire.defaultAudioSink] }` at the root level. This ensures the node is properly bound and its properties (`volume`, `muted`) are live.

**Lesson:** `PwObjectTracker` is mandatory when using `Pipewire.defaultAudioSink`. Without it, the node is unbound and properties are undefined.

---

## Issue 7: System Tray — Right-Click Menu Crash

**Symptom:** Calling `modelData.menu.open()` on a `SystemTrayItem` crashed quickshell immediately.

**Root Cause:** The StatusNotifierItem menu protocol requires a `QsMenuAnchor` object to handle positioning and window parenting. Directly calling `.menu.open()` without anchoring to a window causes a null pointer dereference or protocol violation. Reference configs (spx-quickshell, doannc2212) use a dedicated `TrayMenu` component with `QsMenuOpener` and proper anchor setup — a significant amount of infrastructure.

**Fix:** Removed system tray entirely. Used a simple custom network widget instead. Right-click on tray items changed to `modelData.secondaryActivate()` (middle-click action). Left-click kept as `modelData.activate()`.

**Lesson:** SNI tray menus require substantial boilerplate (`QsMenuAnchor`, `PopupAdjustment`, window coordinate mapping). Not worth it for a minimal bar.

---

## Issue 8: nm-applet — GTK / Wayland Incompatibility

**Symptom:** `nm-applet` tray icon appeared but clicks did nothing. Right-click crashed the bar.

**Root Cause:** `nm-applet` is a GTK3 application. On Wayland, GTK3 apps use XWayland, which can cause issues with SNI protocol communication (the D-Bus menu proxy may not work across X11/Wayland boundaries). Additionally, `nm-applet`'s `Activate` D-Bus method may not be implemented by all versions.

**Fix:** Replaced `nm-applet` with a custom network indicator. Click opens `nm-connection-editor` via `Quickshell.execDetached()`.

**Lesson:** Prefer Qt-based/Wayland-native tray apps (`nm-tray` would be ideal but wasn't in Nobara repos). GTK tray apps are unreliable on pure Wayland compositors.

---

## Issue 9: Duplicate Background Processes

**Symptom:** The `/tmp/niri_network` file accumulated hundreds of duplicate lines and NUL bytes after several quickshell restarts. Each restart spawned a new `while sleep` background loop without killing the old one.

**Root Cause:** The `Process { running: true }` in QML starts a background `sh -c "while sleep..."` process. When quickshell restarts, the old quickshell process dies but its child processes (the shell loop) may **outlive** the parent (daemonized). Each restart leaks one loop. Multiple concurrent loops writing to the same file with `>` (truncate) cause interleaved writes and file corruption (NUL bytes from truncated frames).

**Fix:** Added explicit `pkill -f "niri_network"` before starting quickshell. Changed file writes from `>` to use `>>` with periodic truncation... actually, better: kill old loops on each restart.

**Lesson:** Long-lived child processes spawned from QML `Process` need explicit lifecycle management. They don't die with the parent.

---

## Issue 10: XMLHttpRequest Blocked for file:// URLs

**Symptom:** `XMLHttpRequest` with `file:///tmp/...` returned empty/blocked:
```
WARN: XMLHttpRequest: Using GET on a local file is disabled by default.
Set QML_XHR_ALLOW_FILE_READ to 1 to enable this feature.
```

**Root Cause:** Qt 6's QML engine disables `file://` access in `XMLHttpRequest` by default as a security measure (prevents QML apps from reading arbitrary local files).

**Fix:** Set `QML_XHR_ALLOW_FILE_READ=1` environment variable when launching quickshell. Added to Niri config: `spawn-sh-at-startup "env QML_XHR_ALLOW_FILE_READ=1 qs -c ~/.config/quickshell"`.

**Lesson:** Qt 6 QML security model requires explicit opt-in for local file access via XHR.

---

## Final Architecture — What Ships

```
┌─ ≡ Niri │ eDP-1 ── ☕ Jun 4 ── 󰤨 ZTE_2.4G │ 󰖜 100% │ 󰕾 55% │ 06:25 │ ⏻ ─┐
```

| Widget | Data Source | Update Mechanism | Interaction |
|--------|------------|-----------------|-------------|
| Network | `sh -c "while sleep 3..."` → `/tmp/niri_network` | `XMLHttpRequest` every 3s | Click → `nm-connection-editor` |
| Brightness | `brightnessctl -m` Process | Poll 500ms + instant on scroll | Scroll ±5% |
| Volume | `Pipewire.defaultAudioSink.audio` | Native PipeWire push | Scroll ±5%, Click → `pavucontrol`, MClick → mute |
| Power | — | — | Click → fuzzel powermenu via `execDetached` |
| Clock | `Date()` QML | Every 1s | — |

## Key Takeaways

1. **Rebuild after Qt upgrades.** QML/C++ plugins are ABI-sensitive.
2. **Use `String.fromCodePoint()` for Nerd Fonts.** `\u` is BMP-only.
3. **Don't trust `Process` + `StdioCollector`.** It's fragile. Use native APIs or XHR file polling.
4. **`FileView.text()` caches.** Not suitable for live data. Prefer XHR.
5. **Sysfs has no inotify.** Always poll backlight/network stats.
6. **`PwObjectTracker` is mandatory** for PipeWire native API.
7. **SNI tray menus need `QsMenuAnchor`.** Not worth the complexity for a minimal bar.
8. **Kill old background loops** before restart to avoid process leaks and file corruption.
9. **Qt 6 blocks XHR file://** by default. Set `QML_XHR_ALLOW_FILE_READ=1`.
