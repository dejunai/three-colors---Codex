extends RefCounted

# Flat-file dialogue grammar and its GATE-expression evaluator. Pure text in,
# structured data out — no engine/game references, so this file is testable
# in isolation (see tests/dialogue_lang_flow.gd) and the only place that
# needs to change if the grammar itself grows.
#
# FILE SHAPE
#   NPC: father_behan
#   LOCATION: rectory
#   INCLUDE: shared_rebuffs.dialogue      (repeatable; optional)
#   SCHEDULE: dawn={home}, midday={workplace}, ...   (background/template NPCs only)
#
#   TOPIC: topic_id
#     GATE: <expression>          ("never" / "always" / a boolean expression)
#     LABEL: "Menu button text"   (optional; defaults to topic_id.capitalize())
#     SPEAKER: "Line of dialogue, may
#               continue across indented lines until the closing quote,
#               or use \n / \n\n inline to keep one physical line and
#               still reproduce the source material's paragraph breaks."
#     [A bracketed line is a stage direction/beat, not spoken dialogue.]
#     CHOICE: "The player's own line."
#       SPEAKER: "The reply. CHOICE always opens a nested, linear
#                 continuation — it never branches by itself."
#       NOTEBOOK: stable_note_id | "Free text written straight into the record; no separate
#                  facts table to keep in sync with the dialogue."
#     FORK:
#       CHOICE: "Option A — mutually exclusive with any sibling CHOICE here."
#         SPEAKER: "..."
#       CHOICE: "Option B."
#         SPEAKER: "..."
#
# A `#` at the start of a (stripped) line is a full-line comment. A TOPIC
# with no dialogue lines under it (just GATE/comments) is a documentation
# stub — it parses fine and simply never surfaces in play.
#
# TOPIC IDS: the id "default" is reserved for an NPC's automatic opening
# line. Multiple `TOPIC: default` blocks may exist with different GATEs;
# the first whose GATE is true (file order) wins, and it is never shown in
# a menu. Every other topic id is a revisitable menu entry whenever its
# GATE evaluates true — there is no separate "is this a menu" flag to
# author or get out of sync as new topics are added later.
#
# GATE GRAMMAR: "never" | "always" | <expr>
#   expr       := or_expr
#   or_expr    := and_expr (OR and_expr)*
#   and_expr   := unary (AND unary)*
#   unary      := NOT unary | atom
#   atom       := "(" expr ")" | comparison
#   comparison := NAME ["(" arg ("," arg)* ")"] [cmp value]
#   cmp        := "<" | "<=" | ">" | ">=" | "=" | "!="
# A bare NAME with no call and no comparator must itself resolve to a bool.
# `=`/`!=` compare case-insensitively and match on substring containment
# (so `coat = plain` matches state.coat == "Plain wool coat" without the
# author needing to know the exact stored string). `<`/`<=`/`>`/`>=`
# compare numerically.
#
# Built-in functions/fields are registered by the caller via the `ctx`
# passed to evaluate() — see dialogue_runtime.gd's make_context() for the
# actual vocabulary (visit_count, topic_count, spoken_to, evidence, flag,
# topic_done, coat, day, phase, estate_complete).

static func parse(text: String) -> Dictionary:
	var logical = _logical_lines(text)
	var i = 0
	var npc = ""
	var location = ""
	var schedule: Dictionary = {}
	var includes: Array = []
	var errors: Array = []
	while i < logical.size() and logical[i].indent == 0 and not logical[i].text.begins_with("TOPIC:"):
		var entry = logical[i]
		var colon = entry.text.find(":")
		if colon == -1:
			errors.append({"line": entry.line, "message": "Malformed header line '%s'" % entry.text})
			i += 1
			continue
		var key = entry.text.substr(0, colon).strip_edges().to_upper()
		var value = entry.text.substr(colon + 1).strip_edges()
		match key:
			"NPC": npc = value
			"LOCATION": location = value
			"SCHEDULE": schedule = _parse_schedule(value)
			"INCLUDE": includes.append(value)
			_: errors.append({"line": entry.line, "message": "Unknown header '%s'" % key})
		i += 1
	var topics: Array = []
	while i < logical.size():
		var entry = logical[i]
		if entry.indent != 0 or not entry.text.begins_with("TOPIC:"):
			errors.append({"line": entry.line, "message": "Expected a TOPIC block, found '%s'" % entry.text})
			i += 1
			continue
		var topic_id = entry.text.substr(6).strip_edges()
		var j = i + 1
		var body: Array = []
		while j < logical.size() and logical[j].indent > 0:
			body.append(logical[j])
			j += 1
		var parsed = _parse_topic_body(body, errors)
		parsed["id"] = topic_id
		parsed["line"] = entry.line
		topics.append(parsed)
		i = j
	return {"npc": npc, "location": location, "schedule": schedule, "includes": includes, "topics": topics, "errors": errors}

static func evaluate(ast: Dictionary, ctx: Dictionary) -> bool:
	match String(ast.get("op", "")):
		"lit": return bool(ast.value)
		"and": return evaluate(ast.left, ctx) and evaluate(ast.right, ctx)
		"or": return evaluate(ast.left, ctx) or evaluate(ast.right, ctx)
		"not": return not evaluate(ast.expr, ctx)
		"cmp": return _evaluate_cmp(ast, ctx)
		_: return false

# ---- content parsing ----

static func _parse_topic_body(body: Array, errors: Array) -> Dictionary:
	if body.is_empty():
		return {"gate_src": "never", "gate": {"op": "lit", "value": false}, "label": "", "steps": []}
	var base_indent = body[0].indent
	var gate_src = "never"
	var label = ""
	var tag = ""
	var timing = ""
	var k = 0
	while k < body.size() and body[k].indent == base_indent:
		var text = body[k].text
		if text.begins_with("GATE:"):
			gate_src = text.substr(5).strip_edges()
			k += 1
		elif text.begins_with("TAG:"):
			tag = text.substr(4).strip_edges()
			k += 1
		elif text.begins_with("TIME:"):
			timing = text.substr(5).strip_edges()
			k += 1
		elif text.begins_with("LABEL:"):
			label = _quoted(text.substr(6))
			k += 1
		else:
			break
	var steps = _parse_steps(body, k, body.size(), base_indent, errors)
	return {"gate_src": gate_src, "gate": _parse_gate(gate_src), "label": label, "tag": tag, "timing": timing, "steps": steps}

static func _parse_steps(body: Array, start: int, end: int, indent: int, errors: Array) -> Array:
	var steps: Array = []
	var k = start
	while k < end:
		var entry = body[k]
		if entry.indent != indent:
			errors.append({"line": entry.line, "message": "Unexpected indentation near '%s'" % entry.text})
			k += 1
			continue
		var line = entry.text
		if line.begins_with("["):
			steps.append({"kind": "beat", "text": _strip_brackets(line)})
			k += 1
		elif line.begins_with("EVIDENCE:"):
			steps.append({"kind": "evidence", "id": line.substr(9).strip_edges()})
			k += 1
		elif line.begins_with("NOTEBOOK:"):
			var payload = line.substr(9).strip_edges()
			var note_id = ""
			if not payload.begins_with("\"") and payload.contains("|"):
				var separator = payload.find("|")
				note_id = payload.substr(0, separator).strip_edges()
				payload = payload.substr(separator + 1).strip_edges()
			steps.append({"kind": "notebook", "id": note_id, "text": _quoted(payload)})
			k += 1
		elif line.begins_with("CHOICE:"):
			var label = _quoted(line.substr(7))
			var child_indent = _peek_indent(body, k + 1, end)
			var child_end = _block_end(body, k + 1, end, child_indent) if child_indent > indent else k + 1
			steps.append({"kind": "line", "speaker": "WALTER CORWIN", "text": label, "player": true})
			if child_indent > indent:
				steps.append_array(_parse_steps(body, k + 1, child_end, child_indent, errors))
			k = child_end
		elif line.begins_with("FORK:"):
			var fork_indent = _peek_indent(body, k + 1, end)
			var fork_end = _block_end(body, k + 1, end, fork_indent)
			steps.append({"kind": "fork", "options": _parse_fork(body, k + 1, fork_end, fork_indent, errors)})
			k = fork_end
		else:
			var colon = line.find(":")
			if colon == -1:
				errors.append({"line": entry.line, "message": "Unrecognized line '%s'" % line})
				k += 1
				continue
			var speaker = line.substr(0, colon).strip_edges()
			steps.append({"kind": "line", "speaker": speaker, "text": _quoted(line.substr(colon + 1)), "player": false})
			k += 1
	return steps

static func _parse_fork(body: Array, start: int, end: int, indent: int, errors: Array) -> Array:
	var options: Array = []
	if indent == -1: return options
	var k = start
	while k < end:
		var entry = body[k]
		if entry.indent != indent or not entry.text.begins_with("CHOICE:"):
			errors.append({"line": entry.line, "message": "FORK blocks may only contain CHOICE entries"})
			k += 1
			continue
		var label = _quoted(entry.text.substr(7))
		var child_indent = _peek_indent(body, k + 1, end)
		var child_end = _block_end(body, k + 1, end, child_indent) if child_indent > indent else k + 1
		var steps: Array = [{"kind": "line", "speaker": "WALTER CORWIN", "text": label, "player": true}]
		if child_indent > indent:
			steps.append_array(_parse_steps(body, k + 1, child_end, child_indent, errors))
		# Tag/timing live on the topic (session-level), not per fork option —
		# every branch of one FORK still belongs to the same topic/session.
		options.append({"label": label, "steps": steps})
		k = child_end
	return options

static func _peek_indent(body: Array, index: int, end: int) -> int:
	return body[index].indent if index < end else -1

static func _block_end(body: Array, start: int, end: int, indent: int) -> int:
	if indent == -1: return start
	var k = start
	while k < end and body[k].indent >= indent: k += 1
	return k

# ---- lexical scanning: raw lines -> comment-free, quote-merged logical lines ----

static func _logical_lines(text: String) -> Array:
	var raw = text.split("\n")
	var out: Array = []
	var i = 0
	while i < raw.size():
		var line: String = raw[i]
		var stripped = line.strip_edges()
		if stripped.is_empty() or stripped.begins_with("#"):
			i += 1
			continue
		var indent = line.length() - line.lstrip(" \t").length()
		var start_line = i + 1
		var content = stripped
		while _odd_quotes(content) and i + 1 < raw.size():
			i += 1
			var cont = raw[i].strip_edges()
			if cont.is_empty() or cont.begins_with("#"): continue
			content += " " + cont
		out.append({"indent": indent, "text": content, "line": start_line})
		i += 1
	return out

static func _odd_quotes(s: String) -> bool:
	var count = 0
	var escaped = false
	for c in s:
		if escaped:
			escaped = false
			continue
		if c == "\\":
			escaped = true
			continue
		if c == "\"": count += 1
	return count % 2 == 1

static func _quoted(s: String) -> String:
	var trimmed = s.strip_edges()
	if trimmed.length() >= 2 and trimmed.begins_with("\"") and trimmed.ends_with("\""):
		trimmed = trimmed.substr(1, trimmed.length() - 2)
	# \n lets one physical line hold the source material's paragraph breaks
	# (e.g. "...ambitions.\n\nI'll discuss...") without relying on space-joined
	# continuation lines, which would otherwise collapse them to one space.
	return trimmed.replace("\\\"", "\"").replace("\\n", "\n")

static func _strip_brackets(s: String) -> String:
	var trimmed = s.strip_edges()
	if trimmed.begins_with("[") and trimmed.ends_with("]"):
		trimmed = trimmed.substr(1, trimmed.length() - 2)
	return trimmed.strip_edges()

static func _parse_schedule(value: String) -> Dictionary:
	var out: Dictionary = {}
	for part in value.split(","):
		var kv = part.split("=", true, 1)
		if kv.size() == 2: out[kv[0].strip_edges()] = kv[1].strip_edges()
	return out

# ---- GATE expression parsing ----

static func _parse_gate(src: String) -> Dictionary:
	var trimmed = src.strip_edges()
	var lowered = trimmed.to_lower()
	if lowered == "never" or trimmed.is_empty(): return {"op": "lit", "value": false}
	if lowered == "always": return {"op": "lit", "value": true}
	var state = {"tokens": _tokenize(trimmed), "pos": 0}
	return _expr(state)

static func _is_ident_char(c: String) -> bool:
	return c.to_lower() != c.to_upper() or c.is_valid_int() or c == "_" or c == "."

static func _tokenize(src: String) -> Array:
	var tokens: Array = []
	var i = 0
	var n = src.length()
	while i < n:
		var c = src[i]
		if c == " " or c == "\t":
			i += 1
			continue
		if c == "(" or c == ")" or c == ",":
			tokens.append({"kind": "punct", "value": c})
			i += 1
			continue
		if c == "<" or c == ">" or c == "=" or c == "!":
			var two = src.substr(i, 2)
			if two == "<=" or two == ">=" or two == "!=":
				tokens.append({"kind": "op", "value": two})
				i += 2
				continue
			tokens.append({"kind": "op", "value": c})
			i += 1
			continue
		if c == "\"":
			var j = i + 1
			while j < n and src[j] != "\"": j += 1
			tokens.append({"kind": "ident", "value": src.substr(i + 1, j - i - 1)})
			i = j + 1
			continue
		var j = i
		while j < n and _is_ident_char(src[j]): j += 1
		if j == i:
			i += 1
			continue
		tokens.append({"kind": "ident", "value": src.substr(i, j - i)})
		i = j
	return tokens

static func _peek_tok(state: Dictionary):
	return state.tokens[state.pos] if state.pos < state.tokens.size() else null

static func _advance_tok(state: Dictionary):
	var t = _peek_tok(state)
	state.pos += 1
	return t

static func _expr(state: Dictionary) -> Dictionary:
	return _or_expr(state)

static func _or_expr(state: Dictionary) -> Dictionary:
	var node = _and_expr(state)
	while _peek_tok(state) != null and _peek_tok(state).kind == "ident" and String(_peek_tok(state).value).to_upper() == "OR":
		_advance_tok(state)
		node = {"op": "or", "left": node, "right": _and_expr(state)}
	return node

static func _and_expr(state: Dictionary) -> Dictionary:
	var node = _unary(state)
	while _peek_tok(state) != null and _peek_tok(state).kind == "ident" and String(_peek_tok(state).value).to_upper() == "AND":
		_advance_tok(state)
		node = {"op": "and", "left": node, "right": _unary(state)}
	return node

static func _unary(state: Dictionary) -> Dictionary:
	if _peek_tok(state) != null and _peek_tok(state).kind == "ident" and String(_peek_tok(state).value).to_upper() == "NOT":
		_advance_tok(state)
		return {"op": "not", "expr": _unary(state)}
	return _atom(state)

static func _atom(state: Dictionary) -> Dictionary:
	var tok = _peek_tok(state)
	if tok == null: return {"op": "lit", "value": false}
	if tok.kind == "punct" and tok.value == "(":
		_advance_tok(state)
		var node = _expr(state)
		if _peek_tok(state) != null and _peek_tok(state).value == ")": _advance_tok(state)
		return node
	if tok.kind == "ident" and String(tok.value).to_lower() == "always":
		_advance_tok(state)
		return {"op": "lit", "value": true}
	if tok.kind == "ident" and String(tok.value).to_lower() == "never":
		_advance_tok(state)
		return {"op": "lit", "value": false}
	return _comparison(state)

static func _comparison(state: Dictionary) -> Dictionary:
	var name_tok = _advance_tok(state)
	var name = String(name_tok.value) if name_tok != null else ""
	var args: Array = []
	var is_call = false
	if _peek_tok(state) != null and _peek_tok(state).kind == "punct" and _peek_tok(state).value == "(":
		is_call = true
		_advance_tok(state)
		while _peek_tok(state) != null and not (_peek_tok(state).kind == "punct" and _peek_tok(state).value == ")"):
			var a = _advance_tok(state)
			if a != null: args.append(String(a.value))
			if _peek_tok(state) != null and _peek_tok(state).kind == "punct" and _peek_tok(state).value == ",": _advance_tok(state)
		if _peek_tok(state) != null and _peek_tok(state).value == ")": _advance_tok(state)
	var cmp = ""
	var value = null
	if _peek_tok(state) != null and _peek_tok(state).kind == "op":
		cmp = _advance_tok(state).value
		var v = _advance_tok(state)
		value = v.value if v != null else null
	return {"op": "cmp", "name": name, "call": is_call, "args": args, "cmp": cmp, "value": value}

static func _evaluate_cmp(ast: Dictionary, ctx: Dictionary) -> bool:
	var resolved
	if ast.call:
		var fn = ctx.get("functions", {}).get(ast.name)
		if fn == null:
			push_error("Unknown dialogue gate function '%s'" % ast.name)
			return false
		resolved = fn.call(ast.args)
	else:
		var fields = ctx.get("fields", {})
		if not fields.has(ast.name):
			push_error("Unknown dialogue gate field '%s'" % ast.name)
			return false
		resolved = fields[ast.name].call()
	if String(ast.cmp).is_empty(): return bool(resolved)
	var value = ast.value
	if ast.cmp == "=" or ast.cmp == "!=":
		var left = str(resolved).to_lower()
		var right = str(value).to_lower()
		var equal = left == right or left.contains(right) or right.contains(left)
		return equal if ast.cmp == "=" else not equal
	var left_num = float(resolved) if (resolved is float or resolved is int) else (float(str(resolved)) if str(resolved).is_valid_float() else 0.0)
	var right_num = float(value) if str(value).is_valid_float() else 0.0
	match String(ast.cmp):
		"<": return left_num < right_num
		"<=": return left_num <= right_num
		">": return left_num > right_num
		">=": return left_num >= right_num
	return false
