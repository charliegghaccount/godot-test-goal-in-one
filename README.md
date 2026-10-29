# Goal In One — Godot V5

Native Godot 4 / GDScript football puzzle prototype with a visual level-authoring foundation. Standard Godot **4.6.3** is tested and pinned in the web workflow; no .NET or application secrets are needed.

**V5 comparison:** the runtime opens canonical level 1; use its picker for the original **levels 1–20**. Goal collisions/scoring, damping, seam protection, moving timbers, background framing and approved announcer audio have been updated. Read the [parity report](docs/V5_PARITY.md) for measurements and remaining differences.

**Primary level-design workflow:** use the original [Web Level Studio](https://charliegghaccount.github.io/goal-in-one-test/) and its **Test in Godot** button. See [the integration guide](docs/WEB_STUDIO.md). Native scene editing remains optional.

**Interactive mechanics:** forward/backward boosts, reset strip, spring, directional fan, pressure switches and moving gates are reusable scenes with Inspector controls. Three editable experimental levels demonstrate their combinations. See [mechanic design notes](docs/MECHANICS.md).

**Start designing:** [Beginner Level Editor Guide](docs/LEVEL_EDITOR.md).

1. Clone/download this repository and import `project.godot` in Godot.
2. Choose the 2D workspace. Open `levels/green_runway.tscn` or `levels/timber_climb.tscn`.
3. In the 2D toolbar choose **Goal In One → New level from template**.
4. Drag reusable wood/ramp objects into the scene, edit their polygon vertices, move Spawn and Goal, and configure the root's scoring/camera properties.
5. Save in `levels/`, press **F6** to test, and **F8** to return to editing. Ordinary level design needs no GDScript.

The native editor supplies polygon editing, transforms, Inspector, undo and saving. The small enabled plugin adds New/Duplicate with unique IDs. The V2 sample scenes are preserved: original Green runway, Starter practice, and the larger two-axis Timber climb. Only the selected scene is instantiated at runtime. The browser build is for playing saved/exported levels, not authoring them.

## Play

Drag backwards anywhere outside the HUD; release to kick. Unlimited kicks work in mid-flight. The dotted ball-sized trajectory preview includes approximate gravity/rebounds. Restart resets the attempt; Reset ball retains shots. Pause freezes play. Explore/Return (E) switches between camera dragging and aiming; wheel zoom works in Explore. R restarts, Escape pauses. Use the bottom-left picker to test any saved level. Touch uses single-finger mouse emulation in the selected mode. Pinch zoom is not implemented.

## Build and validate

```sh
godot --headless --editor --import --quit
godot --headless --script res://tests/runtime.gd
godot --headless --script res://tests/mechanics.gd
godot --headless --script res://tests/import.gd
mkdir -p build/web
godot --headless --export-release Web build/web/index.html
python3 -m http.server 8000 --directory build/web
```

Install matching export templates via Editor → Manage Export Templates before exporting. Open `http://localhost:8000` on your own machine, not the HTML file directly. Compatibility/WebGL2, single-threaded mode avoids cross-origin isolation requirements. For cloud execution set XDG_DATA_HOME, XDG_CONFIG_HOME and XDG_CACHE_HOME to writable directories; retained templates are under `/workspace/shared/godot-data` in this task.

`.github/workflows/pages.yml` still imports, tests, exports and deploys pushes to `main`. GitHub Settings → Pages → Source must be **GitHub Actions**. Deployment target: https://charliegghaccount.github.io/godot-test-goal-in-one/ . Check the Actions deployment result for actual publication status.

## Scope and platform notes

[Architecture](docs/ARCHITECTURE.md) • [Validation](docs/VALIDATION.md) • [Migration comparison](docs/COMPARISON.md) • [Asset provenance](docs/ASSETS.md)

This remains a technical prototype, not physics parity with Matter.js. The full campaign, all mechanics, world management and browser Level Studio are not recreated. Scoring uses stable level IDs; revisions need new IDs in this foundation. Physical iPhone/Android and Safari testing remain outstanding.

For eventual iPhone testing: install matching native export templates, add an iOS export preset on macOS, export to Xcode, choose your Apple development team/bundle ID and run on a connected device. Android requires its supported JDK/SDK and an Android preset. No browser-only gameplay dependencies were introduced. Signing, hardware performance, safe areas and interruption handling still require platform validation.
