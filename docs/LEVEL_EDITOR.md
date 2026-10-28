# Design a level without writing code

Use the standard Godot 4 editor. This repository/CI is tested with **4.6.3**; use matching export templates. Later 4.x releases may upgrade scene files, so keep a Git backup before upgrading.

## Open and start

1. Download/clone `charliegghaccount/godot-test-goal-in-one`, open Godot, choose **Import**, and select its `project.godot`.
2. Select the **2D** workspace at the top. Wait for asset import. In **Project → Project Settings → Plugins**, check **Goal In One Level Studio** is enabled (it is enabled by default).
3. In the FileSystem dock open `levels/green_runway.tscn` to see the original prototype, or `levels/timber_climb.tscn` for a large horizontal/vertical course. Root settings appear in the Inspector; geometry appears in the Scene tree.
4. In the 2D toolbar choose **Goal In One → New level from template**. Save as e.g. `res://levels/my_first_level.tscn`. It opens with a floor, a visible football spawn and a white goal. The tool assigns a unique stable ID.

The editor is the native Godot editor on your Mac. The browser is for playing/testing saved levels, not for authoring them.

## Place wood, platforms, ramps and walls

- Drag `scenes/timber.tscn` from the FileSystem dock into the 2D canvas to add a platform. Drag `scenes/ramp.tscn` for a ramp. They are reusable instances with their own vertex and grass settings.
- Select the object in the Scene tree. Use Godot's **Move** toolbar tool to drag it, **Rotate** to rotate it. Snap/grid options are in the 2D toolbar. Duplicate selected objects with **Cmd+D** (Ctrl+D on Windows/Linux).
- For freeform shapes select a wooden object, then use the **Polygon2D polygon toolbar** above the canvas. Use **Edit polygon** to drag individual vertices. Use **Create polygon** to draw a new outline, clicking each corner and closing on the first point. The Inspector's **Polygon** array is also available, but ordinary editing does not require typing coordinates.
- Resize platforms by moving their vertices/edges in polygon edit mode. This keeps timber texture density consistent. Avoid non-uniformly scaling whole physics objects; edit vertices instead. Rotation and translation are supported.
- Create walls with tall/thin polygons, or duplicate a platform and rotate it. Concave polygons are supported; avoid self-intersecting outlines, duplicate points and zero-area shapes.
- In the Inspector toggle **Grass Edging** independently for each wooden object. Grass is cosmetic and is drawn on upward-facing polygon edges in the object's local coordinates. Rotate objects before deciding which surfaces should have grass.

The exact same polygon drives rendering and native collision. You do not need to edit a separate CollisionPolygon2D. Generated physics children are deliberately not saved as duplicate authored geometry.

## Ball, goal and scoring

- Select **Spawn** in the Scene tree and drag the football preview to its starting position. Keep the name `Spawn`. It is an ordinary Marker2D. If deleted, drag `scenes/spawn.tscn` into the level and retain that name.
- Select **Goal** and move it. In the Inspector change **Goal Size** (width/height) and **Roof Ratio**. Artwork, three collision bars and crossing detection resize together. Keep its name `Goal`. Use **Goal Size**, rather than non-uniform scale, to resize. Its local origin is the bottom-left entrance. There is no left frame bar or left-edge net strand.
- Select the root level. Set **Level Name**, **Par**, and **Star Shots**: X is the maximum shots for three stars, Y for two stars; otherwise one star. Keep X ≥ 1 and Y ≥ X.
- **Level ID** is the stable save/progression key. Renaming the file/name does not change it. Use the New/Duplicate menu to generate IDs; manually copying a `.tscn` requires a new unique ID. Reusing an ID shares the best score.

## Size and camera

Select the root and change **Level Size**. This defines the illustrated background extent and camera bounds; it does not create physical walls. Add/resize the wooden perimeter separately.

- **Fit arena** shows the entire level, suitable for compact puzzles.
- **Follow ball** follows the ball horizontally and vertically inside the bounds. **Follow Zoom** sets magnification. `timber_climb.tscn` demonstrates this.
- **Gravity** and **Background** are per-level overrides for future worlds; normal gravity is 1100. Shared shot tuning lives in the ball implementation and does not need changing to design a level.

## Save, test, return and reopen

1. **Cmd+S** saves the scene. Keep playable scenes directly inside `res://levels/` (not a nested folder).
2. Press **F6 / Run Current Scene** (Mac keyboards may require Fn+F6). This immediately plays the currently open level using the shared game runtime. No publishing or campaign step is needed.
3. Drag backwards **anywhere outside the HUD** and release to kick. You can kick a moving ball. Small taps do not shoot. Restart resets the attempt and shots; Reset ball returns the ball while preserving shots; Pause freezes play.
4. **Explore** (or E) switches to camera-only interaction. Drag to pan both axes; mouse wheel zooms. **Return** (or E) restores level framing/follow. Explore drags never shoot. Touch uses a single finger for aiming or panning in the selected mode; pinch zoom is not implemented.
5. Press **F8 / Stop** to return to your unchanged editing scene. Changes made in the running game's Remote tree are temporary; make permanent edits in the local scene after stopping.
6. Close/reopen the `.tscn` through FileSystem to continue later. Commit/save your scene file with the project.

Press **F5 / Run Project** to open the normal game; the bottom-left picker lists all saved scenes directly in `levels/`. New scenes are discovered on startup. An already-running browser build cannot see unexported files on your Mac: re-export/deploy to include them.

## Duplicate a design

Open a level, choose **Goal In One → Duplicate current level**, and save to a new filename in `levels/`. The current design is copied and gets a fresh stable ID. The tool refuses to overwrite existing files. All normal subsequent saves use Cmd+S. It is intentionally a small native-editor helper, not a second browser Level Studio.

## Common mistakes

- No Goal In One toolbar: choose 2D and enable the plugin.
- Cannot see polygon handles: select the wood's Polygon2D root in the Scene tree, then choose polygon edit mode; do not select a generated collision child.
- Goal/Spawn deleted or renamed: restore those names, as runtime validation requires them.
- A scene is not in the picker: save it directly in `levels/`, then restart the game/export.
- Changing a level should invalidate old best scores: use a new stable ID for a revised puzzle.
- Amber warning on a level root: check missing Spawn/Goal, scoring thresholds or invalid polygons. Headless runtime tests validate all saved levels.

## V3: build puzzles with mechanics

Drag any of the following scenes from the FileSystem dock into the level canvas. Select its root in the Scene tree, use native Move/Rotate tools, and adjust the Inspector properties. Previews are visible while editing. **Dimensions** are local pixels: prefer them over non-uniform node scaling so collision and artwork stay predictable. Save with Cmd+S and use F6/F8 exactly as for ordinary geometry.

| Scene | Inspector controls and behaviour |
| --- | --- |
| `scenes/boost.tscn` | Green forward pad. **Direction** defaults to (1,0); **Dimensions**, **Acceleration** (px/s²), **Maximum Speed** (px/s). Keep its long axis on the floor. |
| `scenes/backward_boost.tscn` | Matching orange pad with Direction (-1,0). It uses the same sensor and acceleration code as the forward pad. Rotate the node to rotate either pad's force. |
| `scenes/reset_pad.tscn` | Red hazard. Touching it returns the football to Spawn without deleting the ball or erasing shots. It flashes, emits a ring and plays a short falling cue. **Cooldown Seconds** prevents rapid repeated resets. |
| `scenes/spring.tscn` | Spring launcher. Local UP is the launch direction; rotate the node to aim. **Launch Speed** is px/s, **Momentum Retention** preserves a fraction of incoming velocity, and **Retrigger Delay** debounces contact. The cap compresses briefly then extends. |
| `scenes/fan.tscn` | Ground fan, local UP by default. **Airflow Range** extends above its housing, **Airflow Acceleration** applies force, and **Maximum Air Speed** limits acceleration along the airflow. Rotate the whole node to redirect both the sensor and force. The blue region previews range; blades and flow marks animate in play. Housing is decorative; the sensor includes the housing so a rolling ball can enter the stream. |
| `scenes/pressure_switch.tscn` | Low floor switch. **Linked Gate** uses Godot's native node picker: select/assign the Gate node in the same level. **Activation Mode** is Toggle, Timed or Hold; Timed uses **Open Seconds**. The cap moves down while the ball overlaps it. |
| `scenes/gate.tscn` | Wooden moving barrier. **Dimensions**, **Movement Direction** (local coordinates), **Travel Distance** and **Movement Speed** define its track. The yellow editor line/outline previews the endpoint. **Automatic** makes it cycle between endpoints with **Endpoint Wait**. Leave Automatic off when linking a pressure switch. |

### Link a switch to a gate without code

1. Drag a gate into the level; give it a helpful Scene-tree name such as `ExitGate`.
2. Move it to its **closed** position. Set its dimensions, movement direction, travel and speed. Leave Automatic off.
3. Drag a pressure switch onto a floor. Select it, then use **Linked Gate → Assign** and pick `ExitGate`. Godot stores a relative NodePath, so saving/duplicating the whole level retains the link.
4. Choose **Toggle** (each new contact reverses the gate), **Timed** (opens for Open Seconds, then closes), or **Hold** (open while pressed). Do not manually copy only a switch to a different parent without rechecking its link.
5. Save, press F6, and roll/kick the ball onto the switch. The cap depresses and the linked gate moves. An unlinked switch shows an Inspector configuration warning and does nothing in play.

Each switch is intended to command one manual gate. Multiple switches issuing contradictory commands to one gate are not arbitrated; the latest command wins. Avoid placing Spawn inside a hazard or closed gate. Sensors rearm after leaving/reentering; springs do not repeatedly fire while continuously overlapped. Reset ball/red pads retain switch/gate state and shots, matching an attempt correction; Restart reloads the level and resets all mechanism state and shots.

### Editable experiments

- `levels/experiment_boost_spring.tscn`: forward runway into a rotated spring, a wooden bank, and a backward return pad.
- `levels/experiment_fan_hazard.tscn`: upward and angled fans, a red reset strip, and an overhead shelf.
- `levels/experiment_switch_gate.tscn`: a timed floor switch linked to a sliding gate, plus a separate automatic gate.

These are technical labs, not balanced campaign levels. Duplicate them with the Goal In One menu to experiment. New mechanics are native scenes and require no additional editor/plugin installation.
