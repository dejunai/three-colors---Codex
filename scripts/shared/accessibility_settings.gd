extends RefCounted

const VERSION=1
const DEFAULTS={"grain":0.018,"distortion":0.25,"contrast":1.0,"text_scale":1.0,"sensitivity":0.0026,"camera_speed":1.0,"instrument_voice_volume":0.45,"reduced_flicker":true,"hints":true,"invert_y":false}
const RANGES={"grain":[0.0,0.06],"distortion":[0.0,1.0],"contrast":[0.8,1.4],"text_scale":[0.9,1.3],"sensitivity":[0.001,0.006],"camera_speed":[0.2,3.0],"instrument_voice_volume":[0.0,1.0]}

func decode(payload:Dictionary) -> Dictionary:
	var values=DEFAULTS.duplicate(true)
	var source=payload.get("values",payload)
	if payload.has("version") and int(payload.version)!=VERSION: return values
	if not source is Dictionary: return values
	for key in values:
		if not source.has(key): continue
		if RANGES.has(key):
			if (source[key] is float or source[key] is int) and is_finite(float(source[key])):
				values[key]=clampf(float(source[key]),RANGES[key][0],RANGES[key][1])
		elif source[key] is bool: values[key]=source[key]
	return values

func encode(values:Dictionary) -> Dictionary:
	return {"version":VERSION,"values":decode(values)}
