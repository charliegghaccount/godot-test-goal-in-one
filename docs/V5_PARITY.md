# V5 parity report — 29 October 2026

## What changed and why

The goal-floor failure came from disabling the whole level at completion. CollisionObject2D's default disable mode removes its bodies from physics, including the goal and arena floor. Completion now stops actuator callbacks instead, while native collisions remain active. Goal frame bodies also explicitly retain physics when processing is disabled. There is no teleport into the net, invisible entrance wall or frozen football hiding the failure.

A swept full-ball mouth crossing starts a distinct **0.65-second scoring phase**. Kicks are disabled in that phase; native velocity is damped per axis at the original 120 Hz factors (0.95 / 0.97). Low net restitution represents net absorption. Completion retains the solid top/rear/bottom, displays the original thresholds/shot count and plays the approved recording selected by the original announcement rules. Reset cancels scoring; pause freezes it. Gate/pad callbacks stop after completion without removing their bodies.

Air resistance previously combined the requested ball damping with Godot's global default damping. Ball linear/angular damping now use REPLACE, avoiding this hidden extra drag. Spin damping uses the exponential equivalent of the original 0.92/frame decay. Shot power remains linear with the original 6-pixel dead zone, 140-pixel cap, momentum retention and opposing-velocity projection rule. Contact restitution suppresses low-energy floor chatter. Native rough/contact friction increases as the ball settles; it uses native material forces, not a velocity snap or artificial zero-speed clamp. These adjustments improve some measurements but do not make solvers identical.

Imported wall seams now have circular joint caps at the canonical endpoints, matching the original construction. Thin/angled obstacles retain shape-cast continuous collision detection. The aiming guide uses the actual kick velocity including momentum, 120 Hz ballistic prediction, ball-sized sweeps, approximate rebounds, and regularly spaced screen-size dots. It still does not predict future actuator motion or mechanic forces.

## Actual comparison collection

`comparison/levels/L01.json` through L20.json are exported from the reference's actual `levels` array. They are not redraws or substitutes. Reference checkout: `charliegghaccount/goal-in-one-test` at **76bd946** (physics/level data unchanged from its preceding game version). `scripts/tools/export-reference.mts` regenerates the existing version-1 Studio envelopes, preserving geometry, names, par, thresholds and comparison-specific identities.

All twenty load through the same JSON importer used by **Test in Godot**, and appear first in the temporary native level picker. Start at the Godot Pages URL to compare them directly. Comparison best-score keys remain separate from future final campaign designs. Existing native samples and Web Studio remain available.

Inspection found boosts, reset strips and four moving timbers (levels 9, 18, 19, 20); there are **no springs or wind zones in canonical levels 1–20**. Their cosinusoidal moving-body trajectories, dimensions, axis/path settings and periods are now imported into native AnimatableBody2D prefabs. Moving blocks are no longer rejected by Studio testing. Existing spring/fan/switch/gate scenes are retained; spring checks use the separate Studio example. No unsupported objects occur in these twenty imports. Outside this collection, rotors, breakables, ice, wind-region import and some camera options remain explicitly unsupported as described in the V4 guide.

## Graphics and audio

- Approved Grass Parks art now preserves its aspect ratio, mirrored horizontal tiling and original 1.05 scale / 0.14 horizontal / 0.12 vertical parallax with sky/ground extension. It no longer stretches across arbitrary level dimensions.
- Honey timber uses the original 256-world-unit texture density and mirrored repeat. Boundary caps include metal bolt details. Grass remains selective; roof edges are no longer incorrectly trimmed as floors.
- The football retains its approved SVG at diameter 32, native spin, a subtle trail and throttled kick/contact effects.
- Net contact pulses; the white three-sided goal remains open on the left. Mute, pause, restart, reset and exploration remain functional. The timber HUD is still a simplified native layout, not an exact port of the original responsive CSS pill/round-button design.
- Original four MP3 announcements are reused unchanged. One shot → Goal In One; two stars → Goal; one star → Solid Effort or Should Have Done Better at par+2; three stars with more than one shot → no recording. A single voice player prevents stacking, and short effects have cooldown/concurrency limits. Headless tests skip physical playback; audible levels still need human review.

## Quantitative evidence and remaining differences

See [measured physics](../comparison/PHYSICS.md), [full metrics](../comparison/metrics.json), [plot](../comparison/physics-comparison.png), and [scripted route probes](../comparison/ROUTES.md). Raw traces and source harnesses are retained. The original engine's physics was not modified.

The maximum-power 70-degree shot's apex changed from about **393 px** in the initial Godot measurement to about **416 px**, against **417 px** in Matter. Landing times in the final table are generally close to one or two 120 Hz ticks for the tested ballistic shots. One-second flight travel is much closer after correcting damping. Long-run contact behaviour is still visibly different: the rolling benchmark travels about **820 px versus 617 px**, settling later; some rebound/low-power routes lose too much travel while others run farther. See the table rather than assuming numerical parity from a single improved case.

Three-second scripted probes on levels 1, 5, 9 and 14 record actual positions and score states. Several one-shot probes succeed in both engines. The level-5 −55° probe scores in Matter but does not score within three seconds in Godot. None of the three level-9 probes solves either engine. These are probes, not a full solution search: **not all 20 levels are verified solved**, and no claim of visual equivalence or commercial-quality physics parity is made.

## Executed verification

- 128 original native regression checks, 76 mechanic checks, 35 importer checks.
- 108 goal checks: 27 air/rolling entry combinations across three sizes, three speeds (500–2200 px/s), two airborne angles plus rolling contact, different floor heights, delayed completion, retained ball and active collision bodies.
- 89 canonical-level/audio-rule checks: all twenty loaded and fired, metadata/spawn retained, four mover trajectories checked, announcement selection verified.
- 6 high-speed (2400 px/s) thin/angled timber collision checks.
- Original TypeScript: 623 runtime tests and all 17 existing editor/studio browser regression cases pass. No original physics/editor implementation was changed.
- Browser: paired 1280×720 captures for canonical 1/5/9 and a separate spring example; native real mouse shots and Studio edit → test → return → edit/retest with retained history. Figures show actual Godot, not a Matter imitation.
- Godot import and single-threaded HTML5 export run before publication. Pages build/deployment status is verified separately from local checks.

Manual work remains: human A/B feel tuning, all twenty intended routes/pars, mobile hardware, Safari, audio levels, and closer HUD/grass/net rendering parity. Software-rendered headless Chromium can run simulation slower than wall-clock; scoring checks must allow 0.65 seconds of simulation, not assume a screenshot delay proves phase completion.

## Reproduce

Install the reference repository's locked dependencies. Set `REFERENCE_REPO` to that checkout. From this Godot checkout run the export/benchmark `.mts` files using its tsx loader, then run `godot --headless --fixed-fps 120 --script res://comparison/trace.gd` and `comparison/routes.gd`. `python comparison/report.py` updates metrics; `python comparison/plot.py` makes the chart (matplotlib is for analysis only, not a game dependency). Native CI runs all six test runners. The comparison traces sample at 120 Hz; native SceneTree observation is at physics-frame boundaries, which can account for a one-tick offset.

## Follow-up: progression, rolling and voice pause — 29 October 2026

Completion now presents NEXT LEVEL as its primary action, REPLAY LEVEL, and a scrollable level-selection panel. The canonical campaign ends at its final discovered JSON level, rather than continuing into native design samples. Paths are naturally sorted and discovery drives progression without a fixed campaign length. Finishing the campaign displays a completion message and opens selection. Studio tests remain isolated with replay/return workflows. Full restart reconstructs the level and its actuators. Transition guards prevent duplicate loads.

Progress saves now load the existing file before updating a level, preserving other completions. Best shots, highest stars and completed state persist per stable level ID. Replaying with a worse score retains the best result. Completion already retained native goal/floor collision bodies; the 108 physical goal-entry checks still cover containment across sizes, speeds and entry trajectories.

Spoken announcer recordings are disabled by default, including Goal In One, Goal, Solid Effort and Should Have Done Better. Assets and selection rules remain available for later reactivation through `announcements_enabled`; short gameplay sound effects and Mute remain operational.

Rolling uses a brief supported-contact window to prevent low-energy bounce chatter, plus surface-relative tangential resistance below 320 px/s. It acts only on supported, floor-like contacts; kicks clear support and flight/high-speed shots retain existing damping, gravity and power. This is an approximation to Matter's contact solver, not an identical implementation. The retained TypeScript trace remains unchanged. The 420 px/s rolling benchmark now travels **597.73 px versus 617.34 px in TypeScript**, compared with **820.10 px before**, a reduction in distance error from about 33% to 3.2%. First-second travel is **376.65 versus 376.85 px**. See the regenerated full metrics table for remaining rebound differences. Slow rolls at 60 and 120 px/s are also covered by regression checks, including settling and re-kicking.

HUD and completion/selection panels now reposition and scale with viewport dimensions. The existing Park & Treeline art, canonical twenty layouts, boosts, reverse pads, reset strips, movers and native experimental mechanics are retained. No new level designs or full UGC system were added.

Validation: all 442 existing native checks pass; 18 new progression checks cover next/replay routing, final selection, save retention, restart phases/spawn/mover time and voice defaults; 19 new rolling checks cover stopping, reference distance and upward kicks after settling. Both new runners are included in CI. Headless import and single-threaded Web export pass. This follow-up supersedes the earlier voice-playback and long-roll descriptions above. Physical mobile, Safari, subjective feel and intended solutions for every level remain manual follow-up.

Chromium/WebGL follow-up: a real mouse shot completed canonical level 1, the rendered completion panel displayed NEXT LEVEL / REPLAY LEVEL / LEVEL SELECT, and clicking NEXT LEVEL loaded level 2 with zero shots. Desktop completion, level-2 startup, and 844×390 pause captures were inspected. No browser console errors or page exceptions occurred. This verifies one actual browser progression route, not completion of all twenty levels or hardware touch ergonomics.

V6 supersedes the temporary voice-off and prototype-picker UI descriptions in this report. See [V6 game flow](V6_GAME_FLOW.md) for the current menu, official campaign, persisted progression and validation results.
