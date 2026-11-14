extends SceneTree
const Ground=preload('res://scripts/field/ground.gd')
func _init() -> void:
 var points=[]
 for ix in range(98):
  for iz in range(105):
   var p:=Vector2(44.+ix*.5,-26.+iz*.5)
   points.append({'x':p.x,'z':p.y,'walk_height':Ground.parapet(p),'blocked_open':Ground.blocked(p,true),'blocked_closed':Ground.blocked(p,false)})
 # Explicit ramp boundaries and retreat lane, in addition to the broad grid.
 for x in [49.4,49.5,50.5,52.5,52.6]:
  for sign in [-1.,1.]:
   for i in range(164):
    var p:=Vector2(x,sign*(5.5+i*.1))
    points.append({'x':p.x,'z':p.y,'walk_height':Ground.parapet(p),'blocked_open':Ground.blocked(p,true),'blocked_closed':Ground.blocked(p,false)})
 var args:=OS.get_cmdline_user_args()
 if args.is_empty():push_error('Output path required');quit(1);return
 var f:=FileAccess.open(args[0],FileAccess.WRITE)
 if f==null:push_error('Cannot save real Ground samples');quit(1);return
 f.store_string(JSON.stringify({'source':'actual current Ground.parapet/blocked functions, not a new simplified collision function','wall_x':Ground.WALL_X,'back_x':Ground.BACK_X,'wall_z':Ground.WALL_Z,'front_gate_half':Ground.GATE_HALF,'postern_half':Ground.POSTERN_HALF,'points':points}));f.close()
 print('FORT_ACTUAL_GROUND_SAMPLES ',points.size());quit()
