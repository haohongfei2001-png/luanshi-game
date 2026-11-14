"""Publish exact GLB runtime weights, retaining raw Blender groups separately.
Never truncate influences; raw group sums are not glTF normalized skin weights.
"""
import gzip, hashlib, json, pathlib, struct, sys
from check_retarget import read, accessor

def rows(doc, binary, index):
    a, data = accessor(doc, binary, index)
    width = {'VEC2': 2, 'VEC4': 4}[a['type']]
    code = {5121:'B',5123:'H',5126:'f'}[a['componentType']]
    return list(struct.iter_unpack('<'+code*width, data))

def update(glb, sidecar_path):
    doc, binary = read(glb)
    sidecar = json.loads(sidecar_path.read_text())
    parts = {p['node']:p for p in sidecar['parts']}
    seen = {}; changed = 0; max_error = 0.0; dropped = []
    for node in doc['nodes']:
        if 'mesh' not in node: continue
        part = parts[node['name']]
        names = [doc['nodes'][i]['name'] for i in doc['skins'][node['skin']]['joints']]
        for primitive in doc['meshes'][node['mesh']]['primitives']:
            at = primitive['attributes']; ids = rows(doc,binary,at['TEXCOORD_1'])
            sets = sorted(int(k.split('_')[1]) for k in at if k.startswith('WEIGHTS_'))
            assert sets == list(range(len(sets)))
            ws = [rows(doc,binary,at[f'WEIGHTS_{s}']) for s in sets]
            js = [rows(doc,binary,at[f'JOINTS_{s}']) for s in sets]
            for i, uv in enumerate(ids):
                vid = round(uv[0])+256*round(uv[1]); v = part['vertices'][vid]; assert v['id']==vid
                entries = sorted([[names[j],w] for ss in range(len(sets)) for j,w in zip(js[ss][i],ws[ss][i]) if w>0])
                key=(node['name'],vid)
                if key in seen:
                    assert seen[key]==entries, ('seam weights mismatch', key)
                    continue
                seen[key]=entries
                raw=v.get('raw_blender_weights',v['weights']); total=sum(w for _,w in raw)
                missing = [[b,w] for b,w in raw if b not in dict(entries)]
                if missing: dropped.append({'node':node['name'],'id':vid,'raw_missing':missing})
                kept_total=sum(w for b,w in raw if b in dict(entries))
                error=max(abs(dict(raw)[b]/kept_total-w) for b,w in entries)
                assert error<2e-7, (key,error)
                assert abs(sum(w for _,w in entries)-1)<2e-7
                max_error=max(max_error,error);changed+=abs(total-1)>1e-6
                v.update(raw_blender_weights=raw, raw_blender_weight_sum=total,
                         runtime_normalization_factor=1/total,
                         weights=[[b,w/total] for b,w in raw], gltf_exported_weights=entries)
    assert len(seen)==sum(len(p['vertices']) for p in parts.values())
    sidecar.update(format='mh-full-influences-v2',weights_semantics='All raw Blender groups explicitly divided by their total, no truncation; exact exported GLB WEIGHTS_n retained separately and may omit tiny influences',runtime_glb_sha256=hashlib.sha256(glb.read_bytes()).hexdigest())
    blob=json.dumps(sidecar,separators=(',',':')).encode();sidecar_path.write_bytes(blob)
    with gzip.GzipFile(filename=str(sidecar_path)+'.gz',mode='wb',mtime=0) as stream:stream.write(blob)
    report={'source_vertices':len(seen),'raw_nonunit_vertices':changed,'max_export_normalization_error':max_error,'all_sidecar_influences_retained':True,'gltf_has_all_source_influences':not dropped,'gltf_dropped_vertices':dropped,'sha256':hashlib.sha256(blob).hexdigest(),'runtime_glb_sha256':sidecar['runtime_glb_sha256']}
    (sidecar_path.parent/'weight-normalization-report.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report))
    return report

if __name__=='__main__':update(pathlib.Path(sys.argv[1]),pathlib.Path(sys.argv[2]))
