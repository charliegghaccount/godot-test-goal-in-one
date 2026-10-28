# Migration comparison

Reference inspected at `charliegghaccount/goal-in-one-test`, commit `db078f1cf0f7567fb8cfa931291bdd808841c9c2`. Original checkout/source was not changed.

## Recreated level and behaviour

Level 14, Green runway, comes from `src/extra-layouts.ts` and `src/levels.ts`: the same PDF transform (52+(x−50)×1.6, 92+(y−84)×1.6), peaked roof, start (112,606.13632), floor 628.13632, ramp vertices (370,419)/(490,345)/(490,419), boost between source x=180 and 295, and original training goal coordinates. A tiny original mouth junction is effectively coincident at this scale. Timber is a native textured Polygon2D with matching collision geometry. Goal styling and grass borders are native approximations of the existing canvas procedures. Background is a fixed composition because this level uses fixed arena framing; the original large-level parallax/exploration system is not ported.

`src/simulation.ts` uses 120 Hz Matter.js updates, radius 16, gravity 1.1×0.001 px/ms², pull cap 140, dead zone 6, kick strength 0.125 and retained velocity 0.55. Godot uses gravity 1100 px/s²; Matter's normalized px/60-Hz-frame velocities convert by ×60, giving maximum kick 1050 px/s. The opposing momentum projection clamp is ported. Spin converts to rad/s. Boost acceleration 2 per normalized frame becomes approximately 7200 px/s² with the same fade toward 1080 px/s. Air damping is approximately 0.09/s and angular damping 4.8/s. These are starting conversions, not proof of identical trajectories.

## Expected physics differences

Godot's contact solver, friction combination, bounce combination, sleeping and penetration correction differ from Matter.js. Matter selects maximum restitution while Godot normally combines materials; this prototype puts 0.76 bounce on the ball and zero on timber to avoid summing two bounces. Native continuous collision detection plus a fixed 120 Hz tick replaces Matter's adaptive collision substeps. Polygon seams lack the reference's explicit circular joint caps. Spin/rolling and moving-contact response will differ even with the same constants. The aim preview raycasts native colliders and predicts gravity/rebounds, but approximates sphere contacts and excludes future boost forces; treat it as guidance. Goal crossing checks the whole ball crossing the mouth in the correct direction with clearance, following the reference. The reference's 0.65 s net damping/announcer celebration is simplified to an immediate result card.

A release-quality match requires reference trajectory recordings for fixed pulls, rebound angles, rolling stops and moving-ball correction shots, followed by numerical comparison and human A/B playtesting on phones. This prototype is not a claim of physics parity.

## Reuse versus rewrite

Reuse approved raster/SVG art, audio sources, level coordinate/polygon data, level design, campaign IDs/revisions, star thresholds and product rules. Data conversion can be scripted for the full campaign and checked for geometry and goal-mouth validity. The reference's progress records are keyed by campaign identity/revision; this one-level prototype stores a best score in Godot ConfigFile. Importing existing browser localStorage records requires an explicit migration path.

Rewrite TypeScript/Matter runtime, canvas materials and rendering, camera controls, DOM HUD, touch/pinch interaction, mechanic implementations, browser localStorage wrappers and Level Studio integration in GDScript/native nodes. Port the existing tests' behavioural intent, rather than assuming the TypeScript tests validate Godot. Preserve game data as an engine-independent schema if both versions will coexist.

## Feasibility

Godot is a credible fit for a polished mobile 2D physics puzzle: native reusable scenes, editor iteration, collision tools and iOS/Android export are strong advantages. Existing content and art have useful reuse value; gameplay code and editor systems are a substantial port. The biggest risks are game feel, geometry seams at high speeds, all mechanic combinations, camera/input across screen sizes, and migrating user progress. A full commercial migration is a multi-stage engineering project, not a file conversion. Next gate: device-tested vertical slice with measured shot/rebound parity, representative spring/switch/mover levels, audio and interruption handling, then a full data importer and campaign regression suite. A reliable schedule needs that gate and an inventory of all mechanics/editor requirements; this single-level result alone cannot establish it.

## V2 changes

The original level is now authored scene data, with shared gameplay, native polygon editing, stable IDs and reusable objects. See ARCHITECTURE.md for the V2 design. The one-level V1 hard-coding and near-ball aim restriction described above have been replaced. Circle-sweep trajectory guidance improves obstacle clearance, and goal art no longer draws an entrance strand. The underlying kick conversion, damping, 120 Hz physics and boost tuning are preserved; V2 changes usability rather than claiming a newly matched solver. New Timber climb is a Godot editor demonstration level, not a recreation of an existing TypeScript puzzle.
