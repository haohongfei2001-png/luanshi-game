extends Control
## Static surveyed terrain, current viewpoint and the player's own position.
## Remote companies never broadcast their whereabouts through the map.
const Ground := preload("res://scripts/field/ground.gd")
const SURVEY := preload("res://assets/environment/river-survey.svg")
signal chosen(at: Vector2)
var observer:=Vector2.ZERO
var player:=Vector2.ZERO
var heading:=Vector2.RIGHT
var half_view:=Vector2(19,15)
var view_yaw:=0.0
var first:=true
var mustering:=PackedVector2Array()
var selected:=Vector2.INF

func set_muster(b: RefCounted,index: int) -> void:
	mustering.clear()
	selected=Vector2.INF
	if not b.started:
		for i in b.companies_per_side: mustering.append(b.companies[i].home)
		if index>=0 and index<mustering.size(): selected=mustering[index]
	queue_redraw()

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	tooltip_text="点击地形观察；C 返回主角"

func locate(center: Vector2,hero: Vector2,face: Vector2,extent: Vector2,yaw: float=0.) -> void:
	if not first and center.distance_squared_to(observer)<0.04 and hero.distance_squared_to(player)<0.04 and heading.dot(face)>0.995 and half_view.is_equal_approx(extent) and absf(angle_difference(view_yaw,yaw))<.001: return
	first=false
	observer=center
	player=hero
	heading=face
	half_view=extent
	view_yaw=yaw
	queue_redraw()

func _point(p: Vector2) -> Vector2:
	return Vector2(7,6)+(p/Ground.LIMIT+Vector2.ONE)*0.5*(size-Vector2(14,12))

func _draw() -> void:
	var area:=Rect2(Vector2(7,6),size-Vector2(14,12))
	draw_rect(Rect2(Vector2.ZERO,size),Color("24312eeb"))
	draw_texture_rect(SURVEY,area,false)
	draw_rect(Rect2(Vector2(.5,.5),size-Vector2.ONE),Color("92876d"),false,1.)
	var gate:=_point(Ground.GATE)
	draw_colored_polygon(PackedVector2Array([gate+Vector2(-2.8,0),gate+Vector2(0,-2.8),
		gate+Vector2(2.8,0),gate+Vector2(0,2.8)]),Color("ebbc7a"))
	var across:=Vector2(cos(view_yaw),-sin(view_yaw))*half_view.x
	var along:=Vector2(sin(view_yaw),cos(view_yaw))*half_view.y
	var sight:=PackedVector2Array()
	for delta:Vector2 in [-across-along,across-along,across+along,-across+along,-across-along]:
		sight.append(_point(observer+delta))
	# A panned view can reach beyond the surveyed sheet. Clip its four edges
	# independently so an out-of-bounds corner does not create a false diagonal.
	var border:=PackedVector2Array([area.position,Vector2(area.end.x,area.position.y),
		area.end,Vector2(area.position.x,area.end.y)])
	for path:PackedVector2Array in Geometry2D.intersect_polyline_with_polygon(sight,border):
		if path.size()>1: draw_polyline(path,Color("bfd1bd"),1.,true)
	for at in mustering: draw_circle(_point(at),1.6,Color("9fc6bd"))
	if selected.is_finite(): draw_arc(_point(selected),4,0,TAU,12,Color("ffe297"),1.6,true)
	var p:=_point(player)
	draw_circle(p,2.8,Color("ffe6a0"))
	draw_line(p,p+heading*6,Color("ffedc2"),1.4,true)

func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index==MOUSE_BUTTON_LEFT and e.pressed:
		var norm: Vector2=(e.position-Vector2(7,6))/(size-Vector2(14,12))
		chosen.emit(((norm*2.0-Vector2.ONE)*Ground.LIMIT).clamp(-Ground.LIMIT,Ground.LIMIT))
		accept_event()
