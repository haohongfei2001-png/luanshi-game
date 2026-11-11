extends Control
## Static surveyed terrain, current viewpoint and the player's own position.
## Remote companies never broadcast their whereabouts through the map.
const Ground := preload("res://scripts/field/ground.gd")
signal chosen(at: Vector2)
var observer:=Vector2.ZERO
var player:=Vector2.ZERO
var heading:=Vector2.RIGHT
var half_view:=Vector2(19,15)
var first:=true

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	tooltip_text="点击地形观察；C 返回主角"

func locate(center: Vector2,hero: Vector2,face: Vector2,extent: Vector2) -> void:
	if not first and center.distance_squared_to(observer)<0.04 and hero.distance_squared_to(player)<0.04 and heading.dot(face)>0.995 and half_view.is_equal_approx(extent): return
	first=false
	observer=center
	player=hero
	heading=face
	half_view=extent
	queue_redraw()

func _point(p: Vector2) -> Vector2:
	return Vector2(7,6)+(p/Ground.LIMIT+Vector2.ONE)*0.5*(size-Vector2(14,12))

func _rect(a: Vector2,b: Vector2) -> Rect2:
	return Rect2(_point(a),_point(b)-_point(a)).abs()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("263c37ee"))
	draw_rect(Rect2(Vector2.ZERO,size),Color("9c976f"),false,1)
	var clay:=Color("a29a6f")
	draw_rect(_rect(Vector2(Ground.RIVER_X-4.8,-64),Vector2(Ground.RIVER_X+4.8,64)),Color("638b88"))
	for lane: float in Ground.CROSSINGS:
		var route:=PackedVector2Array([_point(Vector2(-98,lane*0.57)),_point(Vector2(Ground.RIVER_X-7,lane)),_point(Vector2(Ground.RIVER_X+7,lane)),_point(Vector2(25,lane*0.77)),_point(Ground.GATE)])
		draw_polyline(route,Color("857b5d"),1,true)
		draw_line(_point(Vector2(Ground.RIVER_X-5.5,lane)),_point(Vector2(Ground.RIVER_X+5.5,lane)),clay,2)
	draw_circle(_point(Ground.GROVE),8,Color("607252"))
	draw_arc(_point(Ground.RIDGE),7,PI,TAU,12,clay,1,true)
	draw_rect(_rect(Vector2(-94,-15),Vector2(-75,15)),clay,false,1)
	draw_rect(_rect(Vector2(Ground.WALL_X,-Ground.WALL_Z),Vector2(Ground.BACK_X,Ground.WALL_Z)),Color("c9b995"),false,1)
	draw_circle(_point(Ground.GATE),2.5,Color("ebbe7b"))
	var bounds:=_rect(observer-half_view,observer+half_view).intersection(Rect2(Vector2(2,2),size-Vector2(4,4)))
	if bounds.has_area(): draw_rect(bounds,Color("a8c5b3"),false,1)
	var p:=_point(player)
	draw_circle(p,2.8,Color("ffe6a0"))
	draw_line(p,p+heading*6,Color("ffedc2"),1.4,true)

func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index==MOUSE_BUTTON_LEFT and e.pressed:
		var norm: Vector2=(e.position-Vector2(7,6))/(size-Vector2(14,12))
		chosen.emit(((norm*2.0-Vector2.ONE)*Ground.LIMIT).clamp(-Ground.LIMIT,Ground.LIMIT))
		accept_event()
