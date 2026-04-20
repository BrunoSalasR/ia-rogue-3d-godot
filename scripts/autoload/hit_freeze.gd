extends Node
## HitFreeze — Autoload singleton.
## Pauses game for a few frames on impactful hits.
## This single mechanic is responsible for ~60% of the "game feel" in
## Hades, HLD, and similar action games. Without it, combat feels floaty.
##
## Usage:
##   HitFreeze.trigger()          # standard hit (0.05s)
##   HitFreeze.trigger(0.08)      # heavy hit (boss, overkill)
##   HitFreeze.trigger(0.03)      # light hit (graze, small enemy)

signal freeze_ended

# Internal
var _active:   bool  = false
var _duration: float = 0.0

# ── Public API ────────────────────────────────────────────────────────────────

func trigger(duration: float = 0.05) -> void:
	## Freeze the game for `duration` real-time seconds.
	## Stacks with existing freeze (takes the longer value).
	if _active:
		_duration = max(_duration, duration)
		return
	_active   = true
	_duration = duration
	Engine.time_scale = 0.0
	# Use a timer that ignores time_scale to unfreeze
	await get_tree().create_timer(duration, true, false, true).timeout
	_end_freeze()

# ── Internal ──────────────────────────────────────────────────────────────────

func _end_freeze() -> void:
	Engine.time_scale = 1.0
	_active           = false
	_duration         = 0.0
	freeze_ended.emit()
