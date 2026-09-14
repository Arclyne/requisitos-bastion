# -*- coding: utf-8 -*-
"""Genera los diagramas entidad-relación del modelo de datos.

Uso, desde la raíz del repositorio (tras bd/generar_tablas.ps1, que escribe
er/esquema.json):

    python er/generar.py                 # todos los diagramas
    python er/generar.py partida social  # solo algunos
    python er/generar.py --sin-disposicion partida
        vuelve a dibujar er/modelos/partida.py tal como está, sin recalcular
        posiciones; sirve para retocar a mano coordenadas del modelo.

Para cada diagrama escribe er/modelos/<id>.py (datos en el formato de
model.py de la skill diagrama-er-chen) y, en er/salida, <id>.svg, <id>.drawio
y, si encuentra Microsoft Edge o Chrome, <id>.pdf (para el documento) y
<id>.png. Los renderizadores render_svg.py y render_drawio.py son los de la
skill, con el único añadido de las relaciones recursivas.
"""

import importlib.util
import json
import os
import pprint
import re
import runpy
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

AQUI = Path(__file__).resolve().parent
sys.path.insert(0, str(AQUI))

from diagramas import DIAGRAMAS, PADRE_TOTAL, VERBOS  # noqa: E402
from disposicion import construir  # noqa: E402

MODELOS = AQUI / "modelos"
SALIDA = AQUI / "salida"
NAVEGADORES = [
    r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
    r"C:\Program Files\Microsoft\Edge\Application\msedge.exe",
    r"C:\Program Files\Google\Chrome\Application\chrome.exe",
    "/usr/bin/microsoft-edge", "/usr/bin/google-chrome", "/usr/bin/chromium",
]


def escribir_modelo(ruta, diag, m):
    lineas = [
        "# -*- coding: utf-8 -*-",
        f'"""Modelo E-R «{diag["titulo"]}», generado por er/generar.py a partir de',
        'er/esquema.json y er/diagramas.py. Se puede retocar a mano y volver a dibujar',
        f'con: python er/generar.py --sin-disposicion {diag["id"]}"""',
        "",
        "ENTITIES = " + pprint.pformat(m["ENTITIES"], width=110, sort_dicts=False),
        "",
        "ENTITY_LABEL = " + pprint.pformat(m["ENTITY_LABEL"], width=110),
        "",
        "RELATIONS = " + pprint.pformat(m["RELATIONS"], width=110, sort_dicts=False),
        "",
        "ATTRS = " + pprint.pformat(m["ATTRS"], width=110, sort_dicts=False),
        "",
        'ATTR_BY_ID = {a["id"]: a for a in ATTRS}',
        "",
        "NOTES = []",
        "",
    ]
    ruta.write_text("\n".join(lineas), encoding="utf-8")


def dibujar(ruta_modelo, ident):
    spec = importlib.util.spec_from_file_location("model", ruta_modelo)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    sys.modules["model"] = mod
    previo = os.getcwd()
    with tempfile.TemporaryDirectory() as tmp:
        os.chdir(tmp)
        try:
            runpy.run_path(str(AQUI / "render_svg.py"), run_name="__main__")
            runpy.run_path(str(AQUI / "render_drawio.py"), run_name="__main__")
        finally:
            os.chdir(previo)
        shutil.copy(Path(tmp) / "diagrama_er.svg", SALIDA / f"{ident}.svg")
        shutil.copy(Path(tmp) / "diagrama_er.drawio", SALIDA / f"{ident}.drawio")
    del sys.modules["model"]


def navegador():
    return next((p for p in NAVEGADORES if os.path.exists(p)), None)


def medidas_svg(svg):
    cab = svg.read_text(encoding="utf-8")[:400]
    w = float(re.search(r'width="([\d.]+)"', cab).group(1))
    h = float(re.search(r'height="([\d.]+)"', cab).group(1))
    return w, h


def _html(svg, css, cuerpo):
    return ("<!doctype html><html><head><meta charset='utf-8'><style>"
            + css + "</style></head><body>" + cuerpo.format(src=svg.name) + "</body></html>")


def _correr(exe, args, perfil):
    subprocess.run([exe, "--headless", "--disable-gpu", "--no-first-run",
                    f"--user-data-dir={perfil}"] + args,
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=180)


def convertir(svg, exe, ancho_pdf_in=11.0, ancho_png=2600):
    """SVG -> PDF vectorial (para LaTeX) y PNG, con el navegador en modo sin ventana."""
    w, h = medidas_svg(svg)
    alto_in = ancho_pdf_in * h / w
    with tempfile.TemporaryDirectory() as perfil:
        pagina = svg.with_suffix(".pdf.html")
        pagina.write_text(_html(
            svg,
            f"@page{{size:{ancho_pdf_in}in {alto_in:.3f}in;margin:0}}"
            "html,body{margin:0;padding:0;overflow:hidden}"
            f"img{{display:block;width:{ancho_pdf_in}in;height:{alto_in - 0.02:.3f}in}}",
            "<img src='{src}'>"), encoding="utf-8")
        _correr(exe, ["--no-pdf-header-footer", "--print-to-pdf-no-header",
                      f"--print-to-pdf={svg.with_suffix('.pdf')}", pagina.as_uri()], perfil)
        pagina.unlink()
        alto_png = round(ancho_png * h / w)
        pagina = svg.with_suffix(".png.html")
        pagina.write_text(_html(
            svg, "html,body{margin:0;padding:0;overflow:hidden}"
                 f"img{{display:block;width:{ancho_png}px;height:{alto_png}px}}",
            "<img src='{src}'>"), encoding="utf-8")
        _correr(exe, ["--hide-scrollbars", f"--window-size={ancho_png},{alto_png}",
                      f"--screenshot={svg.with_suffix('.png')}", pagina.as_uri()], perfil)
        pagina.unlink()


def mosaico(svg, exe, destino, columnas=2, filas=2, ancho_tesela=1800):
    """Teselas ampliadas del diagrama, para revisar de cerca las zonas densas."""
    w, h = medidas_svg(svg)
    escala = ancho_tesela * columnas / w
    tw, th = ancho_tesela, round(h * escala / filas)
    destino.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as perfil:
        for f in range(filas):
            for c in range(columnas):
                pagina = destino / f"{svg.stem}_{f}{c}.html"
                shutil.copy(svg, destino / svg.name)
                pagina.write_text(_html(
                    svg, "html,body{margin:0;padding:0;overflow:hidden}"
                         f"div{{width:{tw}px;height:{th}px;overflow:hidden;position:relative}}"
                         f"img{{position:absolute;left:{-c * tw}px;top:{-f * th}px;"
                         f"width:{round(w * escala)}px;height:{round(h * escala)}px}}",
                    "<div><img src='{src}'></div>"), encoding="utf-8")
                _correr(exe, ["--hide-scrollbars", f"--window-size={tw},{th}",
                              f"--screenshot={destino / f'{svg.stem}_{f}{c}.png'}", pagina.as_uri()], perfil)
                pagina.unlink()


def main(argv):
    sin_disposicion = "--sin-disposicion" in argv
    revision = None
    if "--revision" in argv:
        revision = Path(argv[argv.index("--revision") + 1])
    ids = [a for a in argv if not a.startswith("--") and (revision is None or Path(a) != revision)]
    esquema = json.loads((AQUI / "esquema.json").read_text(encoding="utf-8-sig"))
    MODELOS.mkdir(exist_ok=True)
    SALIDA.mkdir(exist_ok=True)
    exe = navegador()
    for diag in DIAGRAMAS:
        if ids and diag["id"] not in ids:
            continue
        ruta = MODELOS / f"{diag['id']}.py"
        if not sin_disposicion and not diag.get("fijo"):
            m = construir(esquema, diag, VERBOS, PADRE_TOTAL)
            escribir_modelo(ruta, diag, m)
            print(f"{diag['id']:<11} {len(m['ENTITIES']):>2} entidades, {len(m['RELATIONS']):>2} relaciones, "
                  f"{len(m['ATTRS']):>3} atributos, índice de cruces {m['cruces']}, "
                  f"factor {m['factor']:.2f}, atributos a {m['pt']:.1f} pt en la página")
        dibujar(ruta, diag["id"])
        if exe:
            convertir(SALIDA / f"{diag['id']}.svg", exe)
            if revision:
                mosaico(SALIDA / f"{diag['id']}.svg", exe, revision)
    if not exe:
        print("No se encontró Edge ni Chrome: solo se generaron .svg y .drawio.")


if __name__ == "__main__":
    main(sys.argv[1:])
