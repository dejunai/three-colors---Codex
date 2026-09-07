extends RefCounted

# Storage is chapter-neutral. Each chapter validates/migrates its own state payload.
func read(path:String) -> Dictionary:
	if path.is_empty() or not FileAccess.file_exists(path): return {}
	var file=FileAccess.open(path,FileAccess.READ)
	if file==null: return {}
	var value=JSON.parse_string(file.get_as_text())
	return value if value is Dictionary else {}

func write(path:String,payload:Dictionary) -> Error:
	var temporary=path+".tmp"
	var file=FileAccess.open(temporary,FileAccess.WRITE)
	if file==null: return FileAccess.get_open_error()
	# Exact floating-point round trips preserve encounter timing and remaining relief.
	file.store_string(JSON.stringify(payload,"\t",true,true))
	file.flush()
	var result=file.get_error()
	file.close()
	if result!=OK: return result
	return DirAccess.rename_absolute(temporary,path)

func newest(candidates:Array) -> String:
	var best=""
	var timestamp=-1
	for candidate in candidates:
		if FileAccess.file_exists(candidate) and FileAccess.get_modified_time(candidate)>timestamp:
			best=candidate
			timestamp=FileAccess.get_modified_time(candidate)
	return best
