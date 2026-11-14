"""Explicit experimental normal MainLoop config; caller MUST restore originals.
Does not change a source project by importing this module or execute an engine.
"""
import re
ENTRY='RepresentationBattleControl'
def project_config(text):
    section=re.search(r'(?ms)^\[application\]\n(.*?)(?=^\[|\Z)',text)
    if not section:raise ValueError('application section missing')
    body=section.group(1)
    body=re.sub(r'(?m)^run/main_(?:scene|loop_type)=.*\n?','',body)
    body+='run/main_loop_type="'+ENTRY+'"\nrun/main_scene="res://tools/representation_metal/entry.tscn"\n'
    return text[:section.start(1)]+body+text[section.end(1):]
