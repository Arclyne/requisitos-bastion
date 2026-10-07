"""kit.py · base neutra para lienzos de prototipos (Claude Design). Sin estilo de juego:
el estilo va en THEME y en las funciones header()/navbar() que define cada juego."""
import json, os, re, datetime, glob
from playwright.sync_api import sync_playwright

THEME = {"bg": "#F2F4F7", "surf": "#FFFFFF", "line": "#D9E0E8", "ink": "#16202C", "ink2": "#465160", "muted": "#687382",
         "acc": "#2F6FDE", "navy": "#10233F", "hf": "sans-serif", "bf": "sans-serif", "fonts_link": "", "fonts_local_css": ""}
ANN = "#C026D3"                      # color de anotación (marcas, flechas, cursor): no es del juego
ICONS = {"cursor": '<path d="M5 3l14 8-6 2-2 6z"></path>', "tap": '<circle cx="12" cy="12" r="4"></circle><circle cx="12" cy="12" r="8"></circle>',
         "arrowR": '<path d="M4 12h15"></path><path d="M13 6l6 6-6 6"></path>'}


def T(k):
    return THEME[k]


def icon(n, s=24, c="currentColor", sw=2):
    return (f'<svg width="{s}" height="{s}" viewBox="0 0 24 24" fill="none" stroke="{c}" stroke-width="{sw}" stroke-linecap="round" '
            f'stroke-linejoin="round" aria-hidden="true" style="flex-shrink: 0;">{ICONS[n]}</svg>')


# ---------- piezas del lienzo (anotación, no juego) ----------
def mk(n, pos="top: -4px; left: -42px;"):
    return (f'<div style="position: absolute; {pos} width: 28px; height: 28px; border-radius: 14px; background: {ANN}; color: #FFFFFF; font: 800 14px {T("hf")}; '
            f'display: flex; align-items: center; justify-content: center; box-shadow: 0 0 0 3px #FFFFFF; z-index: 7;">{n}</div>')


def rel(inner, n, pos="top: -4px; left: -42px;", extra=""):
    return f'<div style="position: relative; {extra}">{mk(n, pos)}{inner}</div>'


def label(t):
    return f'<div style="font: 700 13px {T("bf")}; color: {ANN}; text-transform: uppercase; letter-spacing: 0.8px;">{t}</div>'


def sheet_title(t, sub=""):
    s = f'<div style="font: 600 16px {T("bf")}; color: {T("ink2")}; margin-top: 4px;">{sub}</div>' if sub else ""
    return f'<div><div style="font: 800 30px {T("hf")}; color: {T("ink")};">{t}</div>{s}</div>'


def state_block(lbl, inner):
    return f'<div style="display: flex; flex-direction: column; gap: 12px;">{label(lbl)}{inner}</div>'


def cap(inner, t, w=250):
    return f'<div style="display: flex; flex-direction: column; gap: 8px; align-items: flex-start;">{inner}<span style="font: 700 13px {T("bf")}; color: {T("ink2")}; width: {w}px;">{t}</span></div>'


def step(lbl, inner):
    return f'<div style="display: flex; flex-direction: column; gap: 10px; position: relative;">{label(lbl)}{inner}</div>'


def hoja(titulo, contenido, sub=""):
    """Tablero de partes o de concepto: margen de 48 px, título y contenido en columna."""
    return (f'<div style="padding: 48px; display: flex; flex-direction: column; gap: 32px; box-sizing: border-box;">'
            f'{sheet_title(titulo, sub)}{contenido}</div>')


def pasos(*items):
    """Fila de pasos de un concepto: step(...), step_arrow(), step(...)…"""
    return f'<div style="display: flex; align-items: center;">{"".join(items)}</div>'


def step_arrow():
    return f'<div style="display: flex; align-items: center; justify-content: center; width: 48px; flex-shrink: 0;">{icon("arrowR", 32, ANN, 2.5)}</div>'


def cursor_at(pos, kind="cursor"):
    """kind: cursor (mouse) | tap (dedo). pos en coordenadas del contenedor relativo."""
    return f'<div aria-hidden="true" style="position: absolute; {pos} z-index: 8; pointer-events: none;">{icon(kind, 30, ANN, 2.2)}</div>'


def path(d, w, h):
    """Trayectoria de algo que se mueve: línea discontinua de anotación (SVG path d)."""
    return f'<svg width="{w}" height="{h}" aria-hidden="true" style="position: absolute; inset: 0;"><path d="{d}" stroke="{ANN}" stroke-width="2.5" stroke-dasharray="7 6" fill="none"></path></svg>'


def note_box(t, extra=""):
    return f'<div style="padding: 10px 12px; border-radius: 10px; background: #FBEAFD; color: #6B1476; font: 600 14px {T("bf")}; box-sizing: border-box; {extra}">{t}</div>'


def roblox_box(t, sub="Lo dibuja Roblox, no el juego", w=300, h=200):
    return (f'<div style="width: {w}px; height: {h}px; box-sizing: border-box; border: 2px dashed {T("line")}; border-radius: 16px; background: rgba(255,255,255,0.7); '
            f'display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 6px; text-align: center; padding: 16px;">'
            f'<span style="font: 800 16px {T("hf")}; color: {T("ink")};">{t}</span><span style="font: 600 13px {T("bf")}; color: {T("ink2")};">{sub}</span></div>')


def float_bottom(html, bottom=122):
    """Aviso flotante encima de la barra de navegación (va en overlay)."""
    return f'<div style="position: absolute; left: 0; right: 0; bottom: {bottom}px; display: flex; justify-content: center; z-index: 6;">{html}</div>'


def scrim_modal(inner):
    return f'<div style="position: absolute; inset: 0; z-index: 6; background: rgba(10,20,40,0.45); display: flex; align-items: center; justify-content: center;">{inner}</div>'


def at(html, x, y, z=6):
    """Cualquier cosa en coordenadas de pantalla dentro de un overlay."""
    return f'<div style="position: absolute; left: {x}px; top: {y}px; z-index: {z};">{html}</div>'


def artboard(title, w, h, body):
    fl = T("fonts_link")
    return f'''<!doctype html>
<html lang="es">
<head>
<meta charset="utf-8">
<title>{title}</title>
<script src="./support.js"></script>
</head>
<body>
<x-dc>
<helmet>
{fl}
<style>body{{margin:0;background:{T("bg")}}}</style>
</helmet>
<div style="position: relative; width: {w}px; height: {h}px; overflow: hidden; background: {T("bg")}; font-family: {T("bf")}; color: {T("ink")};">
{body}
</div>
</x-dc>
<script type="text/x-dc" data-dc-script data-props='{{"$preview":{{"width":{w},"height":{h}}}}}'>
class Component extends DCLogic {{
  renderVals() {{
    return {{}};
  }}
}}
</script>
</body>
</html>
'''


def local(src):
    """HTML del artboard listo para Playwright: sin support.js ni x-dc y con fuentes locales."""
    src = src.replace('<script src="./support.js"></script>', '')
    src = re.sub(r'<script type="text/x-dc".*?</script>', '', src, flags=re.S).replace('<helmet>', '').replace('</helmet>', '')
    if T("fonts_local_css"):
        src = re.sub(r'<link rel="stylesheet" href="https://fonts.googleapis[^>]*>', f'<style>{T("fonts_local_css")}</style>', src)
    return src


# ---------- marcos de pantalla ----------
def page(header, navbar, column, w=1280, col_w=1040, gap=36):
    """Bloque 1: la sección completa sin recortar. header/navbar: HTML del juego."""
    return (f'<div style="display: flex; flex-direction: column; width: {w}px;">{header}'
            f'<main style="padding: 24px {(w - col_w) // 2}px 12px; display: flex; flex-direction: column; gap: {gap}px; box-sizing: border-box;">{column}</main>{navbar}</div>')


def viewport(W, H, scroll, column, header, navbar, overlay="", scale=1.0, safe=(0, 0), nav_extra="", gap=24):
    """Pantalla real: encabezado y barra fijos, contenido recortado y desplazado `scroll` px, overlay encima de todo."""
    sx, sy = safe
    inner = (f'<div style="position: relative; width: {W}px; height: {H}px; overflow: hidden; display: flex; flex-direction: column;">'
             f'<div style="position: relative; z-index: 2; flex-shrink: 0; padding: {sy}px {sx}px 0;">{header}</div>'
             f'<div style="position: relative; z-index: 1; flex-grow: 1; min-height: 0; overflow: hidden; display: flex; flex-direction: column; align-items: center;">'
             f'<div style="margin-top: {-scroll}px; flex-shrink: 0; display: flex; flex-direction: column; gap: {gap}px; padding-top: 12px;">{column}</div></div>'
             f'<div style="position: relative; z-index: 2; flex-shrink: 0; padding: 0 {sx}px {sy}px;">{nav_extra}{navbar}</div>{overlay}</div>')
    return inner if scale == 1.0 else f'<div style="width: {W}px; height: {H}px; zoom: {scale};">{inner}</div>'


PHONE = {"w": 800, "h": 360, "left": 47, "right": 48, "bottom": 22}      # Galaxy A06 horizontal


def phone_guides(p=PHONE):
    d = f"1.5px dashed {ANN}"
    return (f'<div style="position: absolute; left: {p["left"]}px; top: 0; bottom: 0; border-left: {d}; z-index: 8;"></div>'
            f'<div style="position: absolute; right: {p["right"]}px; top: 0; bottom: 0; border-left: {d}; z-index: 8;"></div>'
            f'<div style="position: absolute; left: 0; right: 0; bottom: {p["bottom"]}px; border-top: {d}; z-index: 8;"></div>'
            f'<div style="position: absolute; right: {p["right"] + 6}px; bottom: {p["bottom"] + 4}px; padding: 0 4px; background: #FFFFFF; font: 700 10px {T("bf")}; color: {ANN}; z-index: 8;">zona segura</div>')


def phone(header, content, navbar, overlay="", p=PHONE, head_h=56, nav_h=56):
    """Celular: todo dentro de la zona segura. header/navbar/content: versiones ADAPTADAS, no encogidas.
    Solo para una GUI que de verdad es de pantalla completa; si no, la GUI va dentro de en_juego(..., "cel")."""
    L, R, B = p["left"], p["right"], p["bottom"]
    return (phone_guides(p)
            + f'<div style="position: absolute; left: {L}px; right: {R}px; top: 0; height: {head_h}px; z-index: 3;">{header}</div>'
            + f'<div style="position: absolute; left: {L}px; right: {R}px; top: {head_h}px; bottom: {B + nav_h}px; overflow: hidden; padding: 6px 16px; box-sizing: border-box; display: flex; flex-direction: column; gap: 8px; z-index: 1;">{content}</div>'
            + f'<div style="position: absolute; left: {L}px; right: {R}px; bottom: {B}px; height: {nav_h}px; z-index: 3;">{navbar}</div>' + overlay)


def tv(view_html, logical=(1422, 800)):
    """TV 1920x1080: vista lógica de 1422x800 escalada x1.35 + guía del 5 % de zona segura.
    view_html = f'<div style="width: 1422px; height: 800px; zoom: 1.35;">{en_juego(1422, 800, ..., "tv", chat=False)}</div>'."""
    x5, y5 = 96, 54
    return (f'<div style="position: relative; width: 1920px; height: 1080px;">{view_html}'
            f'<div style="position: absolute; left: {x5}px; top: {y5}px; right: {x5}px; bottom: {y5}px; border: 2px dashed {ANN}; z-index: 9;"></div>'
            f'<div style="position: absolute; right: {x5 + 8}px; bottom: {y5 + 8}px; padding: 2px 8px; border-radius: 6px; background: #FFFFFF; font: 700 14px {T("bf")}; color: {ANN}; z-index: 9;">zona segura de TV (5 % por lado)</div></div>')


def anchor(html):
    """Marca el elemento al que debe apuntar el scroll de una vista real."""
    return f'<div data-a="1">{html}</div>'


# ---------- la GUI dentro del juego (proporción real) ----------
INSET = 58   # alto de la barra superior de Roblox (GuiService:GetGuiInset() con la barra actual); verificar en el place


def game_bg(W, H):
    """Mundo del juego de referencia, neutro: cielo, suelo y siluetas de avatares. No es del juego ni lleva su estilo."""
    avs = ""
    for x, f in [(0.12, 1.0), (0.27, 0.8), (0.46, 1.1), (0.63, 0.9), (0.8, 0.75), (0.92, 1.0)]:
        s = int(H * 0.13 * f); xx = int(W * x); yy = int(H * 0.74) - s
        avs += (f'<span style="position: absolute; left: {xx}px; top: {yy}px; width: {int(s * 0.46)}px; height: {s}px; '
                f'border-radius: {int(s * 0.23)}px {int(s * 0.23)}px 6px 6px; background: rgba(40,55,80,0.28);"></span>')
    return (f'<div aria-hidden="true" style="position: absolute; inset: 0; overflow: hidden; background: linear-gradient(180deg, #C9D8E6 0%, #E4ECF3 64%, #B9C4CF 64%, #A9B5C1 100%);">{avs}'
            f'<span style="position: absolute; left: 50%; bottom: 8px; transform: translateX(-50%); font: 700 12px {T("bf")}; color: rgba(20,35,55,0.5); white-space: nowrap;">mundo del juego (referencia)</span></div>')


def _rbx(x, y, w, h, t, r=12, pos="left"):
    """Pieza que dibuja Roblox (CoreGui): gris oscuro translúcido como en el juego, con su nombre."""
    return (f'<div style="position: absolute; {pos}: {x}px; top: {y}px; width: {w}px; height: {h}px; box-sizing: border-box; border-radius: {r}px; '
            f'background: rgba(18,24,34,0.55); border: 1.5px dashed rgba(255,255,255,0.55); display: flex; align-items: center; justify-content: center; '
            f'color: rgba(255,255,255,0.9); font: 700 11px {T("bf")}; text-align: center; line-height: 1.15; padding: 2px; z-index: 5;">{t}</div>')


def roblox_chrome(W, H, kind="pc", chat=True, lista=False, touch=False, safe=(0, 0, 0)):
    """Lo que Roblox dibuja siempre encima de las GUI del juego. kind: pc | cel | tv. safe = (izq, der, abajo) del celular."""
    L, R, B = safe
    b = 44 if kind != "tv" else 52
    y0 = (INSET - b) // 2
    out = (_rbx(L + 12, y0, b, b, "Menú", b // 2) + (_rbx(L + 20 + b, y0, b, b, "Chat", b // 2) if kind != "tv" else "")
           + _rbx(R + 12, y0, b, b, "Más", b // 2, "right"))
    if chat and kind == "pc":
        out += _rbx(12, INSET + 6, 380, 210, "Ventana del chat<br>(Roblox · encima de tu GUI)")
    if lista:
        out += _rbx(12, INSET + 6, 200, 240, "Lista de jugadores<br>(Roblox)", 12, "right")
    if touch:
        out += (f'<div style="position: absolute; left: {L + 40}px; bottom: {B + 26}px; width: 110px; height: 110px; border-radius: 55px; border: 1.5px dashed rgba(255,255,255,0.7); '
                f'background: rgba(18,24,34,0.35); z-index: 5; display: flex; align-items: center; justify-content: center; color: #FFFFFF; font: 700 11px {T("bf")};">Joystick</div>'
                + _rbx(R + 30, H - B - 26 - 84, 84, 84, "Salto", 42, "right"))
    return f'<div aria-hidden="true" style="position: absolute; inset: 0; z-index: 5; pointer-events: none;">{out}</div>'


def cobertura(W, H, gw, gh, extra=""):
    """Etiqueta de anotación: cuánto de la pantalla ocupa la GUI."""
    return (f'<span style="display: inline-flex; padding: 3px 10px; border-radius: 8px; background: {ANN}; color: #FFFFFF; font: 700 13px {T("bf")}; white-space: nowrap;">'
            f'Cubre {round(gw * 100 / W)} % del ancho × {round(gh * 100 / H)} % del alto{extra}</span>')


def en_juego(W, H, gui, x, y, gw, gh, kind="pc", chat=True, lista=False, touch=False, safe=(0, 0, 0), dim=0.0, label=True, overlay="", label_at=None):
    """Pantalla real del juego: mundo de fondo, la GUI a su tamaño y posición reales, y encima lo que dibuja Roblox.
    gui = HTML de la GUI ya del tamaño gw×gh. overlay = cosas en coordenadas de pantalla (teclado, anotaciones)."""
    d = f'<div style="position: absolute; inset: 0; background: rgba(10,20,40,{dim}); z-index: 1;"></div>' if dim else ""
    lx, ly = label_at or ((x, y + gh + 6) if y + gh + 30 < H else (x, max(0, y - 28)))
    lab = f'<div style="position: absolute; left: {lx}px; top: {ly}px; z-index: 9;">{cobertura(W, H, gw, gh)}</div>' if label else ""
    return (f'<div style="position: relative; width: {W}px; height: {H}px; overflow: hidden;">{game_bg(W, H)}{d}'
            f'<div style="position: absolute; left: {x}px; top: {y}px; width: {gw}px; height: {gh}px; z-index: 2;">{gui}</div>'
            f'{roblox_chrome(W, H, kind, chat, lista, touch, safe)}{lab}{overlay}</div>')


def ventana(gw, gh, inner, r=20, bg=None):
    """La GUI como ventana: esquinas, sombra y fondo; recorta su contenido como un Frame con ClipsDescendants."""
    return (f'<div style="position: relative; width: {gw}px; height: {gh}px; border-radius: {r}px; overflow: hidden; background: {bg or T("bg")}; '
            f'box-shadow: 0 18px 48px rgba(10,20,40,0.35), 0 0 0 1px rgba(10,20,40,0.08);">{inner}</div>')


# ---------- el lienzo ----------
class Canvas:
    NOTE_W = 460

    def __init__(self, root, title):
        self.root = root; self.title = title
        os.makedirs(root, exist_ok=True)
        self.files = {}; self.boards = {}; self.order = []; self.notes = {}
        self.pw = sync_playwright().start(); self.br = self.pw.chromium.launch()

    def _html(self, w, body, h=9000):
        return local(artboard("m", w, h, body))

    def measure(self, w, body):
        """Alto real de un contenido de ancho w."""
        tmp = self.root + "/../_m.html"
        open(tmp, "w").write(self._html(w, f'<div data-m="1">{body}</div>'))
        pg = self.br.new_page(viewport={"width": w, "height": 900}); pg.goto("file://" + os.path.abspath(tmp)); pg.wait_for_timeout(150)
        h = pg.evaluate("() => document.querySelector('[data-m]').getBoundingClientRect().height"); pg.close()
        return int(h) + 2

    def anchor_scroll(self, column, col_w=1040, gap=24, lead=12, view_h=None):
        """Cuánto bajar para que el elemento dentro de anchor(...) quede arriba con `lead` px de margen.
        view_h = alto visible del área de contenido: el scroll no pasa del final (como un ScrollingFrame)."""
        tmp = self.root + "/../_a.html"
        open(tmp, "w").write(self._html(1400, f'<div data-w="1" style="display: flex; flex-direction: column; gap: {gap}px; width: {col_w}px;">{column}</div>'))
        pg = self.br.new_page(viewport={"width": 1400, "height": 900}); pg.goto("file://" + os.path.abspath(tmp)); pg.wait_for_timeout(120)
        top, total = pg.evaluate("() => { const w = document.querySelector('[data-w]').getBoundingClientRect(); return [document.querySelector('[data-a]').getBoundingClientRect().top - w.top, w.height]; }")
        pg.close()
        s = max(0, int(top) - lead)
        return s if view_h is None else min(s, max(0, int(total) + 12 - view_h))

    def board(self, name, title, w, body, h=None, strip=None):
        """name sin extensión. h=None → se mide. strip = título que se ve en el lienzo."""
        h = h or self.measure(w, body)
        self.files[name + ".dc.html"] = (artboard(title, w, h, body), w, h, strip or title)

    def place(self, name, x, y):
        _, w, h, t = self.files[name + ".dc.html"]
        self.boards[name + ".dc.html"] = {"x": x, "y": y, "w": w, "h": h, "title": t}; self.order.append(name + ".dc.html")

    def sticky(self, id_, x, y, text):
        self.notes[id_] = {"x": x, "y": y, "text": text, "w": self.NOTE_W, "maxH": 1400, "color": "pink", "size": "m"}

    def heading(self, id_, x, y, text, max_w):
        self.notes[id_] = {"x": x, "y": y, "text": text, "kind": "title1", "maxW": max_w}

    def row(self, names, y, notes, w=None):
        """Coloca una fila de tableros, cada uno con su nota a 80 px a la derecha. Devuelve el y del borde de abajo."""
        x = 0
        for n in names:
            bw = w or self.files[n + ".dc.html"][1]
            self.place(n, x, y); self.sticky("n_" + n, x + bw + 80, y, notes[n]); x += bw + 80 + self.NOTE_W + 120
        return y + max(self.files[n + ".dc.html"][2] for n in names)

    def block(self, id_, y, text, names_rows, notes, gap_rows=200):
        """Bloque con título: 300 px de aire arriba, filas separadas 200 px. Devuelve el y siguiente."""
        y += 300; self.heading(id_, 0, y - 300, text, 6000)
        for r in names_rows:
            y = self.row(r, y, notes) + gap_rows
        return y - gap_rows + 120

    def write(self, swap=lambda s: s):
        """Escribe project/*.dc.html y canvas.json. swap = función que cambia iconos por /_blob/… (assets)."""
        missing = set(self.files) - set(self.boards)
        assert not missing, f"tableros sin colocar: {missing}"
        for n, (src, *_rest) in self.files.items():
            open(os.path.join(self.root, n), "w").write(swap(src))
        canvas = {"v": 3, "createdOnFiles": {"v": 1, "at": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")},
                  "title": self.title, "launch": {"view": "canvas"}, "pages": [], "boards": self.boards, "order": self.order,
                  "notes": self.notes, "designSystems": []}
        open(os.path.join(self.root, "canvas.json"), "w").write(json.dumps(canvas, ensure_ascii=False, indent=1))
        return {"project/" + n: "project/" + n for n in self.files}      # mapa `files` para publicar

    def render(self, names=None, out=None, to_local=lambda s: s):
        """Renderiza a PNG y hace las comprobaciones automáticas. Después HAY QUE MIRAR las imágenes."""
        out = out or os.path.join(self.root, "..", "r"); os.makedirs(out, exist_ok=True)
        report = {}
        for f in sorted(glob.glob(self.root + "/*.dc.html")):
            n = os.path.basename(f)[:-8]
            if names and n not in names:
                continue
            src = open(f).read(); m = re.search(r'width: (\d+)px; height: (\d+)px', src); w, h = int(m[1]), int(m[2])
            tmp = out + "/_r.html"; open(tmp, "w").write(to_local(local(src)))
            pg = self.br.new_page(viewport={"width": w, "height": h}); pg.goto("file://" + os.path.abspath(tmp)); pg.wait_for_timeout(300)
            report[n] = pg.evaluate("""() => ({
              anidados: document.querySelectorAll('button button, button a, a button, a a').length,
              fuera_derecha: [...document.querySelectorAll('body *')].filter(e => { const r = e.getBoundingClientRect(); return r.width > 0 && r.right > innerWidth + 1; }).length,
              texto_cortado: [...document.querySelectorAll('body *')].filter(e => getComputedStyle(e).textOverflow === 'ellipsis' && e.scrollWidth > e.clientWidth + 1).map(e => e.textContent.trim().slice(0, 40))
            })""")
            pg.screenshot(path=f"{out}/{n}.png"); pg.close()
        return report

    def close(self):
        self.br.close(); self.pw.stop()
