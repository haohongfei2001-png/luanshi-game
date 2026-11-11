extends Node2D
## A small ground bracket, facing tip and brief contact marks survive roof occlusion.
var foot:=Vector2.ZERO
var heading:=Vector2.UP
var width:=10.0
var contact:=0.0
var hurt:=0.0

func project(at: Vector2,dir: Vector2,radius: float,hit: float,hit_back: float) -> void:
	foot=at
	heading=dir.normalized()
	width=clampf(radius,6,28)
	contact=hit
	hurt=hit_back
	queue_redraw()

func _draw() -> void:
	var color:=Color("f4d182")
	color.a=0.87
	if hurt>0: color=color.lerp(Color("e98969"),hurt)
	for sign_x: float in [-1,1]:
		var a:=foot+Vector2(sign_x*width,-1)
		var points:=PackedVector2Array([a+Vector2(-sign_x*width*0.22,-2),a,a+Vector2(-sign_x*width*0.25,3)])
		draw_polyline(points,Color("383b32a8"),3.2,true)
		draw_polyline(points,color,1.4,true)
	var tip:=foot+heading*(width+4)
	draw_line(tip-heading*3,tip,color,1.6,true)
	if contact>0:
		var crosshair:=foot+heading*(width+11)
		for i in 4:
			var d:=Vector2.ONE.normalized().rotated(i*PI/2)
			draw_line(crosshair+d*2,crosshair+d*(3.5+2*contact),Color(1,0.90,0.63,contact),1.6,true)
