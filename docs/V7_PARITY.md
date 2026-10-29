# V7 — migration parity milestone

V7 brings the actual Godot renderer closer to the original Vite/Canvas renderer and restores four missing Studio mechanic families. The official campaign remains levels 1–20. Spoken announcements remain **disabled**; their assets and playback infrastructure are retained.

## Cross-repository findings and implemented changes

The audit compared the reference's simulation, renderer, art/material helpers, goal/background layout, camera and controls, object library, UI/CSS and approved UI-V1 evidence against the Godot scripts and V5/V6 reports. The reference checkout is `charliegghaccount/goal-in-one-test`, commit `76bd946`; its runtime source and physics were not changed.

| Area | Finding in V6 | Implemented in V7 |
|---|---|---|
| Framing | Imported legacy courses used editor bounds, rather than the reference's deliberate x=25 / width=1250 rectangle | Preserve the legacy camera rectangle and vertical margins. Matched fixed-camera captures now use the same center and zoom. Follow-camera imports accept initial position, dead zones and minimum ball diameter. Native authored-scene zoom remains supported. The offscreen GOAL arrow is restored for exploration/follow views. |
| Timber | Appending directly to the `uv` PackedArray property discarded the edited buffer, stretching the wood. Texture anchors also differed. | Build and assign an explicit UV buffer at 512 texture pixels / 256 world units, anchor in local grain space, and retain mirrored repeat. Add reference edge lighting, corner bolts, round boundary caps, beam highlights and selective turf. Default obstacle grass now matches the reference's false value. |
| Moving wood | Movers inherited steel gate rails | Draw ordinary timber with its actual motion track; retain rails on gates. Path phases and once-path clamping now follow the reference. |
| Background | Approved image was already correct | Byte-identical approved background/wood assets retained. Preserve the reference's 1.05 game scale, mirrored tiling, 0.14/0.12 parallax and edge-row extension. Menus use the reference CSS cover/center treatment. |
| Ball | Gameplay used a different SVG than the original gameplay renderer | Port the reference's shaded circle, pentagonal panels, seams and highlight. Keep the 16-world-unit radius and physical rotation. Menu artwork retains the reference SVG. |
| Goal | Simplified dim mesh and flat tube | Brighter 13-unit net, shadow strands/intersections, damped ripple, layered white frame highlights and metal collars. Three physical bars, open entrance and delayed scoring remain intact. |
| Pads and feedback | Generic plates, line arrows, ring effects | Reference green/orange/red steel-backed strips, filled chevrons, warning marker, fast particles, small 13-point trail, readiness ring and red spring cap. |
| Aim | Even screen-spaced dots with rebound predictions differed from the original guide | Reference 50-step ballistic guide sampled every third step, tapering white dots, yellow power arrow/ring, drag tether and power label. Uses the actual kick/momentum calculation; it intentionally does not predict future obstacle or mechanic forces. |
| Interface | Flat brown buttons, stretched panels, text control abbreviations | Native rounded StyleBoxes with mirrored wood, the original brown gradient overlay, inset highlights, screws and gold focus. Bundled licensed bold font ensures consistent Web typography. Two-line title, decorative menu course, icon controls, retained responsive containers and V6 navigation. |

## Restored mechanics and Studio semantics

All are reusable native scenes and imported from the existing version-1 Studio envelope:

- **Rotating paddles and swinging timbers:** phase, radians/second, sine amplitude/period, optional pivot, original 3 rad/s slew cap, native moving collision and a supported-ball anti-crush check. Transform updates are atomic so rotation is retained by physics synchronization.
- **Breakable wood:** native solid rectangle, incoming normal-speed threshold converted from Matter units by ×60, visible damage crack and deferred removal of both art and collision. Weak impacts leave a solid obstacle. Contact restitution is translated for Godot's additive rule rather than accidentally adding a second full bounce.
- **Ice:** rotated contact strip, declared friction, concurrent contact bookkeeping and reduced grounded resistance. Reset/exit remove stale contacts. Ordinary rolling is unchanged when no ice is present.
- **Rectangular wind/fans:** exact axis-aligned region, center-in-region activation, angle in degrees, strength ×3600 in px/s², reference directional speed fade toward 1440 px/s and animated flow/appliance artwork.
- **Existing mechanics retained:** forward/reverse pads, red reset strips, springs, path/axis movers, switches and gates, plus native fan prefabs. Legacy circular switches now import as actual circular sensors. Unknown mechanic families still fail explicitly.

The original Web Studio is unchanged. Native Return to Editor, repeat testing, editor workspace/history and score isolation remain functional. Camera view-window/region definitions and left-facing goals are still explicitly unsupported. Native gate/rotor anti-crush and contact resolution approximate the Matter solver; these are not claims of identical dynamic behavior in arbitrary adversarial layouts.

## Measured physics and representative gameplay

The eleven existing 120 Hz / ten-second benchmark traces are **byte-identical to V6**. There was no broad gravity, shot, restitution, angular-damping or rolling retune during V7. The prior rolling improvement is retained: **597.73 px versus 617.34 px** in Matter at 420 px/s, and first-second travel **376.65 versus 376.85 px**. See [full benchmark](../comparison/PHYSICS.md).

Equivalent −15°, −35° and −55° full-power inputs were run for three seconds on original levels **1, 2, 5, 6, 9, 10, 14, 18, 19 and 20**, plus the original spring example and a fixture generated by the original Studio object-library functions. No campaign levels or geometry were redesigned. The fixture is a regression scene, not a migrated level 21.

[36 paired route measurements](../comparison/v7-route-metrics.json) show scoring agreement in **34/36** probes and median endpoint separation **61.66 world pixels**. Level 2 at −35° and level 5 at −55° score in Matter but do not score in Godot within the probe window. Maximum separation is about 927 px. These differences are material: ramp/contact/boost routes still need further tuning and all intended solutions/pars are not verified. Shared visual framing is not proof of equivalent physics.

## Visual evidence

The standalone comparison scene uses the actual Godot game/importer and the actual TypeScript Renderer/FootballSimulation. It hides HUDs only for the world comparison, uses the same viewport, source level, specified inputs and 120 Hz tick count, and records camera/ball state beside the original captures. No screenshot warping or geometry editing is used to manufacture alignment. Initial captures freeze both simulations; moving examples are sampled at 120 ticks. Native dynamic-body synchronization can differ by approximately one tick. Exploration captures apply the same zoom and bounded pan to test parallax and exposed edges.

- [1280×720 world contact sheet](../comparison/v7/world-1280.jpg)
- [960×540 world contact sheet](../comparison/v7/world-960.jpg)
- [844×390 world contact sheet](../comparison/v7/world-844.jpg)
- [Desktop interface comparison](../comparison/v7/ui-1280.jpg)
- [960-wide interface comparison](../comparison/v7/ui-960.jpg)
- [844-wide interface comparison](../comparison/v7/ui-844.jpg)
- [Captured state and image measurements](../comparison/v7/visual-metrics.json)

Vite is always on the left and Godot on the right. The world matrix covers all ten representative canonical courses at 1280×720, levels 1/2/5/9 at both smaller sizes, both mechanic examples at all three sizes, an aiming view, moving-state examples and three exploration views. Actual main menu, chapter selection, HUD, pause and completion are captured separately in both products.

The images were visually inspected. The corrected framing, wood density, ball/goal proportions and shared artwork are substantially closer. Remaining visible differences include platform antialiasing, fonts/lettering and exact panel composition, some fan/switch/spring details, net clipping at sloping edges, and native dynamic-object interpolation. The Godot menu adapts the approved treatment; it is not a pixel-identical port of the DOM design. Mean RGB differences are recorded as context, not used as an optimization target or a substitute for inspection.

## Reproduction

Run Godot with writable XDG paths as in README. Existing runners plus `tests/v7_mechanics.gd` exercise real physical contacts, importer parameters, pause/reset, retained UVs and camera bounds. `comparison/routes.gd` and `comparison/route-reference.mts` collect the paired route probes; set `REFERENCE_REPO` to the original checkout and run the TypeScript harness with its pinned `tsx` loader.

For renderer captures, copy the game to a temporary non-Git project (exclude `.git`, `.godot` and `build`), change only that copy's main scene to `comparison/view.tscn`, include `tests/fixtures/*.json` in its Web preset, and export/serve it separately. Copy `comparison/reference-view.html` into the reference Vite server root as `v7-parity.html`, and copy the fixture JSON files to its `v7-fixtures/` directory. Run `node comparison/capture-v7.cjs`; URLs are configurable through `VITE_COMPARE_URL` and `GODOT_COMPARE_URL`. `python3 comparison/contact-v7.py` creates the contact sheets and measurements. Raw captures are in ignored `build/v7-evidence`.

For an assessment by hand: open the same official level and viewport in both games, compare the stationary framing first, then the same low-power and full-power shots; test rolling separately from flight. Compare levels 2/5 for the known contact-route differences. Finally test the Studio spring/library fixtures, pan/zoom, a goal → Next Level transition and saved stars. Keep volume on to check short effects; spoken lines should remain silent.

Physical mobile devices, Safari, audible balancing and all twenty intended solutions remain unverified. Godot is now noticeably closer in artwork and assessment framing and supports more of the existing authoring library, but Matter contact parity is not complete.

## Executed validation

- **883 Godot checks passed:** the existing 852 plus 31 V7 importer, artwork-buffer and physical-mechanic checks. These include actual rotating-body rebound, weak/strong breakable impacts, ice travel versus ordinary floor, center-bounded wind force, pause, reset and original Studio-library import. A path-mover position check allows native physics synchronization's one-tick delay.
- All **623 original TypeScript runtime tests passed** using the repository's exact test command. No original physics source was edited.
- Both production and comparison Web exports and headless import passed without GDScript or export errors. Sandbox-only discovery-socket warnings remain environmental.
- Real Chromium/WebGL gameplay passed main menu → selection → mouse shot → completion → Next Level → level 2 with zero shots, pause/resume, and twenty desktop/mobile captures. Minimum 44 px touch targets and bounds were checked natively at all five V6 sizes.
- Original Studio basic/spring/wide drafts passed edit/test/native-return round trips, repeated testing, undo/redo and geometry/workspace/progress preservation. The restored rotating paddle also passed Studio import/test/return.
- Thirty paired world captures and thirty actual-interface captures cover the three V7 target resolutions. The paired fixed-camera and exploration matrices record matching camera center/zoom to floating-point precision. Contact sheets and raw state records were inspected along with full-size examples.

The production export does not expose the standalone comparison scene as a navigation option. Local validation is separate from Pages publication and hardware testing.
