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
for index,v in enumerate(DATA['variants']):
 cx=(index%5-2)*12;cz=(index//5-.5)*13
 for d in v['parts']:
  p=d['position'];rgb=DATA['stages'][2]['Color'] if d['palette'] in ('amber','energy') else DATA['palette'][d['palette']]
  part(dict(d,position=[cx+p[0],p[1]+.3,cz+p[2]],color=rgb,material='Neon' if d['palette']=='energy' else 'Metal'))
 part(dict(name='DisplayPad',size=[10,.3,9],position=[cx,.1,cz],color=[29,39,47],material='DiamondPlate'))
 bpy.ops.object.text_add(location=(cx,cz+5.2,.32));o=bpy.context.object;o.rotation_euler=(0,0,math.pi)
 o.data.body=v['name'].upper()+' / '+v['source'].upper();o.data.align_x='CENTER';o.data.size=.43
 if font:o.data.font=font
 o.data.materials.append(material(DATA['stages'][2]['Color'],'Neon'))
part(dict(name='Ground',size=[67,.5,33],position=[0,-.3,0],color=[67,77,83],material='Concrete'))
bpy.ops.object.light_add(type='SUN',location=(0,0,30));bpy.context.object.data.energy=2.8;bpy.context.object.rotation_euler=(.35,-.2,-.4)
bpy.ops.object.light_add(type='AREA',location=(0,8,25));bpy.context.object.data.energy=3500;bpy.context.object.data.size=20
bpy.ops.object.camera_add(location=(22,55,34));cam=bpy.context.object;cam.rotation_euler=(Vector((0,0,3.7))-cam.location).to_track_quat('-Z','Y').to_euler()
cam.data.type='ORTHO';cam.data.ortho_scale=74;scene.camera=cam
scene.render.resolution_x=2200;scene.render.resolution_y=1300;scene.cycles.samples=32
scene.render.filepath=str(ROOT/'build/robot-variants-v1.0.png');bpy.ops.render.render(write_still=True)
