#!/usr/bin/env python3
# Integrator's contract in a disposable candidate checkout only. No production presentation source is changed.
import pathlib
p=pathlib.Path('scripts/field/presentation.gd')
s=p.read_text()
def rep(old,new):
 global s
 assert s.count(old)==1,old
 s=s.replace(old,new)
rep('const Builder :=', 'const MountArt := preload("res://scripts/field/mount_art.gd")\nconst Builder :=')
rep('var horse: Batch','var horse_rank: Batch\nvar horse: Batch')
rep('var mount_mesh := Figures.horse()', 'var mount_mesh := MountArt.mesh(false,true)')
rep('horse = _batch(mount_mesh,_material(FRIEND,0,true),battle.ordinary_counts[0]+battle.ordinary_counts[1]+1)','horse = _batch(mount_mesh,MountArt.material(),battle.ordinary_counts[0]+battle.ordinary_counts[1]+1)\n\thorse_rank = _batch(MountArt.mesh(false,false),MountArt.material(),battle.ordinary_counts[0]+battle.ordinary_counts[1]+1)')
rep('var wagon := Figures.horse(true)','var wagon := MountArt.mesh(true,true)')
rep('cart = _batch(wagon,_material(FRIEND,0,true),1)','cart = _batch(wagon,MountArt.material(),1)')
rep('horse.used = 0','horse.used = 0\n\thorse_rank.used=0')
rep('_put(horse,base,angle,Color((horse_pose+0.5)/128,0.0 if unhorsed else progress,0.0 if unhorsed else u.stride,data.a))','_put(horse if zoom<35.0 and p.distance_squared_to(center)<256.0 else horse_rank,base,angle,MountArt.pose(horse_pose,progress,u.stride,0.0 if unhorsed else u.pos.distance_to(u.before),alpha,data.a))')
rep('Color((state+0.5)/128.0,1,stride,0))','MountArt.pose(state,1.0,stride,battle.hero.pos.distance_to(battle.hero.before) if battle.vehicle==id else 0.0,alpha))')
rep('[contact,horse,cart,arrows,runners','[contact,horse,horse_rank,cart,arrows,runners')
p.write_text(s)
