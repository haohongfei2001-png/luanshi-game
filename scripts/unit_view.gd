extends Node3D
## Placeholder equipment assembled from engine primitives; no external assets.

var body: Node3D
var health_fill: MeshInstance3D
var helmet: MeshInstance3D
var weapon: Node3D
var ring: MeshInstance3D
var base_color: Color
var flesh_material: StandardMaterial3D
var cloth_material: StandardMaterial3D
var dead := false
var hero := false

func configure(unit: Dictionary) -> void:
	hero = unit.hero
	base_color = Color("d7b76b") if hero else (Color("428c8a") if unit.team == 0 else Color("b9563d"))
	body = Node3D.new()
	add_child(body)
	cloth_material = material(base_color)
	var leather := material(Color("3a3028"))
	var iron := material(Color("89897b"))
	var bronze := material(Color("aa8952"))
	flesh_material = material(Color("bc9773"))
	var tunic := CylinderMesh.new()
	tunic.top_radius = 0.31
	tunic.bottom_radius = 0.44
	tunic.height = 0.78
	tunic.radial_segments = 8
	add_mesh(body, tunic, cloth_material, Vector3(0, 0.78, 0))
	add_box(body, Vector3(0.61, 0.35, 0.35), leather, Vector3(0, 1.02, 0))
	for x in [-0.19, 0.19]:
		add_box(body, Vector3(0.22, 0.48, 0.25), leather, Vector3(x, 0.24, 0))
	var head := SphereMesh.new()
	head.radius = 0.24
	head.height = 0.48
	head.radial_segments = 8
	head.rings = 4
	add_mesh(body, head, flesh_material, Vector3(0, 1.39, 0))
	var cap := SphereMesh.new()
	cap.radius = 0.27
	cap.height = 0.3
	cap.radial_segments = 8
	cap.rings = 4
	helmet = add_mesh(body, cap, iron, Vector3(0, 1.56, 0))
	add_box(body, Vector3(0.13, 0.20, 0.13), leather, Vector3(0, 1.77, 0))
	add_box(body, Vector3(0.55, 0.08, 0.40), bronze, Vector3(0, 0.79, 0))
	# A rectangular wooden shield and plain iron spear, not fantasy armor.
	add_box(body, Vector3(0.15, 0.70, 0.52), bronze, Vector3(-0.48, 0.97, 0.12))
	weapon = Node3D.new()
	body.add_child(weapon)
	add_box(weapon, Vector3(0.065, 0.065, 2.15), leather, Vector3(0.48, 0.93, 0.57))
	add_box(weapon, Vector3(0.13, 0.08, 0.44), iron, Vector3(0.48, 0.93, 1.78))
	var health_back := add_box(self, Vector3(0.94, 0.08, 0.11), material(Color("252c29")), Vector3(0, 2.10, 0))
	health_back.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	health_fill = add_box(self, Vector3(0.9, 0.09, 0.12), material(base_color.lightened(0.22)), Vector3(0, 2.11, 0))
	health_fill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 0.53 if hero else 0.34
	ring_mesh.outer_radius = 0.64 if hero else 0.40
	ring_mesh.rings = 16
	ring_mesh.ring_segments = 6
	ring = add_mesh(self, ring_mesh, material(base_color), Vector3(0, 0.035, 0))
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if hero:
		body.scale = Vector3.ONE * 1.14

func update_state(unit: Dictionary, time: float) -> void:
	position = Vector3(unit.pos.x, 0, unit.pos.y)
	if unit.hp <= 0.0:
		if not dead:
			dead = true
			body.rotation.z = PI * 0.5
			body.position.y = 0.15
			cloth_material.albedo_color = base_color.darkened(0.55)
			health_fill.get_parent().get_child(1).visible = false
			health_fill.visible = false
			ring.visible = false
		return
	body.rotation.y = atan2(unit.facing.x, unit.facing.y)
	body.position.y = sin(time * 8.0 + unit.id) * 0.025
	weapon.rotation.y = sin(unit.swing * 17.0) * 0.7 if unit.swing > 0.0 else 0.0
	health_fill.scale.x = maxf(0.001, unit.hp / unit.max_hp)
	cloth_material.albedo_color = Color("f7e5b1") if unit.flash > 0.0 else base_color
	ring.scale = Vector3.ONE * (1.2 if unit.guard > 0.0 else 1.0)

static func material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.95
	return mat

static func add_box(parent: Node3D, dimensions: Vector3, mat: Material, pos: Vector3) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	return add_mesh(parent, mesh, mat, pos)

static func add_mesh(parent: Node3D, mesh: Mesh, mat: Material, pos: Vector3) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = mat
	node.position = pos
	parent.add_child(node)
	return node
