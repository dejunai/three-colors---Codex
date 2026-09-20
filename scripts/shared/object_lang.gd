extends RefCounted

# Flat-file OBJECT grammar and its GATE-expression evaluator. A deliberate
# sibling of dialogue_lang.gd, not a subclass of it: world objects are not
# NPCs, so this grammar drops NPC/SCHEDULE/WEIGHT/VOICE and adds TAKE for
# carryable items. The GATE mini-language is intentionally identical to
# dialogue_lang.gd's so one authoring skill covers both formats. Pure text
# in, structured data out — no engine/game references, so this file is
# testable in isolation (see tests/object_lang_flow.gd) and is the only
# place that needs to change if the object grammar itself grows.
#
# FILE SHAPE
#   LOCATION: estate
#   INCLUDE: shared_object_rebuffs.object      (repeatable; optional)
#
#   OBJECT: knife
#     GATE: <expression>          ("never" / "always" / a boolean expression)
#     LABEL: "Recover the knife"  (optional; otherwise object_id.capitalize())
#     TAG: estate_knife_take      (optional; extra completion/timing key)
#     TIME: 5                     (optional; minutes charged once per id/TAG)
#     [A good boning knife, wiped too carefully.]
#     EVIDENCE: clean_knife
#     NOTEBOOK: clean_knife_note | "The knife beneath the hedge was wiped clean."
#     TAKE: clean_knife            (adds to case_state inventory)
#
# Unlike TOPIC ids in dialogue, OBJECT ids are expected to repeat: every
# object interaction is a self-contained encounter (there is no NPC-style
# topic menu to keep unique), so authoring "the same hotspot, several
# states" is normal. Multiple `OBJECT: knife` blocks may exist with
# different GATEs; the first block whose GATE is currently true wins,
# exactly like dialogue's `TOPIC: default` cascade — write the most
# specific/gated state first and the fallback last.
#
# GATE GRAMMAR: identical to dialogue_lang.gd — "never" | "always" | <expr>
#   expr       := or_expr
#   or_expr    := and_expr (OR and_expr)*
#   and_expr   := unary (AND unary)*
#   unary      := NOT unary | atom
#   atom       := "(" expr ")" | comparison
#   comparison := NAME ["(" arg ("," arg)* ")"] [cmp value]
#   cmp        := "<" | "<=" | ">" | ">=" | "=" | "!="
# `=`/`!=` compare case-insensitively via substring containment; `<`/`<=`/
# `>`/`>=` compare numerically. Built-in functions/fields are registered by
# the caller via the `ctx` passed to evaluate() — see object_runtime.gd's
# make_context() for the actual vocabulary (object_done, object_count,
# examine_count, taken, evidence, filed, flag, outcome, outcome_is, coat,
# day, phase, estate_complete, steward_ready).
#
# STEPS: beats `[...]`, `SPEAKER: "..."` lines, linear `CHOICE:` (always
# labelled WALTER CORWIN, matching dialogue), `FORK:`/nested `CHOICE:`,
# `NOTEBOOK: id | "..."`, `EVIDENCE: id`, `OUTCOME: decision_id = value_id`
# (only inside a FORK choice), and `TAKE: item_id`. There is no VOICE —
# examined objects are Walter's own narration and stay unvoiced, same as
# dialogue's beats/notebook/system cards.

static func parse(text: String) -> Dictionary:
	var logical = _logical_lines(text)
	var i = 0
	var location = ""
	var includes: Array = []
	var errors: Array = []
	while i < logical.size() and logical[i].indent == 0 and not logical[i].text.begins_with("OBJECT:"):
		var entry = logical[i]
		var colon = entry.text.find(":")
		if colon == -1:
			errors.append({"line": entry.line, "message": "Malformed header line '%s'" % entry.text})
			i += 1
			continue
		var key = entry.text.substr(0, colon).strip_edges().to_upper()
		var value = entry.text.substr(colon + 1).strip_edges()
		match key:
			"LOCATION":
				location = value
				# The cookbook's {generated} placeholder is deliberately not a real
				# identifier — braces mark it for a human to replace, same convention
				# as dialogue's NPC header; skip validation only for that shape.
				if not location.is_empty() and not location.contains("{") and not location.is_valid_identifier():
					errors.append({"line": entry.line, "message": "LOCATION must be a simple lowercase_snake_case identifier"})
			"INCLUDE": includes.append(value)
			_: errors.append({"line": entry.line, "message": "Unknown header '%s'" % key})
		i += 1
	var objects: Array = []
	while i < logical.size():
		var entry = logical[i]
		if entry.indent != 0 or not entry.text.begins_with("OBJECT:"):
			errors.append({"line": entry.line, "message": "Expected an OBJECT block, found '%s'" % entry.text})
			i += 1
			continue
		var object_id = entry.text.substr(7).strip_edges()
		if not object_id.is_valid_identifier():
			errors.append({"line": entry.line, "message": "OBJECT id must be a simple lowercase_snake_case identifier"})
		var j = i + 1
		var body: Array = []
		while j < logical.size() and logical[j].indent > 0:
			body.append(logical[j])
			j += 1
		var parsed = _parse_object_body(body, errors)
		parsed["id"] = object_id
		parsed["line"] = entry.line
		objects.append(parsed)
		i = j
	return {"location": location, "includes": includes, "objects": objects, "errors": errors}

static func evaluate(ast: Dictionary, ctx: Dictionary) -> bool:
	match String(ast.get("op", "")):
		"lit": return bool(ast.value)
		"and": return evaluate(ast.left, ctx) and evaluate(ast.right, ctx)
		"or": return evaluate(ast.left, ctx) or evaluate(ast.right, ctx)
		"not": return not evaluate(ast.expr, ctx)
		"cmp": return _evaluate_cmp(ast, ctx)
		_: return false

# ---- content parsing ----

static func _parse_object_body(body: Array, errors: Array) -> Dictionary:
	if body.is_empty():
		return {"gate_src": "never", "gate": {"op": "lit", "value": false}, "label": "", "tag": "", "timing": "", "outcome_keys": [], "steps": []}
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
			if not tag.is_empty() and not tag.is_valid_identifier():
				errors.append({"line": body[k].line, "message": "TAG must be a simple identifier"})
			k += 1
		elif text.begins_with("TIME:"):
			var raw_time = text.substr(5).strip_edges()
			if not raw_time.is_empty() and (not raw_time.is_valid_float() or float(raw_time) < 0.0 or not is_finite(float(raw_time))):
				errors.append({"line": body[k].line, "message": "TIME must be a finite number greater than or equal to zero"})
			timing = raw_time
			k += 1
		elif text.begins_with("LABEL:"):
			label = _quoted(text.substr(6))
			k += 1
		else:
			break
	var steps = _parse_steps(body, k, body.size(), base_indent, errors)
	return {"gate_src": gate_src, "gate": _parse_gate(gate_src), "label": label, "tag": tag, "timing": timing,
		"outcome_keys": _collect_outcome_keys(steps), "steps": steps}

static func _parse_steps(body: Array, start: int, end: int, indent: int, errors: Array, allow_outcome: bool = false) -> Array:
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
			var evidence_id = line.substr(9).strip_edges()
			if not evidence_id.is_valid_identifier():
				errors.append({"line": entry.line, "message": "EVIDENCE must name a simple identifier"})
			else:
				steps.append({"kind": "evidence", "id": evidence_id})
			k += 1
		elif line.begins_with("TAKE:"):
			var item_id = line.substr(5).strip_edges()
			if not item_id.is_valid_identifier():
				errors.append({"line": entry.line, "message": "TAKE must name a simple item id"})
			else:
				steps.append({"kind": "take", "id": item_id})
			k += 1
		elif line.begins_with("OUTCOME:"):
			var assignment = line.substr(8).strip_edges().split("=", true, 1)
			if not allow_outcome:
				errors.append({"line": entry.line, "message": "OUTCOME is only valid inside a FORK choice"})
			elif assignment.size() != 2 or not assignment[0].strip_edges().is_valid_identifier() or not assignment[1].strip_edges().is_valid_identifier():
				errors.append({"line": entry.line, "message": "OUTCOME must use 'decision_id = value_id' with simple identifiers"})
			else:
				steps.append({"kind": "outcome", "id": assignment[0].strip_edges(), "value": assignment[1].strip_edges()})
			k += 1
		elif line.begins_with("NOTEBOOK:"):
			var payload = line.substr(9).strip_edges()
			var note_id = ""
			if not payload.begins_with("\"") and payload.contains("|"):
				var separator = payload.find("|")
				note_id = payload.substr(0, separator).strip_edges()
				payload = payload.substr(separator + 1).strip_edges()
			if not note_id.is_empty() and not note_id.is_valid_identifier():
				errors.append({"line": entry.line, "message": "NOTEBOOK id must be a simple identifier"})
			else:
				steps.append({"kind": "notebook", "id": note_id, "text": _quoted(payload)})
			k += 1
		elif line.begins_with("CHOICE:"):
			var label = _quoted(line.substr(7))
			var child_indent = _peek_indent(body, k + 1, end)
			var child_end = _block_end(body, k + 1, end, child_indent) if child_indent > indent else k + 1
			steps.append({"kind": "line", "speaker": "WALTER CORWIN", "text": label, "player": true})
			if child_indent > indent:
				steps.append_array(_parse_steps(body, k + 1, child_end, child_indent, errors, allow_outcome))
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

static func _collect_outcome_keys(steps: Array) -> Array[String]:
	var keys: Array[String] = []
	for step in steps:
		if String(step.get("kind", "")) == "outcome":
			var key = String(step.get("id", ""))
			if not keys.has(key): keys.append(key)
		elif String(step.get("kind", "")) == "fork":
			for option in step.get("options", []):
				for key in _collect_outcome_keys(option.get("steps", [])):
					if not keys.has(key): keys.append(key)
	return keys

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
			steps.append_array(_parse_steps(body, k + 1, child_end, child_indent, errors, true))
		# Tag/timing live on the object (session-level), not per fork option —
		# every branch of one FORK still belongs to the same object/session.
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
	return trimmed.replace("\\\"", "\"").replace("\\n", "\n")

static func _strip_brackets(s: String) -> String:
	var trimmed = s.strip_edges()
	if trimmed.begins_with("[") and trimmed.ends_with("]"):
		trimmed = trimmed.substr(1, trimmed.length() - 2)
	return trimmed.strip_edges()

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
	var name = String(ast.name)
	var result
	if bool(ast.call):
		var fn = ctx.get("functions", {}).get(name)
		if not (fn is Callable and fn.is_valid()):
			push_error("Unknown object gate function '%s'" % name)
			return false
		result = fn.call(ast.args)
	else:
		var fields = ctx.get("fields", {})
		if not fields.has(name):
			push_error("Unknown object gate field '%s'" % name)
			return false
		var field = fields.get(name)
		result = field.call() if field is Callable and field.is_valid() else false
	if String(ast.cmp).is_empty(): return bool(result)
	var expected = str(ast.value) if ast.value != null else ""
	var res_str = str(result) if result != null else ""
	match String(ast.cmp):
		"=":
			if expected.is_empty() and res_str.is_empty(): return true
			if (result is int or result is float or res_str.is_valid_float()) and expected.is_valid_float():
				return is_equal_approx(float(result), float(expected))
			return res_str.to_lower().contains(expected.to_lower()) or expected.to_lower().contains(res_str.to_lower())
		"!=":
			if expected.is_empty(): return not res_str.is_empty()
			if (result is int or result is float or res_str.is_valid_float()) and expected.is_valid_float():
				return not is_equal_approx(float(result), float(expected))
			return not (res_str.to_lower().contains(expected.to_lower()) or expected.to_lower().contains(res_str.to_lower()))
		"<": return float(res_str) < float(expected) if expected.is_valid_float() else false
		"<=": return float(res_str) <= float(expected) if expected.is_valid_float() else false
		">": return float(res_str) > float(expected) if expected.is_valid_float() else false
		">=": return float(res_str) >= float(expected) if expected.is_valid_float() else false
		_: return false
