"""UAL -> complete MH163 rest-relative body-motion prototype; no game hookup.
Blender 4.3+: blender -b --disable-autoexec --python-exit-code 1 --python
retarget.py -- OUTPUT_DIR UAL1_Standard.glb [MASTER.blend]
Full source weights are retained. >8 influences remain an explicit Godot limit.
"""
import bpy
import hashlib
import json
import math
import pathlib
import struct
import sys
from mathutils import Matrix, Quaternion, Vector

CLIPS = ('Idle_Loop', 'Walk_Loop', 'Jog_Fwd_Loop', 'Sprint_Loop',
         'Hit_Chest', 'Hit_Head', 'Death01', 'Sword_Idle', 'Sword_Attack')
FPS = 120
SAMPLE_HZ = 30


def bone_mapping():
    result = {'root': 'pelvis', 'spine05': 'spine_01', 'spine04': 'spine_01',
              'spine03': 'spine_02', 'spine02': 'spine_02', 'spine01': 'spine_03',
              'neck01': 'neck_01', 'neck02': 'neck_01', 'neck03': 'neck_01',
              'head': 'Head'}
    for side, suffix in [('L', 'l'), ('R', 'r')]:
        for target, source in [('clavicle', 'clavicle'), ('shoulder01', 'clavicle'),
                               ('upperarm01', 'upperarm'), ('upperarm02', 'upperarm'),
                               ('lowerarm01', 'lowerarm'), ('lowerarm02', 'lowerarm'),
                               ('wrist', 'hand'), ('upperleg01', 'thigh'),
                               ('upperleg02', 'thigh'), ('lowerleg01', 'calf'),
                               ('lowerleg02', 'calf'), ('foot', 'foot')]:
            result[target + '.' + side] = source + '_' + suffix
        for number, source in enumerate(('thumb', 'index', 'middle', 'ring', 'pinky'), 1):
            for segment in range(1, 4):
                result[f'finger{number}-{segment}.{side}'] = f'{source}_{segment:02d}_{suffix}'
        # Map only the first toe joints to the shared source ball. Other toe segments
        # keep their native local rest, rather than inventing independent toe motion.
        for number in range(1, 6):
            result[f'toe{number}-1.{side}'] = f'ball_{suffix}'
    return result


def glb_clip_lengths(path):
    raw = path.read_bytes()
    length = struct.unpack_from('<I', raw, 12)[0]
    doc = json.loads(raw[20:20 + length])
    return {a['name']: max(doc['accessors'][s['input']]['max'][0]
                           for s in a['samplers']) for a in doc['animations']}


def ordered_bones(armature):
    result = []
    def visit(bone):
        result.append(bone)
        for child in bone.children:
            visit(child)
    for bone in armature.data.bones:
        if bone.parent is None:
            visit(bone)
    return result


def source_action(name, before):
    matches = [a for a in bpy.data.actions if a not in before and
               (a.name == name or a.name.startswith(name + '_'))]
    if len(matches) != 1:
        raise ValueError(f'Expected one imported source action {name}, got {[a.name for a in matches]}')
    return matches[0]


def matrices_signature(armature):
    return {b.name: {'parent': b.parent.name if b.parent else None,
                     'rest': [float(x) for row in b.matrix_local for x in row],
                     'length': float(b.length)} for b in armature.data.bones}


def geometry_signature(objects):
    """Ensure retarget changes animation only, not author meshes/UV/weights."""
    digest = hashlib.sha256()
    for obj in sorted(objects, key=lambda o: o.name):
        if obj.type != 'MESH':
            continue
        digest.update(obj.name.encode())
        for v in obj.data.vertices:
            digest.update(struct.pack('<3f', *v.co))
            for g in v.groups:
                digest.update(struct.pack('<If', g.group, g.weight))
        for poly in obj.data.polygons:
            digest.update(struct.pack('<' + 'I' * len(poly.vertices), *poly.vertices))
        for layer in obj.data.uv_layers:
            for item in layer.data:
                digest.update(struct.pack('<2f', *item.uv))
    return digest.hexdigest()


def reference_orientations(target, source, mapping):
    sq = source.matrix_world.to_quaternion()
    tq = target.matrix_world.to_quaternion()
    result = {}
    for name, src_name in mapping.items():
        bone = target.data.bones[name]
        world_rest = tq @ bone.matrix_local.to_quaternion()
        if name.startswith(('upperarm', 'lowerarm', 'wrist', 'finger', 'upperleg', 'lowerleg', 'foot', 'toe')):
            target_axis = tq @ (bone.tail_local - bone.head_local).normalized()
            src = source.data.bones[src_name]
            source_axis = sq @ (src.tail_local - src.head_local).normalized()
            world_rest = target_axis.rotation_difference(source_axis) @ world_rest
        result[name] = world_rest
    return result


def poses_from_world_delta(target, source, mapping, source_pose, root_delta):
    """Return local pose-basis quaternions, preserving target local translations.
    A mapped bone uses sourcePose * inverse(sourceRest) * calibratedTargetReference.
    The target reference aligns long-bone directions to source T reference without
    changing any target bind/rest matrix or mesh. This avoids adding T->idle arm
    drop onto an already lowered MH A-pose.
    Unmapped facial/helper bones retain local rest and follow their native parent.
    """
    sq = source.matrix_world.to_quaternion()
    tq = target.matrix_world.to_quaternion()
    reference = reference_orientations(target, source, mapping)
    target_global = {}
    rotations = {}
    for bone in ordered_bones(target):
        rest = bone.matrix_local.to_quaternion()
        parent_rest = bone.parent.matrix_local.to_quaternion() if bone.parent else Quaternion()
        local_rest = parent_rest.inverted() @ rest
        parent_pose = target_global[bone.parent.name] if bone.parent else Quaternion()
        if bone.name in mapping:
            src_name = mapping[bone.name]
            source_rest_world = sq @ source.data.bones[src_name].matrix_local.to_quaternion()
            source_pose_world = sq @ source_pose[src_name].to_quaternion()
            desired = tq.inverted() @ (source_pose_world @ source_rest_world.inverted()) @ reference[bone.name]
        else:
            desired = parent_pose @ local_rest
        basis = local_rest.inverted() @ parent_pose.inverted() @ desired
        basis.normalize()
        rotations[bone.name] = basis
        target_global[bone.name] = desired
    # MH's root is at pelvis height. Root/pelvis animation delta maps through the
    # target object and root rest basis; source rest position is NOT copied.
    root_rest = target.data.bones['root'].matrix_local.to_quaternion()
    local_delta = target.matrix_world.inverted().to_3x3() @ root_delta
    return rotations, root_rest.inverted() @ local_delta


def run(out, source_path, master):
    master_sha = hashlib.sha256(master.read_bytes()).hexdigest()
    runtime_master = out / 'mh_natural_fullweights.glb'
    runtime_master_sha = hashlib.sha256(runtime_master.read_bytes()).hexdigest() if runtime_master.exists() else None
    bpy.ops.wm.open_mainfile(filepath=str(master), load_ui=False, use_scripts=False)
    scene = bpy.context.scene
    scene.render.fps = FPS
    target = bpy.data.objects.get('MH163')
    if target is None or target.type != 'ARMATURE' or len(target.data.bones) != 163:
        raise ValueError('Master must contain complete MH163 armature with all 163 bones')
    if any(abs(v - 1) > 1e-6 for v in target.scale):
        raise ValueError('Apply target object scale in the master, not during retarget')
    original_objects = set(bpy.data.objects)
    original_actions = set(bpy.data.actions)
    rest_before = matrices_signature(target)
    mesh_before = geometry_signature(original_objects)
    source_sha = hashlib.sha256(source_path.read_bytes()).hexdigest()
    durations = glb_clip_lengths(source_path)
    bpy.ops.import_scene.gltf(filepath=str(source_path))
    imported_objects = set(bpy.data.objects) - original_objects
    source = next(o for o in imported_objects if o.type == 'ARMATURE')
    assert len(source.data.bones) == 65
    source.name = 'UAL_Source_Temporary'
    source_actions = {name: source_action(name, original_actions) for name in CLIPS}
    if source.animation_data:
        for track in source.animation_data.nla_tracks:
            track.mute = True
    target.animation_data_create()
    for track in target.animation_data.nla_tracks:
        track.mute = True
    target.data.pose_position = 'POSE'
    source.data.pose_position = 'POSE'
    mapping = bone_mapping()
    assert set(mapping).issubset(target.data.bones.keys())
    assert set(mapping.values()).issubset(source.data.bones.keys())
    target_hip = target.matrix_world @ target.data.bones['root'].head_local
    target_foot = sum((target.matrix_world @ target.data.bones[n].head_local
                       for n in ['foot.L', 'foot.R']), Vector()) * .5
    source_hip = source.matrix_world @ source.data.bones['pelvis'].head_local
    source_foot = sum((source.matrix_world @ source.data.bones[n].head_local
                       for n in ['foot_l', 'foot_r']), Vector()) * .5
    scale = (target_hip - target_foot).length / (source_hip - source_foot).length
    if not .5 < scale < 2.:
        raise ValueError(f'Unexpected source-to-target leg scale {scale}')
    # Algebraic rest identity check before any source clip evaluation.
    rotations, location = poses_from_world_delta(target, source, mapping,
        {b.name: b.matrix_local.copy() for b in source.data.bones}, Vector())
    # Source rest intentionally maps MH A-pose into a calibrated T reference.
    # Check the corresponding anatomical long-bone axes, not a false identity basis.
    reference = reference_orientations(target, source, mapping)
    reference_error = 0.
    for name, src_name in mapping.items():
        if name.startswith(('upperarm', 'lowerarm', 'wrist', 'finger', 'upperleg', 'lowerleg', 'foot', 'toe')):
            expected = source.matrix_world.to_quaternion() @ (source.data.bones[src_name].tail_local - source.data.bones[src_name].head_local).normalized()
            actual = reference[name] @ Vector((0, 1, 0))
            reference_error = max(reference_error, actual.angle(expected))
    if reference_error > 1e-3 or location.length > 1e-8:
        raise AssertionError(('reference direction', reference_error, location))
    report = {'status': 'RETARGET_TECHNICAL_PROTOTYPE', 'visual_pass': False,
              'combat_enabled': False, 'source_sha256': source_sha,
              'master_blend_sha256': master_sha, 'master_runtime_glb_sha256': runtime_master_sha,
              'target_bones': 163, 'mapped_bones': len(mapping),
              'unmapped_bones_keep_local_rest': sorted(set(target.data.bones.keys()) - set(mapping)),
              'leg_displacement_scale': scale, 'calibrated_reference_axis_max_rad': reference_error,
              'target_A_pose_to_source_T_reference_calibration': True,
              'rejected_uncalibrated_idle_left_wrist_x_m': -0.1156730130314827,
              'full_weights_preserved': True, 'godot_weight_limit_resolved': False,
              'rest_and_geometry_preserved': False, 'clips': [],
              'limitations': ['No foot contact IK or hand-held weapon validation',
                'No facial expressions authored; original facial bones/weights retained',
                'Sword_Attack is not spear/archery/shield/riding',
                'Original non-RM source clips; source pelvis displacement is retained',
                'Full >8 influences remain in master/GLB; Godot native limit is not hidden']}
    generated = []
    for name in CLIPS:
        source.animation_data.action = source_actions[name]
        target.animation_data.action = None
        for p in target.pose.bones:
            p.rotation_mode = 'QUATERNION'
            p.matrix_basis = Matrix.Identity(4)
        action = bpy.data.actions.new(name)
        action.use_fake_user = True
        target.animation_data.action = action
        source_duration = float(durations[name])
        samples = round(source_duration * SAMPLE_HZ) + 1
        duration = (samples - 1) / SAMPLE_HZ
        if abs(duration - source_duration) > 1e-6:
            raise ValueError(('Source is not on declared 30Hz grid', name, source_duration))
        previous = {}
        max_scale_error = 0.
        first_pose = None
        for sample in range(samples):
            time = sample / SAMPLE_HZ
            frame = sample * (FPS // SAMPLE_HZ)
            scene.frame_set(math.floor(frame), subframe=frame - math.floor(frame))
            bpy.context.view_layer.update()
            source_pose = {b.name: b.matrix.copy() for b in source.pose.bones}
            current_hip = source.matrix_world @ source_pose['pelvis'].translation
            delta = (current_hip - source_hip) * scale
            rotations, location = poses_from_world_delta(target, source, mapping, source_pose, delta)
            for bone in ordered_bones(target):
                p = target.pose.bones[bone.name]
                q = rotations[bone.name]
                if bone.name in previous and q.dot(previous[bone.name]) < 0:
                    q.negate()
                previous[bone.name] = q.copy()
                p.rotation_quaternion = q
                p.location = location if bone.name == 'root' else Vector()
                p.scale = (1., 1., 1.)
                p.keyframe_insert('rotation_quaternion', frame=frame, group=bone.name)
                if bone.name == 'root':
                    p.keyframe_insert('location', frame=frame, group=bone.name)
            bpy.context.view_layer.update()
            if sample == 0:
                first_pose = {n: list(target.pose.bones[n].head) for n in ['wrist.L', 'wrist.R', 'foot.L', 'foot.R', 'head']}
                if name == 'Idle_Loop':
                    if not first_pose['wrist.L'][0] > 0 or not first_pose['wrist.R'][0] < 0:
                        raise AssertionError(('Idle arms cross body after calibration', first_pose))
                    report['calibrated_idle_left_wrist_x_m'] = first_pose['wrist.L'][0]
            for p in target.pose.bones:
                max_scale_error = max(max_scale_error,
                    max(abs(v - 1.) for v in p.matrix.to_scale()))
        for fc in action.fcurves:
            for key in fc.keyframe_points:
                key.interpolation = 'LINEAR'
        if max_scale_error > 1e-4:
            raise AssertionError((name, 'unexpected bone stretch', max_scale_error))
        generated.append(action)
        record = {'name': name, 'duration_seconds': duration, 'source_duration_seconds': source_duration, 'samples': samples,
                  'blender_frame_end': duration * FPS, 'max_pose_scale_error': max_scale_error,
                  'first_pose_bone_heads_armature_space': first_pose}
        report['clips'].append(record)
        print('MH163_RETARGET_CLIP', json.dumps(record), flush=True)
    assert matrices_signature(target) == rest_before
    assert geometry_signature(original_objects) == mesh_before
    report['rest_and_geometry_preserved'] = True
    report['geometry_sha256'] = mesh_before
    # Remove only the imported source. Master meshes and source rig are not edited.
    for obj in imported_objects:
        bpy.data.objects.remove(obj, do_unlink=True)
    for action in source_actions.values():
        if action.users == 0:
            bpy.data.actions.remove(action)
    # All other imported actions must also stay out of the destination export.
    for action in list(bpy.data.actions):
        if action not in original_actions and action not in generated:
            bpy.data.actions.remove(action)
    target.animation_data.action = generated[0]
    scene.frame_start = 0
    scene.frame_end = round(max(durations[n] for n in CLIPS) * FPS)
    scene.frame_set(0)
    for text in list(bpy.data.texts):
        bpy.data.texts.remove(text)
    out.mkdir(parents=True, exist_ok=True)
    (out / 'source').mkdir(exist_ok=True)
    bpy.ops.object.select_all(action='DESELECT')
    target.select_set(True)
    runtime_meshes = [o for o in original_objects if o.type == 'MESH'
                      and not o.hide_render and not o.hide_get()]
    assert all(o.name != 'Body_SourceFull' for o in runtime_meshes)
    for obj in runtime_meshes:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = target
    report['export_runtime_meshes'] = sorted(o.name for o in runtime_meshes)
    report['reference_body_retained_in_blend_not_exported'] = 'Body_SourceFull' in bpy.data.objects
    bpy.ops.file.pack_all()
    bpy.ops.wm.save_as_mainfile(filepath=str(out / 'source/mh_natural_animated.blend'))
    bpy.ops.export_scene.gltf(filepath=str(out / 'mh_natural_animated_full.glb'),
        export_format='GLB', use_selection=True, export_animations=True, export_animation_mode='ACTIONS',
        export_skins=True, export_all_influences=True, export_def_bones=True,
        export_morph=True, export_apply=False, export_frame_range=False)
    (out / 'retarget-report.json').write_text(json.dumps(report, indent=2) + '\n')
    print('MH163_RETARGET_DONE', json.dumps(report), flush=True)


if __name__ == '__main__':
    args = sys.argv[sys.argv.index('--') + 1:]
    output = pathlib.Path(args[0]).resolve()
    source = pathlib.Path(args[1]).resolve()
    master = pathlib.Path(args[2]).resolve() if len(args) > 2 else output / 'source/mh_natural_editable.blend'
    run(output, source, master)
