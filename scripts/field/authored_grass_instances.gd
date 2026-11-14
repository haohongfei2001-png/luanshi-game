extends MultiMeshInstance3D
## Transform data is explicitly serialized on CPU. Dummy/headless RenderingServer
## does not preserve MultiMesh.set_instance_transform data for packed scenes.
@export var authored_mesh:Mesh
@export var authored_transforms:Array[Transform3D]=[]
func _ready() -> void:
	assert(authored_mesh and not authored_transforms.is_empty())
	var batch:=MultiMesh.new();batch.transform_format=MultiMesh.TRANSFORM_3D
	batch.mesh=authored_mesh;batch.instance_count=authored_transforms.size()
	for i in authored_transforms.size():batch.set_instance_transform(i,authored_transforms[i])
	multimesh=batch
