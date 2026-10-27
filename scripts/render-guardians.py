"""Optional Blender preview of the actual scrapyard blueprint; not a Studio screenshot."""
from pathlib import Path
import json, math, sys
import bpy
from mathutils import Matrix, Vector
ROOT=Path(__file__).resolve().parents[1]
DATA=json.loads((ROOT/'build/blueprints.json').read_text())
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
scene=bpy.context.scene
scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=16
scene.cycles.use_denoising=False
scene.render.resolution_x=1400;scene.render.resolution_y=900;scene.render.resolution_percentage=100
scene.world.color=(.3,.35,.4)
scene.view_settings.view_transform='AgX'
A=Matrix(((1,0,0,0),(0,0,1,0),(0,1,0,0),(0,0,0,1)))
materials={}
def material(rgb,kind,transparency=0):
 key=tuple(rgb)+(kind,transparency)
 if key in materials:return materials[key]
 mat=bpy.data.materials.new(kind);mat.use_nodes=True
 rgb=[n/255 for n in rgb];linear=[n/12.92 if n<=.04045 else ((n+.055)/1.055)**2.4 for n in rgb]
 bsdf=mat.node_tree.nodes.get('Principled BSDF');bsdf.inputs['Base Color'].default_value=(*linear,1)
 bsdf.inputs['Metallic'].default_value=.5 if kind in ('Metal','CorrodedMetal') else 0
 bsdf.inputs['Roughness'].default_value=.18 if kind=='Glass' else .6
 if transparency:bsdf.inputs['Alpha'].default_value=1-transparency
 if kind in ('CorrodedMetal','Concrete','Ground','Slate'):
  noise=mat.node_tree.nodes.new('ShaderNodeTexNoise');noise.inputs['Scale'].default_value=22;noise.inputs['Detail'].default_value=2
  bump=mat.node_tree.nodes.new('ShaderNodeBump');bump.inputs['Strength'].default_value=.15;bump.inputs['Distance'].default_value=.1
  mat.node_tree.links.new(noise.outputs['Fac'],bump.inputs['Height']);mat.node_tree.links.new(bump.outputs['Normal'],bsdf.inputs['Normal'])
 if kind=='Neon':bsdf.inputs['Emission Color'].default_value=(*linear,1);bsdf.inputs['Emission Strength'].default_value=2
 materials[key]=mat;return mat
# Allocate meshes directly for large scenes; repeated operators rebuild the depsgraph.
meshes={}
for shape in ('Block','Cylinder','Ball'):
 if shape=='Cylinder':bpy.ops.mesh.primitive_cylinder_add(vertices=16,radius=.5,depth=1)
 elif shape=='Ball':bpy.ops.mesh.primitive_uv_sphere_add(segments=12,ring_count=6,radius=.5)
 else:bpy.ops.mesh.primitive_cube_add(size=1)
 template=bpy.context.object
 meshes[shape]=template.data.copy()
 bpy.data.objects.remove(template,do_unlink=True)
def part(d):
 shape=d.get('shape','Block')
 obj=bpy.data.objects.new(d['name'],meshes[shape].copy())
 scene.collection.objects.link(obj)
 p=d['position'];s=d['size']
 R=Matrix.Rotation(math.radians(d.get('pitch',0)),4,'X')@Matrix.Rotation(math.radians(d.get('yaw',0)),4,'Y')@Matrix.Rotation(math.radians(d.get('roll',0)),4,'Z')
 S=Matrix.Diagonal((*s,1))
 obj.matrix_world=Matrix.Translation(Vector((p[0],p[2],p[1])))@A@R@S@(Matrix.Rotation(math.pi/2,4,'Y') if shape=='Cylinder' else Matrix.Identity(4))
 obj.data.materials.append(material(d['color'],d.get('material','Metal'),d.get('transparency',0)))

fontfile=Path('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf')
font=bpy.data.fonts.load(str(fontfile)) if fontfile.is_file() else None
import colorsys
for i,g in enumerate(DATA['guardians']):
 cx=(i-3)*14;scale=g['profile']['Scale'];tint=DATA['stages'][i]['Color']
 for j,d in enumerate(g['parts']):
  rgb=tint if d['palette'] in ('amber','energy') else DATA['palette'][d['palette']]
  if i==6 and d['palette'] in ('amber','energy'):rgb=[c*255 for c in colorsys.hsv_to_rgb((j*.055)%1,.82,1)]
  p=d['position'];part(dict(d,position=[cx+p[0]*scale,p[1]*scale+.35,p[2]*scale],size=[s*scale for s in d['size']],color=rgb,material='Neon' if d['palette']=='energy' else 'Metal'))
 part(dict(name='StagePad',size=[12,.3,9],position=[cx,.1,0],color=[27,37,46],material='Metal'))
 bpy.ops.object.text_add(location=(cx,6,.3));o=bpy.context.object;o.rotation_euler=(0,0,math.pi)
 o.data.body=g['rarity'].upper()+' / '+str(g['profile']['ChaseSpeed'])+' STUDS/SEC';o.data.align_x='CENTER';o.data.size=.44
 if font:o.data.font=font
 o.data.materials.append(material(tint,'Neon'))
# Native-part, 5.5-stud avatar silhouette supplies a size reference.
for name,size,p in [('Body',[2,2,1],[-53,3,0]),('Head',[1.3,1.3,1.3],[-53,4.8,0]),('LeftLeg',[.8,2,1],[-53.5,1,0]),('RightLeg',[.8,2,1],[-52.5,1,0]),('LeftArm',[.7,2,1],[-54.4,3,0]),('RightArm',[.7,2,1],[-51.6,3,0])]:part(dict(name=name,size=size,position=p,color=[170,185,200],material='Metal'))
part(dict(name='GalleryFloor',size=[119,.5,28],position=[-3,-.3,0],color=[55,66,76],material='Concrete'))
bpy.ops.object.light_add(type='SUN',location=(0,0,35));bpy.context.object.data.energy=2.8;bpy.context.object.rotation_euler=(.4,-.3,-.3)
bpy.ops.object.light_add(type='AREA',location=(0,8,30));bpy.context.object.data.energy=9000;bpy.context.object.data.size=90
bpy.ops.object.camera_add(location=(13,110,38));cam=bpy.context.object;cam.rotation_euler=(Vector((-3,0,7))-cam.location).to_track_quat('-Z','Y').to_euler()
cam.data.type='ORTHO';cam.data.ortho_scale=120;scene.camera=cam
scene.render.resolution_x=2600;scene.render.resolution_y=1050;scene.cycles.samples=24
scene.render.filepath=str(ROOT/'build/stage-guardians-v1.5.png');bpy.ops.render.render(write_still=True)
