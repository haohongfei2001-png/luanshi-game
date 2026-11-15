extends "res://scripts/field/maps/experimental_native_navigation.gd"
## A separate third constructor: support batching plus optional body-loop kernel.
## Portal admission, sample order, slope, and segment-shot checks stay unchanged.
const NativeObstacles:=preload("res://scripts/field/maps/experimental_native_obstacles.gd")
func _init():
 super()
 obstacles=NativeObstacles.new()
