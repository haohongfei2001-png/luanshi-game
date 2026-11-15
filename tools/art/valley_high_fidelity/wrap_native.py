"""Deterministic author-world wrapper. Never runtime relighting or hidden exposure."""
import sys,json,hashlib
from pathlib import Path
out=Path(sys.argv[1]);prefix=sys.argv[2] if len(sys.argv)>2 else 'res://assets/production_v2/valley_hf01'
m=json.loads((out/'mother-manifest.json').read_text());w=json.loads((out/'author-world.json').read_text())
def val(v):
 if isinstance(v,str):return json.dumps(v)
 if isinstance(v,bool):return 'true' if v else 'false'
 return str(v)
def color(v):return 'Color('+', '.join(map(str,v))+', 1)'
lines=['[gd_scene load_steps=3 format=3]','',f'[ext_resource type="PackedScene" path="{prefix}/river-valley-hf01.glb" id="1_visual"]','','[sub_resource type="Environment" id="Environment_AuthorDaylight"]','background_mode = 1','background_color = '+color(w['background_color']),'ambient_light_source = 2','ambient_light_color = '+color(w['ambient_light_color']),'ambient_light_energy = '+str(w['ambient_light_energy']),'tonemap_mode = 2','ssao_enabled = '+val(w['ssao_enabled']),'ssao_radius = '+str(w['ssao_radius']),'ssao_intensity = '+str(w['ssao_intensity']),'ssil_enabled = false','fog_enabled = false','','[node name="RiverValleyHF01_CompleteMother" type="Node3D"]']
for key in ['map_id','topology_revision','topology_sha256','visual_revision','authored_source_sha256']:lines.append('metadata/'+key+' = '+val(m[key]))
lines+=['','[node name="AuthoredVisual" parent="." instance=ExtResource("1_visual")]','','[node name="AuthoredWorldEnvironment" type="WorldEnvironment" parent="."]','environment = SubResource("Environment_AuthorDaylight")','']
(out/'mother.tscn').write_text('\n'.join(lines));manifest={'status':'AUTHOR_WRAPPER_NOT_RUNTIME_ACCEPTED','scene':{'path':prefix+'/mother.tscn','sha256':hashlib.sha256((out/'mother.tscn').read_bytes()).hexdigest()},'navigation':{'path':prefix+'/mother-manifest.json','sha256':hashlib.sha256((out/'mother-manifest.json').read_bytes()).hexdigest()},'identity':{k:m[k] for k in ['map_id','topology_revision','topology_sha256','visual_revision','authored_source_sha256']},'world_source_sha256':hashlib.sha256((out/'author-world.json').read_bytes()).hexdigest(),'scope':'Author-supplied wrapper carries exact original native world. Sun exists only inside GLB. Native import closure remains to be measured.'}
(out/'native-handoff.json').write_text(json.dumps(manifest,indent=2));print(json.dumps(manifest,indent=2))
