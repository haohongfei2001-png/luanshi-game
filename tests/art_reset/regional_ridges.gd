extends SceneTree
const Ridge:=preload("res://scripts/field/authored_ridge_profile.gd")
func _initialize() -> void:
	var samples:=0;var max_step:=0.;var max_height:=0.
	for z in range(-112,113):
		for x in range(-144,161):
			var p:=Vector2(x,z);var h:=Ridge.height(p)
			assert(is_finite(h) and h>=0. and h<=26.)
			max_height=maxf(max_height,h)
			max_step=maxf(max_step,absf(h-Ridge.height(p+Vector2(.01,0))))
			if absf(p.y)<=28. or p.x<=6.:assert(Ridge.weight(p)==0.)
			samples+=1
	# No seams at authored station joins; the previous cone chain is not used.
	for rows:Array in [Ridge.NORTH,Ridge.SOUTH]:
		for s:Vector4 in rows:
			assert(absf(Ridge.profile(Vector2(s.x-.0001,s.y),rows)-Ridge.profile(Vector2(s.x+.0001,s.y),rows))<.001)
	assert(max_step<.03 and max_height>20.)
	print("CONNECTED_RIDGE_PROFILE_PASS samples=",samples," max_height=",max_height," max_dx_1cm=",max_step," standalone_not_integrated=true art=NOT_RUN")
	quit()
