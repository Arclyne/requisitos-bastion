import json, sys
import bpy
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Vector
import escena as E
out={}
for n,cam in [(9,'juego'),(7,'juego')]:
    sc=E.escena(n=n, camara=cam); bpy.context.view_layer.update()
    co=sc.camera; d={}
    for i in range(n):
        for j in range(n):
            x,y=E.centro(i,j,n)
            for z,k in [(0,''),(0.45,'_alto')]:
                v=world_to_camera_view(sc,co,Vector((x,y,z)))
                d[f"{chr(97+i)}{j+1}{k}"]=(round(v.x*1366,1), round((1-v.y)*768,1))
    # esquinas de surcos para muros: centro de muro en (x+.5,y+.5)
    out[f"{n}"]=d
json.dump(out,open('coords.json','w'))
print(out['9']['e3'], out['9']['e7'], out['9']['a1'], out['9']['i9'])
