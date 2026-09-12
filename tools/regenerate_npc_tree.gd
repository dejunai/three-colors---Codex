extends SceneTree

# Run from the project root:
# godot --headless --path . --script res://tools/regenerate_npc_tree.gd
# Updates the standalone HTML using the game's own loader/parser.
func _initialize() -> void:
	var Runtime = load("res://scripts/shared/dialogue_runtime.gd")
	var path = "res://docs/npc-tree-patched.html"
	var html = FileAccess.get_file_as_string(path).replace("\r\n", "\n")
	var start = html.find("const NPCS = ")
	var finish = html.find("\n\nconst LOCATIONS", start)
	assert(start >= 0 and finish > start, "NPC data anchors missing")
	var previous = JSON.parse_string(html.substr(start + 13, finish-start-13).strip_edges().trim_suffix(";"))
	var data = {}
	var names = DirAccess.get_files_at("res://dialogue")
	names.sort()
	var blocks = 0
	for filename in names:
		if not filename.ends_with(".dialogue"): continue
		var definition = Runtime.load_npc("res://dialogue/" + filename)
		assert(definition.errors.is_empty(), "%s: %s" % [filename, definition.errors])
		if definition.npc.is_empty() or definition.npc.contains("{"): continue
		var old = previous.get(definition.npc, {})
		data[definition.npc] = {"label": old.get("label", definition.npc.capitalize()), "color": old.get("color", "#608060"), "location": definition.location, "schedule": definition.schedule, "source": "dialogue/" + filename, "topics": definition.topics}
		blocks += definition.topics.size()
	var serialized = JSON.stringify(data).replace("<", "\\u003c")
	html = html.substr(0,start) + "const NPCS = " + serialized + ";" + html.substr(finish)
	var view_start = html.find("function gateClass(")
	if view_start < 0: view_start = html.find("function escapeHtml(")
	var view_end = html.find("function toggleTopic(", view_start)
	assert(view_start >= 0 and view_end > view_start)
	html = html.substr(0,view_start) + FileAccess.get_file_as_string("res://tools/npc_tree_view.js") + "\n" + html.substr(view_end)
	# Browser-injected download artifacts are not part of this offline reference.
	var scripts = RegEx.new()
	scripts.compile("(?s)<script[^>]*src=[^>]*>.*?</script>")
	html = scripts.sub(html, "", true)
	# Include all real authored location names in navigation, including new ones.
	html = html.replace('const byLoc = {};', 'const byLoc = {};\nObject.values(NPCS).forEach(npc => { if (!LOC_ORDER.includes(npc.location)) LOC_ORDER.push(npc.location); });') if not html.contains('if (!LOC_ORDER.includes(npc.location))') else html
	var file = FileAccess.open(path, FileAccess.WRITE)
	assert(file != null)
	file.store_string(html)
	file.close()
	print("NPC TREE GENERATED: %d concrete NPCs, %d topic blocks; template excluded" % [data.size(),blocks])
	quit()
