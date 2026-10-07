# -*- coding: utf-8 -*-
"""Genera los prototipos corregidos de Prototipos/corregidos/ en el mismo estilo
de boceto de los originales.

Uso, desde la raíz del repositorio:
    python Prototipos/corregidos/fuente/generar.py            # todas
    python Prototipos/corregidos/fuente/generar.py 3b 6c      # algunas

Cada pantalla es un fragmento de HTML en PANTALLAS (pantallas.py); este script
la envuelve con los estilos comunes y la fotografía con Playwright (Chromium).
Las fuentes Architects Daughter y Kalam son de Google Fonts (licencia OFL) y
van en fuente/fonts.
"""
import sys
from pathlib import Path

AQUI = Path(__file__).resolve().parent
SALIDA = AQUI.parent
sys.path.insert(0, str(AQUI))
from pantallas import PANTALLAS  # noqa: E402

CSS = """
@font-face{font-family:Mano;src:url('fonts/ArchitectsDaughter-Regular.ttf')}
@font-face{font-family:Titulo;src:url('fonts/Kalam-Bold.ttf')}
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:Mano,sans-serif;color:#1b1b1b;background:#fff}
.hoja{width:var(--w);height:var(--h);background:#000;padding-top:34px;position:relative}
.hoja>.id{position:absolute;left:10px;top:6px;color:#555;font:600 15px monospace}
.hoja>.id b{color:#c9c9c9}
.pant{background:#fbfaf7;height:calc(100% - 0px);border-radius:10px 10px 0 0;padding:22px 24px;position:relative;overflow:hidden}
h1{font-family:Mano;font-weight:400;font-size:26px;margin-bottom:10px}
h2{font-family:Mano;font-weight:400;font-size:20px;margin-bottom:6px}
.marca{font-family:Titulo;font-size:52px;text-align:center}
.gris{color:#8a8a8a}.peq{font-size:13px}.mini{font-size:11px}
.btn{display:inline-flex;align-items:center;justify-content:center;border:3px solid #1b1b1b;border-radius:10px;padding:8px 18px;font-size:17px;background:#fbfaf7}
.btn.prim{background:#1b1b1b;color:#fbfaf7}
.btn.sec{border:3px dashed #a8a8a8;color:#8a8a8a}
.btn.off{border-color:#c9c9c9;color:#b5b5b5;background:#f1f0ec}
.btn.full{display:flex;width:100%}
.campo{border:3px solid #1b1b1b;border-radius:10px;padding:10px 14px;font-size:17px;color:#9a9a9a;background:#fff}
.campo.lleno{color:#1b1b1b}
.campo.err{border-color:#1b1b1b;background:#f3f1ec}
.lbl{font-size:13px;color:#8a8a8a;margin:10px 0 4px}
.caja{border:3px solid #1b1b1b;border-radius:12px;padding:14px 16px;background:#fbfaf7}
.caja.fina{border-width:2px}
.dash{border:2px dashed #a8a8a8;border-radius:12px;padding:12px 14px}
.chip{display:inline-block;border:2px solid #1b1b1b;border-radius:20px;padding:3px 12px;font-size:14px;margin-right:6px}
.chip.on{background:#1b1b1b;color:#fbfaf7}
.chip.sec{border:2px dashed #a8a8a8;color:#8a8a8a}
.fila{display:flex;align-items:center;gap:12px}
.entre{justify-content:space-between}
.col{display:flex;flex-direction:column;gap:10px}
.aviso{display:flex;gap:10px;align-items:flex-start;border-bottom:1px dashed #bdbdbd;padding:9px 0;font-size:14px}
.aviso i{flex:none;width:18px;height:18px;border:2px solid #1b1b1b;border-radius:4px;font-style:normal;font-size:11px;text-align:center;line-height:14px}
.circ{width:52px;height:52px;border:3px solid #1b1b1b;border-radius:50%;flex:none}
.item{display:flex;justify-content:space-between;align-items:center;border-bottom:2px dashed #cfcfcf;padding:10px 4px;font-size:18px}
.velo{position:absolute;inset:0;background:rgba(236,234,229,.72)}
.modal{position:absolute;background:#fbfaf7;border:4px solid #1b1b1b;border-radius:16px;padding:22px 26px}
.tab{display:inline-block;padding:6px 16px;font-size:15px}
.tab.on{background:#1b1b1b;color:#fbfaf7}
.digitos{display:flex;gap:10px}
.digitos span{width:48px;height:58px;border:3px solid #1b1b1b;border-radius:10px;font-size:28px;display:flex;align-items:center;justify-content:center}
.tabla{width:100%;border-collapse:collapse;font-size:14px}
.tabla td,.tabla th{border-bottom:2px dashed #cfcfcf;padding:7px 6px;text-align:left;font-weight:400}
.tabla th{color:#8a8a8a;font-size:12px}
.sel{background:#ecebe6}
"""

PAGINA = """<!doctype html><html><head><meta charset="utf-8"><style>{css}</style></head>
<body><div class="hoja" style="--w:{w}px;--h:{h}px"><div class="id"><b>{id}</b> · corregido</div>
<div class="pant">{cuerpo}</div></div></body></html>"""


def main(ids):
    from playwright.sync_api import sync_playwright
    with sync_playwright() as p:
        nav = p.chromium.launch(args=["--no-sandbox"])
        for pid, (w, h, cuerpo) in PANTALLAS.items():
            if ids and pid not in ids:
                continue
            html = AQUI / f"{pid}.html"
            html.write_text(PAGINA.format(css=CSS, w=w, h=h, id=pid, cuerpo=cuerpo), encoding="utf-8")
            pag = nav.new_page(viewport={"width": w, "height": h}, device_scale_factor=1)
            pag.goto(html.as_uri())
            pag.wait_for_timeout(250)
            pag.screenshot(path=str(SALIDA / f"{pid}.png"), clip={"x": 0, "y": 0, "width": w, "height": h})
            pag.close()
            print(pid)
        nav.close()


if __name__ == "__main__":
    main(sys.argv[1:])
