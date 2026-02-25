extends Object
class_name StopWatch

func print_time() -> void:
	var datetime = Time.get_datetime_dict_from_system()
	var time = Time.get_datetime_string_from_datetime_dict(datetime,false)

var ticks_msec_dict: Dictionary = {}
func measure_msecs(timer_name: String):
	if ticks_msec_dict.has(timer_name):
		var ticks_msec: Array = ticks_msec_dict[timer_name]
		ticks_msec.append(Time.get_ticks_msec())
		print_rich("[bgcolor=black][color=green][b]%s[/b][/color][/bgcolor]" % timer_name)
		print_rich("[bgcolor=black][color=green]start@: [b]%s[/b]msec\nstop@: [b]%s[/b]msec[/color][/bgcolor]" % ticks_msec)
		print_rich("[bgcolor=black][color=green]msec:    [b]%s[/b][/color][/bgcolor]" % (ticks_msec[1]-ticks_msec[0]))
		print_rich("[bgcolor=black][color=green]seconds: [b]%s[/b][/color][/bgcolor]" % ((ticks_msec[1]-ticks_msec[0]) / 1000.0))
		print_rich("[bgcolor=black][color=green]frames:  [b]%s[/b][/color][/bgcolor]" % msec_to_frames(ticks_msec[1]-ticks_msec[0]))
		ticks_msec_dict.erase(timer_name)
	else:
		var timer_msec: Array = []
		timer_msec.append(Time.get_ticks_msec())
		ticks_msec_dict[timer_name] = timer_msec
		
func msec_to_frames(ms: float, fps: float = 60.0) -> float:
	return ms * fps / 1000.0
