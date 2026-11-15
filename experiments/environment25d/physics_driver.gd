extends Node
var experiment
func _physics_process(delta:float)->void:
 if experiment!=null:experiment.physics_tick(delta)
func _unhandled_input(event:InputEvent)->void:
 if experiment!=null:experiment.handle_input(event)
