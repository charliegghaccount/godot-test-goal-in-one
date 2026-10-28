# V3 mechanic architecture and reference behaviour

Reference: unchanged `charliegghaccount/goal-in-one-test` at db078f1cf0f7567fb8cfa931291bdd808841c9c2, especially src/mechanics.ts, simulation.ts, motion.ts, mechanic-materials.ts and level mechanics definitions. No original files were edited.

## Shared interface and collision layers

Every sensor derives from the small `@tool` area script. It exports dimensions, builds an unsaved native rectangle sensor from those dimensions, detects football entry/exit, and binds to the selected runtime using `bind_game`. The shared game now discovers that interface for sensors and gates; it contains no level-specific mechanic names or trigger logic. The existing V2 forward pad remains the same reusable scene path and uses the original 7200 px/s² acceleration with fade toward 1080 px/s. Backward is another configured instance of the same implementation.

Layer 1 is solid architecture (including gates), layer 2 is the football. Ball mask 1 collides with solids; sensors mask 2 detect only the football. This lets gate sweep queries isolate the football without mistaking scenery for a crush risk. Mechanics are instantiated only with the selected scene, not through a global campaign preload.

## Behaviours and deliberate simplifications

- Boost: continuous directional acceleration while overlapped, fading as velocity along its direction approaches Maximum Speed. Settings are native exported scene properties.
- Reset strip: original semantics return the same football to Spawn and preserve shot count. Reset is deferred out of collision callbacks. A cooldown/pending latch prevents duplicate requests; flash/ring and a short generated PCM sound provide feedback. Generated cues introduce no external assets/dependencies.
- Spring: new contact sets velocity to retained incoming velocity plus local-up launch speed. The original uses 20% retention and caps launch at 24 normalized px/frame (1440 px/s). Defaults/ranges reflect that. There is one activation per contact with a short cooldown; compression releases over roughly 0.2 s. It is a sensor, not a moving rigid spring simulation.
- Fan: constant directional acceleration within a rotated rectangle, fading toward maximum airflow speed. This corresponds to the reference's bounded wind force. Unlike the TypeScript wind rectangle, it is presented as a visible ground-mounted fan; its sensor includes the housing and the configured range above it. It has no solid housing collision.
- Pressure switch: original Toggle and Timed modes, plus simple Hold. A native exported NodePath links a gate. Physical pressed state and logical gate target are separate. Timer advancement belongs to level physics processing, so pause stops it. Switching toggles only on a new contact, not every tick.
- Gate: native AnimatableBody2D with a matching rectangular collision shape, synchronized at the 120 Hz physics tick. It moves from saved closed position along its local configured track at px/s. Automatic mode reverses at endpoints after a wait. A football-only swept-shape query blocks movement before squeezing the ball; the gate resumes when clear. This follows the reference's conservative stop-before-crush policy. Gates can pass through static geometry along their designed track; designers must leave adequate clearance. Continuous overlapping starts, extreme scales and deliberate ball/gate penetration are not a general-purpose crushing simulation.

Operational animations run in physics time and pause with the level. Completion disables the level mechanisms so hazards cannot reset a completed ball. Restart reconstructs the level; ball-only resets retain mechanism state. Changing a switch's parent or deleting its gate requires relinking. Multiple controllers of one gate have last-command semantics, not a new logic-graph system.

## Visuals and testing limits

Native scalable drawing uses the established wood texture, steel fittings, orange/green directional pads, red hazard stripes, spring coils and fan cage/blades. Art previews and generated collisions share exported dimensions and node transforms. The original sprite/canvas rendering code is not embedded. Trajectory preview still predicts solid geometry and gravity only: it does not simulate future boost/spring/fan/switch effects or future gate positions.

The mechanics test suite exercises native physical overlaps, directions, debounce, pause, linked modes/timers, gate endpoints and anti-crush, combined boost/spring behaviour and property save/reopen. Physical iOS/Android, Safari and human puzzle balancing remain manual work. See VALIDATION.md for the actual executed checks and deployment status.
