extends RefCounted
## Consumes the Web Studio's existing goal-in-one-level v1 envelope. Never loads data-supplied resources.
var errors: PackedStringArray = []
func number(d: Dictionary, key: String, fallback: float = 0, low: float = -100000, high: float = 100000) -> float:
	var v = d.get(key,fallback)
	if not (v is float or v is int) or not is_finite(float(v)) or float(v)<low or float(v)>high:
		errors.append("Invalid numeric field: "+key)
		return fallback
	return float(v)
func point(v: Variant) -> Vector2:
	if not v is Dictionary:
		errors.append("Expected point {x,y}")
		return Vector2.ZERO
	return Vector2(number(v,"x"),number(v,"y"))
func objects(d: Dictionary,key: String) -> Array:
	var a = d.get(key,[])
	if not a is Array or a.size()>2000:
		errors.append("Invalid/oversized object array: "+key)
		return []
	for item in a:
		if not item is Dictionary:
			errors.append("Invalid object in "+key)
			return []
	return a
func polygon(value: Variant) -> PackedVector2Array:
	var result = PackedVector2Array()
	if not value is Array or value.size()<3 or value.size()>512:
		errors.append("Polygon needs 3–512 vertices")
		return result
	for vertex in value: result.append(point(vertex))
	if Geometry2D.triangulate_polygon(result).is_empty(): errors.append("Invalid polygon geometry")
	return result
func prefab(name: String) -> Node2D:
	return load("res://scenes/"+name+".tscn").instantiate()
func wood(level: Node, points: PackedVector2Array, grass: bool):
	var node = prefab("timber")
	node.polygon = points
	node.grass_edging = grass
	level.add_child(node)
func beam(level: Node,a: Vector2,b: Vector2,grass: bool):
	if a.distance_to(b)<0.01: return
	var n = (b-a).normalized().orthogonal()*5.2
	wood(level,PackedVector2Array([a+n,b+n,b-n,a-n]),grass and absf(a.y-b.y)<0.1)
func parse(text: String) -> Dictionary:
	errors.clear()
	if text.length()>2000000: return {"errors":["Level exceeds 2 MB limit"]}
	var draft = JSON.parse_string(text)
	if not draft is Dictionary or draft.get("format")!="goal-in-one-level" or draft.get("version")!=1 or not draft.get("level") is Dictionary:
		return {"errors":["Expected goal-in-one-level version 1 draft JSON"]}
	var d: Dictionary = draft.level
	if d.has("grass") and not d.grass is bool: errors.append("Grass must be boolean")
	var level = Node2D.new()
	level.set_script(preload("res://scripts/level.gd"))
	level.level_id = "studio:"+str(draft.get("designId",draft.get("draftId",d.get("id","preview"))))
	level.level_name = str(d.get("name","Studio test")).left(200)
	level.par = int(number(d,"par",1,1,999))
	var stars = d.get("starShots",[1,3])
	if not stars is Array or stars.size()!=2 or not (stars[0] is float or stars[0] is int) or not (stars[1] is float or stars[1] is int):
		errors.append("Invalid starShots")
	else:
		level.star_shots = Vector2i(int(stars[0]),int(stars[1]))
		if stars[0]<1 or stars[1]<stars[0]: errors.append("Invalid star thresholds")
	var spawn = Marker2D.new()
	spawn.name = "Spawn"
	spawn.position = point(d.get("start"))
	level.add_child(spawn)
	var g = d.get("goal",{})
	if not g is Dictionary: g = {}; errors.append("Missing goal")
	var goal = prefab("goal")
	goal.name = "Goal"
	goal.position = point(g)
	var width = number(g,"w",107,65,10000)
	var height = number(g,"h",100,65,10000)
	goal.goal_size = Vector2(width,height)
	goal.roof_ratio = number(g,"roof",82,1,width)/width
	if g.get("direction",1)!=1: errors.append("Unsupported: left-facing goal")
	level.add_child(goal)
	var edge = polygon(d.get("boundary",d.get("outline")))
	var has_boundary = d.has("boundary")
	if edge.size()>=3:
		var lo = edge[0]
		var hi = edge[0]
		for v in edge: lo = lo.min(v); hi = hi.max(v)
		hi = hi.max(goal.position+Vector2(width,0))
		level.camera_origin = lo-Vector2(24,28)
		level.level_size = hi-level.camera_origin+Vector2(24,28)
		for i in range(edge.size() if has_boundary else edge.size()-1):
			var a = edge[i]
			var b = edge[(i+1)%edge.size()]
			if has_boundary and g.get("placement","")!="free" and absf(a.x-goal.position.x)<0.01 and absf(b.x-goal.position.x)<0.01 and minf(a.y,b.y)<=goal.position.y-height+0.01 and maxf(a.y,b.y)>=goal.position.y-0.01:
				var top = goal.position-Vector2(0,height)
				beam(level,a,top if a.y<b.y else goal.position,false)
				beam(level,goal.position if a.y<b.y else top,b,false)
			else: beam(level,a,b,d.get("grass",true)==true)
		if not has_boundary:
			beam(level,edge[-1],goal.position-Vector2(0,height),false)
			beam(level,edge[0],goal.position+Vector2(width,0),d.get("grass",true)==true)
	for o in objects(d,"obstacles"):
		# Studio already rotates polygon vertices; rotation is authoring metadata, not another transform.
		if o.has("grass") and not o.grass is bool:
			errors.append("Object grass must be boolean")
			continue
		wood(level,polygon(o.get("points")),o.get("grass",true))
	for s in objects(d,"surfaces"):
		var kind = s.get("kind","")
		if not kind in ["forward","backward","delete"]: errors.append("Unsupported surface: "+str(kind)); continue
		var node = prefab("reset_pad" if kind=="delete" else "boost")
		var w = number(s,"w",100,8,10000)
		node.position = Vector2(number(s,"x")+w/2,number(s,"y")-6)
		node.dimensions = Vector2(w,8)
		if kind!="delete":
			node.direction = Vector2.RIGHT if kind=="forward" else Vector2.LEFT
			node.acceleration = number(s,"acceleration",2,0,5)*3600
		level.add_child(node)
	var mechanics = d.get("mechanics",{})
	if not mechanics is Dictionary: mechanics = {}; errors.append("Invalid mechanics")
	for key in mechanics:
		if not key in ["springs","gates","switches"] and mechanics[key]!=[]: errors.append("Unsupported mechanic: "+str(key))
	if not objects(d,"movers").is_empty(): errors.append("Unsupported: moving blocks")
	for s in objects(mechanics,"springs"):
		var node = prefab("spring")
		var w = number(s,"w",90,8,10000)
		node.position = Vector2(number(s,"x")+w/2,number(s,"y")-6)
		node.dimensions = Vector2(w,10)
		var angle = deg_to_rad(number(s,"angle",90))
		node.local_launch_direction = Vector2(cos(angle),-sin(angle))
		node.visual_height = 38.0
		node.launch_speed = minf(24,number(s,"strength",20,0,100))*60
		level.add_child(node)
	var gates = {}
	for s in objects(mechanics,"gates"):
		var id = str(s.get("id",""))
		if id.is_empty() or gates.has(id): errors.append("Missing/duplicate gate ID")
		var node = prefab("gate")
		node.position = point(s)
		node.dimensions = Vector2(number(s,"w",40,12,10000),number(s,"h",160,12,10000))
		var offset = point(s.get("offset",{"x":0,"y":-170}))
		node.movement_direction = offset.normalized()
		node.travel_distance = offset.length()
		node.movement_speed = offset.length()/number(s,"openDuration",0.7,0.05,100)
		node.closing_speed = offset.length()/number(s,"closeDuration",0.7,0.05,100)
		level.add_child(node)
		gates[id] = node
	for s in objects(mechanics,"switches"):
		var node = prefab("pressure_switch")
		node.position = point(s)
		if not s.has("w") and not s.has("h"): errors.append("Unsupported: legacy circular pressure switch; resize it in Studio")
		node.dimensions = Vector2(number(s,"w",36,8,10000),number(s,"h",36,8,10000))
		if not s.get("mode","toggle") in ["toggle","timed"]: errors.append("Unsupported switch mode")
		node.activation_mode = 1 if s.get("mode")=="timed" else 0
		node.open_seconds = number(s,"duration",6,0.2,100)
		level.add_child(node)
		var id = str(s.get("gateId",""))
		if not gates.has(id): errors.append("Switch refers to missing gate: "+id)
		else: node.linked_gate = node.get_path_to(gates[id])
	var camera = d.get("camera",{})
	if not camera is Dictionary: camera = {}; errors.append("Invalid camera")
	var mode = camera.get("mode","fixed")
	if not mode in ["fixed","follow-x","follow-xy"]: errors.append("Unsupported camera mode")
	level.camera_mode = 0 if mode=="fixed" else 1
	level.follow_vertical = mode!="follow-x"
	level.follow_zoom = maxf(1280.0/number(camera,"viewWidth",1280,100,10000),720.0/number(camera,"viewHeight",720,100,10000))*number(camera,"zoom",1,0.1,10)
	if camera.has("initial"): errors.append("Unsupported: custom camera initial point")
	if camera.has("deadZone"): errors.append("Unsupported: custom camera dead zone")
	level.camera_speed = -log(1-number(camera,"smoothing",0.11,0.001,0.99))*60
	if camera.has("bounds"):
		var bounds = camera.bounds
		if bounds is Dictionary:
			level.camera_origin = point(bounds)
			level.level_size = Vector2(number(bounds,"w",1280,320,100000),number(bounds,"h",720,240,100000))
		else: errors.append("Invalid camera bounds")
	if not camera.get("windows",[]) is Array or not camera.get("windows",[]).is_empty(): errors.append("Unsupported: camera view windows; remove camera regions before testing")
	level.set_meta("studio_draft",draft.duplicate(true))
	if not errors.is_empty():
		level.free()
		return {"errors":errors}
	return {"errors":[],"level":level}
