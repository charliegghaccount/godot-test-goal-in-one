# V3 validation — 28 October 2026

Godot 4.6.3, native 120 Hz physics and single-threaded Compatibility web export.

- Editor import completed and all mechanic/tool scripts compiled.
- Existing regression runner expanded automatically over the six saved levels: **128 checks passed** (all V2 gameplay, camera, editable geometry, level identities, resized goals and scene roundtrips).
- New mechanics runner: **76 checks passed**. Physical forward/backward/rotated boost activation, spring launch/debounce/recovery/orientation, upward/rotated/out-of-range fan forces, red-pad reset/shot preservation/cooldown, linked toggle/timed/hold switches, pause, gate endpoints/automatic cycling/anti-crush/resumption, combined boost-to-spring launching, and Inspector settings packed/saved/reopened for all seven prefab variants, plus whole-level save/reopen and duplicate switch/gate link resolution.
- Initial property roundtrip checks exposed strict equality against serialized 32-bit rotation values; the test now uses approximate float comparison. Both affected rotation roundtrips pass.
- Single-threaded web release export succeeded with the retained matching templates.
- Chromium WebGL2: V2 anywhere-aiming, level selection, camera Explore, emulated touch and landscape resize flow passed without browser errors. Each of the three new labs was loaded and exercised using real mouse input. Captures show the new art and the pressure switch opening its linked gate. Screenshots inspected visually; no browser console errors/page exceptions.
- GitHub workflow retains the existing Pages deployment, adding the mechanics runner before export. Push publication and live deployment are separate from the verified local export. API status checks were blocked by the environment's network policy (api.github.com); hosted-site access is also outside its current allowlist. Draft domain additions have been saved, not applied. The normal GitHub Actions web page is accessible as a read-only fallback for checking the exact pushed commit. Do not infer a successful deployment from local tests alone.

Manual follow-up: macOS editor placement/rotation/resize, node-picker linking and native undo; physical iOS/Android and Safari; audible cue volume, feel and animation timing; deliberately adversarial gate/ball penetration; puzzle balancing. Automated tests use real sensors/physics and scene persistence, but do not replace a human editor walkthrough or hardware playtest. The three labs are experiments, not final campaign designs.

Commands:

```sh
godot --headless --editor --import --quit
godot --headless --script res://tests/runtime.gd
godot --headless --script res://tests/mechanics.gd
godot --headless --export-release Web build/web/index.html
```

Serve build/web locally, then run tests/web.cjs and tests/web_mechanics.cjs with Playwright/Chromium; set GAME_URL as needed. These harnesses exercise inputs and detect browser errors; canvas state is assessed using captured screenshots and native runtime assertions. Restricted cloud sandbox discovery-socket bind warnings do not prevent import/export; no GDScript/gameplay errors were present in the final logs.

---

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
