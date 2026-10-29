# V4 — original Web Studio + native Godot runtime

Primary authoring URL: https://charliegghaccount.github.io/goal-in-one-test/ . Open Settings → LEVEL EDITOR, create/open a level, click **Test in Godot**, then **Return to Editor**. The original Test Level button remains Matter.js. No Godot desktop editor, manual JSON transfer or backend is needed for this workflow.

The Studio changes live in its own repository: `src/editor/godot-preview.ts`, a toolbar command and modal styling. Its actual LevelEditor/EditorSession remain mounted beneath a modal iframe. No snapshot reconstruction is used to restore editing: selection, camera, undo and unsaved data never leave that live editor instance. Return removes the iframe/engine and exposes the same editor.

## Contract

The importer consumes the Studio's existing **goal-in-one-level version 1** draft JSON, not a new incompatible schema. `studio_import.gd` validates bounded plain data and instantiates only hard-coded native prefab paths. Metadata is retained on the level. Data cannot supply scripts, resource paths or executable expressions. Runtime IDs are derived from draft/design identity.

The web-only autoload bridge installs a JavaScriptBridge callback and a message listener before announcing readiness. The parent waits for readiness before transmitting. Messages have fixed types (gio:ready, gio:level, gio:loaded, gio:error, gio:return), exact origin/source checks and a per-preview random token. Production sites share one GitHub Pages origin; local development can use separate localhost ports with an explicit target URL. There is a loading timeout and an always-available DOM Return button. Invalid data displays explicit errors and hides the preview.

Only message transport is browser-specific. JSON import, native level construction, football physics, mechanics, collision, scoring, camera and input use the same Godot code as the scene/native game. `studio_test` disables progression reads/writes and hides the sample-level picker. Restart reconstructs the imported JSON, not a sample scene. Return does not publish a campaign or store a score.

## Supported and rejected

Supported: polygon vertices (Studio rotation is already baked), legacy outline or full boundary with attached goal-mouth opening, free right-facing goals, spawn, name/par/star thresholds/metadata, forward/backward/reset surfaces, spring directional velocity, rectangular pressure switches and linked gate offsets with distinct open/close speeds. Fixed, follow-x and follow-xy framing use native camera controls/bounds. Native solver/framing differences remain; this is not a TypeScript renderer embedded in Godot.

Rejected with named errors: movers, rotors/swings, breakables, ice, Studio winds/fans (their rectangular field differs from the native fan's rotated footprint), circular legacy switches, left-facing goals, camera windows/regions, custom initial/dead-zone settings, malformed/oversized geometry/data and unknown populated mechanic families. Other descriptive draft metadata is retained without becoming executable behaviour. Custom global Matter.js physics preferences are not part of the exported draft format; native tuning remains authoritative.

Surface/spring sensors retain source dimensions/position. Spring launch angle is independent of its horizontal contact footprint, matching the original implementation; its visual height can exceed the thin trigger band. Gate JSON links resolve via native sibling node paths, not data-supplied resource paths. Normal Godot scene samples/editor functionality remain available.

## Examples and validation

`tests/fixtures/basic.json`, `mechanics.json` and `wide.json` were generated with the real Studio model. Copies in the web repository's docs/godot-examples can be imported through the existing UI.

Godot: import, 128 existing runtime checks, 76 mechanics checks and 35 importer checks passed. Import tests include actual native shots/goal crossing, an imported boost carrying the football into an imported spring, camera dimensions, metadata retention, invalid-data rejection and unchanged Godot progression files.

Web Studio: 623 existing runtime tests passed; TypeScript/Vite builds passed; all 17 existing editor/studio browser regression cases passed, including the original Matter.js Test Level workflow. The new integration browser harness performs actual geometry dragging, repeated Godot preview, real mouse shooting, Return, exact exported draft/workspace/progression comparisons, and Undo/Redo after return across basic/mechanics/wide examples. Screenshots show the actual native Godot canvas inside Studio. No claim is made for physical phones, Safari or exact Matter.js solver parity.

## Deploy and reproduce

1. Push this repository to main: its existing Actions workflow tests all three runners and deploys the Godot web build.
2. In the web repository run `npm run build:pages`, then the existing publish-pages script to update gh-pages. Its default iframe URL points here.
3. The Studio source and deployed runtime must both include V4. Earlier runtime builds have no bridge and will remain on the loading message.

Locally, serve build/web on 8064, run the Studio Vite server on 5174 and open `http://127.0.0.1:5174/?dev=1&godotPreview=http://127.0.0.1:8064/`. Run the web repository's `node tests/godot-integration.cjs` (Playwright + Chromium). Use GAME_URL/STUDIO_URL overrides where documented. Tests exercise real input rather than replacing Godot with a mock.
