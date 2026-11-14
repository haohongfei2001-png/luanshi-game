extends SceneTree
const Asset=preload("res://tools/representation_compare/control_asset.gd")
func _initialize():go.call_deferred()
func go():
 var stage=Node3D.new();root.add_child(stage);var asset=Asset.new();asset.prepare(stage,true);print("BOUNDS ",JSON.stringify(asset.clips));quit()
