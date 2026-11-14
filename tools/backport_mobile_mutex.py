"""Apply the exact upstream Forward Mobile mutex-scope fix to the pinned 4.6.3 source.

Upstream PR https://github.com/godotengine/godot/pull/123312
The original engine source and this derivative remain under the engine's MIT license.
"""
from pathlib import Path
import difflib,sys
root=Path(sys.argv[1])
path=root/"servers/rendering/renderer_rd/forward_mobile/scene_shader_forward_mobile.cpp"
source=path.read_text()
old="\tMutexLock lock(SceneShaderForwardMobile::singleton_mutex);\n\tError err = SceneShaderForwardMobile::singleton->compiler.compile(RS::SHADER_SPATIAL, code, &actions, path, gen_code);"
new="\tError err = OK;\n\t{\n\t\tMutexLock lock(SceneShaderForwardMobile::singleton_mutex);\n\t\terr = SceneShaderForwardMobile::singleton->compiler.compile(RS::SHADER_SPATIAL, code, &actions, path, gen_code);\n\t}"
assert source.count(old)==1
updated=source.replace(old,new)
for name in ("get_native_source_code","get_native_shader_and_version","get_shader_variant","is_valid","~ShaderData"):
    token="SceneShaderForwardMobile::ShaderData::"+name+"("
    start=updated.index(token)
    end=updated.index("\n}",start)
    body=updated[start:end]
    lock="\t\tMutexLock lock(SceneShaderForwardMobile::singleton_mutex);\n"
    assert body.count(lock)==1,name
    updated=updated[:start]+body.replace(lock,"")+updated[end:]
path.write_text(updated)
print("".join(difflib.unified_diff(source.splitlines(True),updated.splitlines(True),fromfile="a/"+str(path.relative_to(root)),tofile="b/"+str(path.relative_to(root)))),end="")
