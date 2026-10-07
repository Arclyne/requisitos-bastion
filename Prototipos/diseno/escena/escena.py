# -*- coding: utf-8 -*-
"""Renders del tablero de Bastión para los prototipos con diseño.

Usa los modelos reales de modelos-3d/ (tablero_clasico_9x9/7x7, peon_clasico,
muro_madera) con Blender como módulo de Python (pip install bpy) y Cycles en CPU.
Uso: python escena.py <nombre> [<nombre> ...]   (ver ESCENAS)
"""
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector

AQUI = Path(__file__).resolve().parent
# los .blend se leen de modelos-3d/ del repo (o de la ruta en BASTION_MODELOS)
import os
MODELOS = Path(os.environ.get("BASTION_MODELOS", AQUI.parents[2] / "modelos-3d"))
COL = {"J1": "#D85A30", "J2": "#1D9E75", "J3": "#7F77DD", "J4": "#EF9F27"}
FONDO = "#F6F1E6"


def hex2rgb(h, a=1.0):
    h = h.lstrip("#")
    r, g, b = (int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))
    lin = lambda c: c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
    return (lin(r), lin(g), lin(b), a)


def material(nombre, color, emision=0.0, alfa=1.0):
    m = bpy.data.materials.new(nombre)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = hex2rgb(color)
    b.inputs["Roughness"].default_value = 0.6
    if emision:
        b.inputs["Emission Color"].default_value = hex2rgb(color)
        b.inputs["Emission Strength"].default_value = emision
    if alfa < 1:
        b.inputs["Alpha"].default_value = alfa
        try:
            m.surface_render_method = "BLENDED"
        except Exception:
            pass
    return m


def append(blend, nombre):
    with bpy.data.libraries.load(str(MODELOS / blend), link=False) as (src, dst):
        dst.objects = [nombre]
    o = dst.objects[0]
    bpy.context.scene.collection.objects.link(o)
    return o


def centro(col, fila, n):
    return (col - (n - 1) / 2, fila - (n - 1) / 2)


def celda(c):          # "e1" -> (4, 0)
    return ord(c[0]) - ord("a"), int(c[1:]) - 1


def escena(n=9, peones=(), muros=(), marcas=(), marcas_color="#FFE8A8", fantasma=None, camara="juego", destacado=None):
    bpy.ops.wm.open_mainfile(filepath=str(MODELOS / f"tablero_clasico_{n}x{n}.blend"))
    sc = bpy.context.scene
    # casillas resaltadas: material propio
    if marcas:
        mm = material("Marca", marcas_color, emision=0.15)
        for c in marcas:
            o = bpy.data.objects.get(f"Casilla_{c}")
            if o:
                o.data = o.data.copy()
                o.data.materials.clear()
                o.data.materials.append(mm)
    for c, jug in peones:
        p = append("peon_clasico.blend", "PEON_CLASICO")
        p.data = p.data.copy()
        p.data.materials.clear()
        p.data.materials.append(material("Peon_" + jug, COL[jug], emision=0.4 if destacado == c else 0))
        x, y = centro(*celda(c), n)
        p.location = (x, y, 0)
        if destacado == c:
            p.scale = (1.12, 1.12, 1.12)
    def poner_muro(surco, ori, jug, alfa=1.0, color=None):
        w = append("muro_madera.blend", "MURO_MADERA")
        w.data = w.data.copy()
        madera = material("Madera", color or "#F0C488", alfa=alfa, emision=0.15 if color else 0)
        acento = material("Acento", color or COL[jug], alfa=alfa, emision=0.15 if color else 0)
        # mismas ranuras que el modelo: 0 madera, 1 acento (clear() pondría todas las caras en la 0)
        w.data.materials[0] = madera
        w.data.materials[1] = acento
        x, y = centro(*celda(surco), n)
        w.location = (x + 0.5, y + 0.5, 0)
        if ori == "V":
            w.rotation_euler = (0, 0, math.pi / 2)
    for s, o, j in muros:
        poner_muro(s, o, j)
    if fantasma:
        s, o, color = fantasma
        poner_muro(s, o, "J1", alfa=0.4, color=color)
    # mundo, luz y cámara
    w = sc.world or bpy.data.worlds.new("Mundo")
    sc.world = w
    w.use_nodes = True
    w.node_tree.nodes["Background"].inputs["Color"].default_value = hex2rgb(FONDO)
    w.node_tree.nodes["Background"].inputs["Strength"].default_value = 1.0
    sol = bpy.data.lights.new("Sol", "SUN")
    sol.energy = 3.2
    sol.angle = math.radians(12)
    so = bpy.data.objects.new("Sol", sol)
    so.rotation_euler = (math.radians(40), math.radians(12), math.radians(-35))
    sc.collection.objects.link(so)
    cam = bpy.data.cameras.new("Cam")
    cam.lens = 36
    co = bpy.data.objects.new("Cam", cam)
    sc.collection.objects.link(co)
    sc.camera = co
    d = {"juego": (0, -n * 1.5, n * 1.3), "menu": (-n * 0.9, -n * 1.1, n * 0.7), "cenital": (0, -0.01, n * 1.9)}[camara]
    co.location = Vector(d)
    mira = Vector((0, -0.55 if camara == "juego" else 0, 0))
    co.rotation_euler = (mira - co.location).to_track_quat("-Z", "Y").to_euler()
    r = sc.render
    r.engine = "CYCLES"
    sc.cycles.device = "CPU"
    sc.cycles.samples = 24
    sc.cycles.use_denoising = True
    r.resolution_x, r.resolution_y, r.resolution_percentage = 1366, 768, 100
    r.film_transparent = False
    sc.view_settings.view_transform = "Standard"
    return sc


ESCENAS = {
    # tu turno, partida clásica a mitad
    "partida": dict(peones=[("e3", "J1"), ("e7", "J2")], muros=[("c5", "H", "J2"), ("f4", "V", "J1"), ("d6", "H", "J1")]),
    # peón seleccionado: casillas alcanzables
    "mover": dict(peones=[("e3", "J1"), ("e7", "J2")], muros=[("c5", "H", "J2"), ("f4", "V", "J1"), ("d6", "H", "J1")],
                  marcas=["e4", "d3", "f3", "e2"], destacado="e3"),
    # salto: rival delante, se puede saltar recto
    "salto": dict(peones=[("e4", "J1"), ("e5", "J2")], muros=[("c5", "H", "J2"), ("f4", "V", "J1")],
                  marcas=["e6", "d4", "f4", "e3"], destacado="e4"),
    # salto diagonal: muro detrás del rival
    "salto_diag": dict(peones=[("e4", "J1"), ("e5", "J2")], muros=[("d5", "H", "J2"), ("f4", "V", "J1")],
                       marcas=["d5", "f5", "d4", "f4", "e3"], destacado="e4"),
    # muro en vista previa, válido
    "muro_ok": dict(peones=[("e3", "J1"), ("e7", "J2")], muros=[("c5", "H", "J2"), ("f4", "V", "J1")],
                    fantasma=("d6", "H", "#D85A30")),
    # muro que encerraría al rival: vista previa en rojo
    "muro_mal": dict(peones=[("e3", "J1"), ("a9", "J2")], muros=[("a7", "H", "J1"), ("e5", "H", "J2")],
                     fantasma=("b8", "V", "#C0392B")),
    # cuatro jugadores
    "cuatro": dict(peones=[("e2", "J1"), ("e8", "J3"), ("h5", "J4")],   # J2 abandonó: su peón sale, sus muros se quedan
                   muros=[("d6", "H", "J3"), ("c4", "V", "J2"), ("f3", "H", "J1"), ("g5", "V", "J4")]),
    # llegada a la meta
    "meta": dict(peones=[("e9", "J1"), ("d4", "J2")], muros=[("c5", "H", "J2"), ("f4", "V", "J1"), ("d6", "H", "J1"), ("e2", "H", "J2")],
                 destacado="e9"),
    # fondo del menú
    "menu": dict(peones=[("e1", "J1"), ("e9", "J2")], muros=[("c5", "H", "J2"), ("f4", "V", "J1")], camara="menu"),
    # rápida 7x7
    "rapida": dict(n=7, peones=[("d2", "J1"), ("d6", "J2")], muros=[("b4", "H", "J2"), ("d3", "V", "J1")]),
}


def main(nombres):
    out = AQUI / "render"
    out.mkdir(exist_ok=True)
    for nombre in nombres or ESCENAS:
        sc = escena(**ESCENAS[nombre])
        sc.render.filepath = str(out / f"{nombre}.jpg")
        sc.render.image_settings.file_format = "JPEG"
        sc.render.image_settings.quality = 86
        bpy.ops.render.render(write_still=True)
        print("listo", nombre)


if __name__ == "__main__":
    main(sys.argv[1:])
