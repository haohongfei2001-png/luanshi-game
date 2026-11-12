#!/usr/bin/env python3
"""Instrument step boundaries only in a disposable copy for attribution, never in shipped code."""
import pathlib,sys
p=pathlib.Path(sys.argv[1])
s=p.read_text()
pre,entry=s.split('func step() -> void:\n',1)
step,post=entry.split('# Version 1',1)
tags=[('grid','\t_rebuild_grid()'),('command','\tcorps.advance(self)'),('assessment','\tfor u in roster:'),('movement_combat','\t# Alternate initiative'),('missiles','\t_projectiles()'),('siege','\t_siege()'),('objectives','\tif objectives.enabled:')]
names=['input']+[t for t,k in tags]
for j,(tag,key) in enumerate(tags):
    assert step.count(key)==1, key
    step=step.replace(key,f'\ttail_us[{j}]=Time.get_ticks_usec()-tail_mark\n\ttail_mark=Time.get_ticks_usec()\n'+key)
step=step.replace('\t\treturn\n\t_resolve_historical()',f'\t\ttail_us[{len(tags)}]=Time.get_ticks_usec()-tail_mark\n\t\treturn\n\t_resolve_historical()\n\ttail_us[{len(tags)}]=Time.get_ticks_usec()-tail_mark')
p.write_text(pre+'var tail_names: Array='+repr(names)+'\nvar tail_us:=PackedInt32Array([0,0,0,0,0,0,0,0])\n\nfunc step() -> void:\n\tvar tail_mark:=Time.get_ticks_usec()\n'+step+'# Version 1'+post)
