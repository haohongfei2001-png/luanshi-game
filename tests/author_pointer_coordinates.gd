extends SceneTree
## Real native Input routing through stretched root; no Battle writes/GPU claim.
const Harness=preload("res://scripts/review/author_dynamic_review.gd")
func _initialize()->void:run.call_deferred()
func run()->void:
 root.size=Vector2i(2560,1440)
 await process_frame;await process_frame
 var logical=Vector2(600,500)
 var event=InputEventMouseMotion.new();event.position=logical;event.global_position=logical
 Input.parse_input_event(event);Input.flush_buffered_events()
 assert(root.get_mouse_position().distance_to(logical)>10.,"Fixture must exercise nonidentity stretch")
 var position=Harness.native_pointer_coordinates(root,logical)
 event=InputEventMouseMotion.new();event.position=position;event.global_position=position
 Input.parse_input_event(event);Input.flush_buffered_events()
 assert(root.get_mouse_position().distance_to(logical)<0.001)
 print("AUTHOR_NATIVE_POINTER_ROUNDTRIP_PASS logical=",logical," event=",position," actual=",root.get_mouse_position(),"; GPU/actor NOT_RUN")
 quit()
