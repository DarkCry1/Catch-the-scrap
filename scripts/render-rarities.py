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

import colorsys
fontfile=Path('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf')
font=bpy.data.fonts.load(str(fontfile)) if fontfile.is_file() else None
for index,rarity in enumerate(('Epic','Legendary','Celestial')):
 cx=(index-1)*7;style=DATA['rarityStyles'][rarity];tint=style['Color']
 for d in DATA['crate']:
  rgb=tint if d['name'] in ('PackingTape','TopTape','StampEye') else d['color']
  p=d['position'];part(dict(d,position=[p[0]+cx,p[1]+2.3,p[2]],color=rgb))
 for edge in DATA['rarityFrames']:
  p=edge['position'];rgb=[v*255 for v in colorsys.hsv_to_rgb((.16+edge['phase'])%1,.82,1)] if rarity=='Celestial' else tint
  part(dict(name='AnimatedRarityFrame',position=[p[0]+cx,p[1]+2.3,p[2]],size=edge['size'],color=rgb,material='Neon'))
 # Two stationary sample arcs show the opening's color family; gameplay arcs animate in 3D.
 for ring in range(2):
  for segment in range(16):
   a=segment*math.pi/8;radius=2.7+ring*.5
   rgb=[v*255 for v in colorsys.hsv_to_rgb((.16+segment/16)%1,.82,1)] if rarity=='Celestial' else tint
   part(dict(name='EnergyArc',position=[cx+math.cos(a)*radius,.17+ring*.2,math.sin(a)*radius],size=[radius*.34,.09,.13],color=rgb,material='Neon',yaw=-math.degrees(a)+90))
 bpy.ops.object.light_add(type='POINT',location=(cx,3,3));light=bpy.context.object;light.data.energy=70;light.data.color=[v/255 for v in tint];light.data.shadow_soft_size=2
 bpy.ops.object.text_add(location=(cx,4.2,.15));o=bpy.context.object;o.rotation_euler=(0,0,math.pi);o.data.body=rarity.upper();o.data.align_x='CENTER';o.data.size=.55
 if font:o.data.font=font
 o.data.materials.append(material(tint,'Neon'))
part(dict(name='AssetFloor',position=[0,-.3,0],size=[29,.5,18],color=[35,46,57],material='Concrete'))
bpy.ops.object.light_add(type='SUN',location=(0,0,20));bpy.context.object.data.energy=2.1;bpy.context.object.rotation_euler=(.45,-.25,-.4)
bpy.ops.object.light_add(type='AREA',location=(0,10,15));bpy.context.object.data.energy=1200;bpy.context.object.data.size=15
bpy.ops.object.camera_add(location=(11,21,14));cam=bpy.context.object;cam.rotation_euler=(Vector((0,0,2))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=31;scene.camera=cam
scene.render.resolution_x=1600;scene.render.resolution_y=1000;scene.cycles.samples=32
scene.render.filepath=str(ROOT/'build/rarity-frames-v1.0.png');bpy.ops.render.render(write_still=True)
