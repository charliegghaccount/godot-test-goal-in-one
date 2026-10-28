# V2 validation — 28 October 2026

Godot 4.6.3 standard, Compatibility renderer, 120 Hz physics. The existing GitHub Pages workflow is preserved.

- Native editor import and script/plugin compilation completed. The command sandbox logs discovery-socket bind errors; these are environmental and do not prevent import/export or gameplay.
- Runtime checks: 73 checks passed, including moving-ball kicks, velocity conversion, dead zone, native floor bounce, boost, pause/resume, physical goal crossing, best score, anywhere input, camera/aim separation, unique IDs, all three sample-level validity, every wooden object's render/collision vertices and transforms, resizing goal crossing thresholds, three-bar frame, scene pack/save/reopen, goal transforms and two-axis camera bounds.
- Direct current-scene-style startup of `levels/timber_climb.tscn` completed without gameplay errors. This exercises the F6 delegation to shared gameplay.
- Single-threaded web release exported with matching SHA-512-verified templates.
- Chromium/WebGL2 software rendering: real mouse aiming from empty sky increased shots; screenshots show the preview emerging from the ball. The native level picker loaded Timber climb. Explore/Return visibly panned both axes without adding a shot. Emulated touchscreen input increased shots and launched the ball. Landscape resizing to 844×390 completed. No browser console errors/page exceptions. Screenshots inspected visually.

The save/reopen checks use native PackedScene packing and ResourceSaver, including modified goal properties. The editor plugin compiled during editor import; a human macOS GUI walkthrough of its dialogs, polygon handles and undo was not performed here. The guide follows native Godot controls. Physical device touch, Safari/Firefox, signed native exports and hardware performance remain unverified. No end-to-end browser solve of Timber climb is claimed.

Run `godot --headless --script res://tests/runtime.gd` for native checks. Serve build/web on 8062, then `node tests/web.cjs` with Playwright/Chromium available. GAME_URL overrides the tested address. Browser harness checks errors and exercises input; gameplay state is verified through its screenshots plus native assertions, not DOM text (Godot draws to canvas).

The saved scene format and generated collisions were tested, not future campaign import/export services. Published Pages availability must be checked independently of the local web export.
