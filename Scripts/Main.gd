extends Node

func tick():
	return float(Time.get_ticks_msec())/1000

func time_since(timestamp):
	return tick()-timestamp

var current_player : Player
