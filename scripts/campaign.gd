extends RefCounted
## Explicit order: adding a published course never enrolls experimental scenes.
var entries: Array[Dictionary] = []
var progress_path = "user://progress.cfg"
func _init():
	var manifest = JSON.parse_string(FileAccess.get_file_as_string("res://campaign.json"))
	for path in manifest.levels:
		var draft = JSON.parse_string(FileAccess.get_file_as_string(path))
		var data = draft.level
		entries.append({"path":path,"id":"studio:"+str(draft.get("designId",draft.get("draftId",data.id))),"name":data.name,"thresholds":Vector2i(data.starShots[0],data.starShots[1])})
func read() -> ConfigFile:
	var save = ConfigFile.new()
	save.load(progress_path)
	return save
func index_of(path: String) -> int:
	for i in entries.size():
		if entries[i].path==path: return i
	return -1
func rating(shots: int, thresholds: Vector2i) -> int:
	if shots <= 0: return 0
	return 3 if shots<=thresholds.x else (2 if shots<=thresholds.y else 1)
func best(entry: Dictionary) -> int:
	var value = read().get_value(entry.id,"best",0)
	return maxi(0,int(value)) if value is int or value is float else 0
func stars(entry: Dictionary) -> int:
	return rating(best(entry),entry.thresholds)
func continue_path() -> String:
	for entry in entries:
		if best(entry)==0: return entry.path
	return entries[0].path if not entries.is_empty() else ""
func next_path(path: String) -> String:
	var index = index_of(path)
	return entries[index+1].path if index>=0 and index+1<entries.size() else ""
func chapter_count() -> int:
	return maxi(1,ceili(entries.size()/25.0))
func chapter_stars(chapter: int) -> int:
	var total = 0
	for i in range(chapter*25,mini(entries.size(),(chapter+1)*25)): total += stars(entries[i])
	return total
func record(id: String, shots: int, thresholds: Vector2i) -> Error:
	if shots<=0: return ERR_INVALID_PARAMETER
	var save = read()
	var previous = int(save.get_value(id,"best",shots))
	var result = mini(previous,shots) if previous>0 else shots
	save.set_value(id,"best",result)
	save.set_value(id,"stars",rating(result,thresholds))
	save.set_value(id,"completed",true)
	return save.save(progress_path)
func sound_enabled() -> bool:
	return read().get_value("settings","sound",true)==true
func set_sound(enabled: bool) -> Error:
	var save = read()
	save.set_value("settings","sound",enabled)
	return save.save(progress_path)
