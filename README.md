# Goal In One — Godot prototype V1

A native Godot 4.6.3 / GDScript recreation of **level 14, Green runway**. Uses RigidBody2D, StaticBody2D, CollisionPolygon2D, Area2D and Camera2D; no embedded JavaScript game. Landscape 1280×720, Compatibility/WebGL2, single-threaded web export.

## Play

Drag backwards starting within 75 world pixels of the football, then release to kick. Kicks are unlimited, including during flight. Green arrows accelerate the ball right; bank off the timber roof and clear the ramp. Restart resets the attempt; Pause freezes play. Keyboard: R restart, Escape pause. Touch uses Godot's touch-to-mouse emulation (one aiming finger). Best score persists locally. Three stars for 1 shot, two for 2–3 shots, one otherwise.

## macOS editor and browser

1. Install the **standard Godot 4.6.3** editor for macOS from the official Godot releases. Choose the build for Apple Silicon or Intel. No .NET SDK is needed.
2. Clone this repository. In Godot Project Manager choose Import and select `project.godot`. Press F6/F5 or the Play button.
3. For browser export, install matching templates via Editor → Manage Export Templates. Project → Export → Web → Export Project to `build/web/index.html` (create the directory first). Thread support is disabled in `export_presets.cfg`.
4. Serve rather than double-clicking HTML: `python3 -m http.server 8000 --directory build/web`. Open `http://localhost:8000` on your Mac. WebGL2 is required. No cross-origin isolation headers are required for this single-threaded export.

CLI (with `godot` on PATH):

```sh
godot --headless --editor --import --quit
godot --headless --script res://tests/runtime.gd
mkdir -p build/web
godot --headless --export-release Web build/web/index.html
```

For restricted cloud tasks, set XDG_CACHE_HOME, XDG_DATA_HOME and XDG_CONFIG_HOME to writable directories before invoking Godot. Templates must be installed under the selected XDG_DATA_HOME. No application credentials are needed.

## GitHub Pages

The included `.github/workflows/pages.yml` imports, runs the runtime checks, exports and deploys on pushes to `main` or manual dispatch. In GitHub **Settings → Pages → Source**, choose **GitHub Actions**. Ensure Actions are enabled and the `github-pages` environment allows `main`. After pushing, the deployment job reports the actual URL. No successful deployment or live URL is claimed until that job succeeds.

Expected URL after successful deployment: `https://charliegghaccount.github.io/godot-test-goal-in-one/`.

If repository access is missing, preserve the local commit and restore the Codex GitHub connection's permission for this exact repository. An empty remote is supported; an initial commit is not required to push this project. The user selected godot-test-goal-in-one as the final destination; do not push into the original TypeScript game.

## Native mobile path

The project uses standard Godot nodes and assets without browser dependencies. Landscape is configured. For iPhone: install matching templates, add an iOS export preset, export on macOS, open the generated Xcode project, select your development team, bundle identifier and connected device, then build/run. This requires Apple's signing and Xcode toolchain. Android similarly needs the Godot Android template, supported JDK/SDK and an Android preset. Hardware touch, safe areas, interruptions, audio lifecycle, performance and save persistence need device testing before production. No App Store, advertising or monetisation integration is included.

## Evidence and scope

See [comparison](docs/COMPARISON.md), [validation](docs/VALIDATION.md) and [asset provenance](docs/ASSETS.md). The supplied browser build is an actual Godot export. Fixed arena framing matches this compact level; scrolling, Explore, pinch zoom, Level Studio and other levels are not implemented.
