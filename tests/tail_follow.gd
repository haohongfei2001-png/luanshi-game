extends "res://tests/rc7_personal_contact.gd"
## Photograph the renderer at the end of each ordinary frame; the existing
## shipping-input driver still owns all button presses and all simulation time.
const OUT := "res://artifacts/foot-load/follow"
var movie_frame:=0
var trajectory: Array=[]

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	RenderingServer.frame_post_draw.connect(_capture)
	super._initialize()

func _capture() -> void:
	if not is_instance_valid(field) or not is_instance_valid(field.camera): return
	var b:=field.battle
	if not b.started or not field.follow: return
	var img:=root.get_texture().get_image()
	img.save_jpg("%s/%03d.jpg"%[OUT,movie_frame],.92)
	var row:=[b.tick,b.hero.id,b.hero.state,b.hero.kit,b.hero.pos.x,b.hero.pos.y,b.hero.hp,b.hero.impacts,
		b.hits[0],b.hits[1],b.losses[0],b.losses[1],field.camera.size,field.follow]
	if movie_frame in [0,15,36,54] or b.hero.impacts>0:
		img.save_png("%s/snapshot-%03d.png"%[OUT,movie_frame])
		print("LOAD_FOLLOW ",movie_frame," ",JSON.stringify(row))
	trajectory.append(row)
	movie_frame+=1
	if b.hero.impacts>0:
		FileAccess.open(OUT+"/trajectory.json",FileAccess.WRITE).store_string(JSON.stringify(trajectory))
