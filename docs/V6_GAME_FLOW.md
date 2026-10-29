# V6 — game flow and timber interface

The default scene is now `scenes/menu.tscn`. Native Controls render the GOAL IN ONE sign, football, Play, Level Select and Settings over the existing Park & Treeline artwork. These are interactive containers, not flattened reference images. `?level=N` remains a direct Web campaign link; `?studio=1` bypasses all campaign screens.

## Campaign and saves

`campaign.json` is the authoritative ordered list of official courses. It currently contains only the twenty imported original levels. Adding further migrated courses means adding their envelopes and manifest entries; no UI or progression rewrite is required. Native `.tscn` samples stay outside this list and are accessible only through the secondary experimental-scene picker.

`scripts/campaign.gd` reads metadata and the existing `user://progress.cfg`. The original stable `studio:comparison-Lxx` identities remain unchanged. Best shots determine stars using each course's current thresholds, so V5 saves containing only `best` remain usable. Writes merge into the existing file. Play finds the first unfinished entry, or starts the first when all are finished. New entries are automatically eligible. Sound settings persist in the same file. Save failures warn rather than claiming successful persistence.

Selection uses 25-slot chapter pages with five columns, drawn earned/unearned stars, a gold outline for the next unfinished course, chapter star totals, and disabled SOON slots for unmigrated levels. Only 1–20 launch today; 21–25 are placeholders. Additional pages appear when the official manifest grows. There is no artificial unlock gate on existing courses.

## Gameplay and completion

The HUD uses separate LEVEL and SHOTS/PAR signs plus sound, retry, pause and camera-drawer controls. Reset Ball, Explore/pan, return to ball, zoom and experimental scenes remain available in the scrollable drawer. Keyboard and touch/mouse shooting remain intact. The display uses actual viewport dimensions rather than shrinking a fixed 1280×720 UI; primary controls retain at least 44-pixel touch rectangles. Containers anchor and center overlays, and grids/drawers scroll when necessary.

Completion shows a performance heading, three drawn earned/unearned stars with a brief reveal, shots/par, NEXT LEVEL, REPLAY LEVEL and BACK TO LEVELS. The final official course offers ALL LEVELS. Actions are immediately available. Pause offers Resume, replay and back. Full restart reconstructs the level and all mechanics; transition guards prevent duplicate loads. Goal containment, delayed scoring and duplicate-completion guards are retained.

The V6 brief explicitly requested the existing announcer recordings and rules; they are re-enabled in this version, superseding the previous temporary voice disable. Mute works across levels and reloads. This change does not alter the audio assets or selection rules.

## Studio isolation

The existing bridge still authenticates messages by source, origin and token. Studio starts the supplied JSON draft directly, shows RETURN TO EDITOR, and retains RESTART TEST. A completed draft offers RETURN TO EDITOR / RESTART TEST and no campaign next action. Scores and test-mode sound toggles never write campaign progress. Returning preserves editor geometry, workspace state, history and draft JSON; no Vite source changes are required.

## Validation and remaining limits

The native suites include the existing gameplay, mechanics, importer, goal-physics, all-twenty-level, collision, progression and rolling checks, plus `tests/game_flow.gd` for menu routing, legacy saves, stars, continuation, future chapter growth, Studio isolation and Control bounds at 1280×720, 960×540, 932×430, 844×390 and 740×360. The camera drawer can scroll at smaller heights. Headless UI assertions inspect actual laid-out button rectangles, not just requested minimum sizes.

`tests/ui_v6.cjs` drives the actual Web export with Chromium, checks rendered screen text using Tesseract, scores with a real mouse drag, clicks NEXT LEVEL, checks level 2 and zero shots, and exercises pause/resume. It captures main menu, selection, HUD and completion at all five target sizes under ignored `build/v6-evidence`. Dependencies are the environment's Playwright, Chromium and Tesseract. Run with `GAME_URL=http://127.0.0.1:8062 node tests/ui_v6.cjs` after exporting and serving locally. Loopback URLs are for internal testing only.

Physics scripts were not retuned during V6. The before/after eleven-case benchmark traces are compared byte-for-byte. The existing low-speed rolling correction from the prior task is retained. This is UI/game-flow work, not a claim of exact Matter/Godot parity or verified solutions for every course.

Physical iPhone/Android, Safari, notch/system safe areas, audible recording levels, and subjective touch comfort remain device checks. Web persistence is scoped to the browser/origin and native persistence to the platform user-data directory; there are no account or cloud saves. No additional levels, monetisation, achievements or replacement editor were added.

## Executed V6 results

- **852 native checks passed:** 128 runtime, 76 mechanics, 35 importer, 108 goal physics, 89 canonical-level/audio rules, 6 collisions, 18 progression, 19 rolling and 373 game-flow/layout checks. Both before- and after-change baseline suites completed. The eleven-case physics trace remained byte-identical.
- Headless editor import and single-threaded Web release export passed. Command-sandbox discovery-socket warnings are environmental; there were no script compilation or application errors.
- Chromium completed the real level-1 mouse shot, completion → NEXT LEVEL → level 2 with zero shots, pause/resume and 20 responsive captures. All four screens were inspected at all five requested dimensions. Final chapter spacing was rechecked after correcting the medium-height grid. At short heights, selection and camera tools scroll while preserving minimum tap sizes.
- The unchanged TypeScript Studio integration passed basic/mechanics/wide draft round trips, native Return to Editor, geometry/workspace/progress preservation, repeated tests, undo/redo, and unsupported-object error handling. Its locked dependencies and dev server were prepared in a temporary reference checkout; no Vite source changes were made.

These are local validations, not a Pages deployment or mobile-hardware sign-off. See ignored `build/v6-evidence` for the original captures and contact sheets. Browser OCR assertions require Python Pillow as well as Tesseract; cream-letter filtering prevents timber/park texture from confusing recognition.

Publication correction: spoken announcer lines are disabled again at the user's request. Assets and selection rules remain for later; gameplay sound effects remain enabled. This supersedes the voice reactivation described above.
