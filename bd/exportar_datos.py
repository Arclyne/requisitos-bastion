# -*- coding: utf-8 -*-
"""Convierte en tablas del documento los resultados de las consultas de la
sección Datos.

Ejecuta sobre la base Bastion ya cargada:
  - cada consulta de bd/consultas_datos.sql, marcada con -- @consulta;
  - bd/pruebas_rechazo.sql, que intenta operaciones prohibidas;
  - una consulta de cobertura que cuenta, para cada columna con valores
    fijos en una restricción CHECK, cuántas filas tiene cada valor.

Escribe en bd/tex/datos un .tex por resultado, un .sql con el texto de cada
consulta para los listados y datos-resumen.tex con las cifras.

Uso: python bd/exportar_datos.py [-S servidor]
Necesita sqlcmd y una cuenta de Windows con permiso de lectura en Bastion.
"""

import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

AQUI = Path(__file__).resolve().parent
SALIDA = AQUI / "tex" / "datos"
SQLCMD_OMISION = r"C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn\SQLCMD.EXE"
AVISO = "% Archivo generado por bd/exportar_datos.py. No editar a mano.\n"


def sqlcmd():
    return os.environ.get("SQLCMD") or shutil.which("sqlcmd") or SQLCMD_OMISION


def ejecutar(sql, servidor, separador="|"):
    """Ejecuta un lote y devuelve sus filas como listas de textos."""
    with tempfile.NamedTemporaryFile("w", suffix=".sql", encoding="utf-8", delete=False) as t:
        t.write("SET NOCOUNT ON;\n" + sql + "\n")
    try:
        r = subprocess.run([sqlcmd(), "-S", servidor, "-E", "-d", "Bastion", "-b", "-I", "-f", "65001",
                            # sqlcmd también toma por opción lo que empieza con "/"
                            "-W", "-h", "-1", "-s", separador, "-i", t.name.replace("/", "\\")], capture_output=True)
    finally:
        os.unlink(t.name)
    texto = r.stdout.decode("utf-8")
    if r.returncode:
        raise SystemExit(f"sqlcmd falló:\n{texto}\n{r.stderr.decode('utf-8', 'replace')}")
    return [l.split(separador) for l in texto.splitlines() if l.strip() and not l.startswith("Changed database context")]


def consultas():
    """Bloques de consultas_datos.sql: (nombre, título, encabezados, sql)."""
    texto = (AQUI / "consultas_datos.sql").read_text(encoding="utf-8-sig").replace("\r\n", "\n")
    bloques = []
    for trozo in re.split(r"^-- @consulta ", texto, flags=re.M)[1:]:
        cabecera, resto = trozo.split("\n", 1)
        nombre, titulo = [x.strip() for x in cabecera.split("|", 1)]
        m = re.match(r"-- @columnas (.*)\n", resto)
        encabezados = [x.strip() for x in m.group(1).split("|")]
        sql = resto[m.end():]
        sql = sql[:sql.rindex(";") + 1]
        bloques.append((nombre, titulo, encabezados, sql))
    return bloques


# ------------------------------------------------------------------ LaTeX
ESPECIALES = [("\\", r"\textbackslash{}"), ("&", r"\&"), ("%", r"\%"), ("$", r"\$"), ("#", r"\#"),
              ("{", r"\{"), ("}", r"\}"), ("~", r"\textasciitilde{}"), ("^", r"\textasciicircum{}")]


def tex(valor):
    if valor == "NULL":
        return r"\textit{NULL}"
    s = valor
    for a, b in ESPECIALES:
        s = s.replace(a, b)
    s = s.replace("_", "\\_\\allowbreak{}")
    if "@" in s or "/" in s:
        s = re.sub(r"([@/.])(?=\S)", r"\1\\allowbreak{}", s)
    return s


# Anchos aproximados de Computer Modern, en em, para repartir el ancho de la
# página entre las columnas sin que ninguna quede más estrecha que su palabra
# más larga.
ANCHO_TEXTO = 472.0          # \textwidth, en pt: carta con márgenes de 2.5 cm
SEPARACION = 2 * 2.0 + 0.4   # \tabcolsep a cada lado y la raya de la columna
EM = {**{c: 0.5 for c in "abcdeghknopquvxyz0123456789"}, **{c: 0.3 for c in "fijlrst"},
      "m": 0.83, "w": 0.72, " ": 0.33, ".": 0.28, ",": 0.28, ":": 0.28, ";": 0.28, "-": 0.33,
      "(": 0.39, ")": 0.39, "'": 0.28, "@": 0.75, "/": 0.5, "_": 0.5, "%": 0.83,
      "I": 0.36, "J": 0.51, "L": 0.63, "S": 0.56, "E": 0.68, "F": 0.65, "P": 0.68, "M": 0.92, "W": 1.03}
TAMANOS = [("\\footnotesize", 9.0), ("\\scriptsize", 8.0), ("\\tiny", 6.0)]


def ancho(texto, pt, negrita=False):
    """Ancho estimado en pt. Las fuentes pequeñas son proporcionalmente más anchas."""
    base = sum(EM.get(c, 0.77 if c.isupper() else 0.5) for c in texto)
    return base * pt * {9.0: 1.05, 8.0: 1.10, 6.0: 1.18}[pt] * (1.2 if negrita else 1.0)


def trozos(valor):
    """Partes de un valor que LaTeX no puede cortar."""
    partes = []
    for palabra in valor.split():
        corte = r"[_@/.]" if ("@" in palabra or "/" in palabra) else r"_"
        partes += re.findall(rf"[^_@/.]*{corte}|[^_@/.]+$", palabra) if re.search(corte, palabra) else [palabra]
    return partes or [valor]


def ancho_encabezado(palabra, pt):
    """Una palabra larga del encabezado puede partirse con guion por la mitad."""
    if len(palabra) <= 7:
        return ancho(palabra, pt, True)
    mitad = (len(palabra) + 1) // 2
    return max(ancho(palabra[:mitad] + "-", pt, True), ancho(palabra[mitad:], pt, True))


def anchos(encabezados, filas, pt):
    """Ancho de cada columna en pt, o None si no caben las palabras más largas."""
    n = len(encabezados)
    disponible = ANCHO_TEXTO - n * SEPARACION - 1.0
    minimo, natural = [], []
    for i, h in enumerate(encabezados):
        valores = [f[i] for f in filas]
        minimo.append(max([ancho(t, pt) for v in valores for t in trozos(v)]
                          + [ancho_encabezado(t, pt) for t in h.split()]) + 2.5)
        natural.append(max(minimo[-1], min(max(ancho(v, pt) for v in valores), 0.45 * disponible)))
    if sum(minimo) > disponible:
        return None
    sobra = disponible - sum(minimo)
    faltan = [a - b for a, b in zip(natural, minimo)]
    if sobra >= sum(faltan):
        extra = sobra - sum(faltan)
        return [a + extra * a / sum(natural) for a in natural]
    return [b + sobra * f / sum(faltan) for b, f in zip(minimo, faltan)]


def tabla_tex(encabezados, filas):
    """Tabla larga con anchos calculados para el contenido de cada columna."""
    n = len(encabezados)
    if not filas:
        return AVISO + "\\textit{La consulta no devuelve filas.}\n"
    for tamano, pt in TAMANOS[(0 if n <= 6 else 1):]:
        medidas = anchos(encabezados, filas, pt)
        if medidas:
            break
    else:
        raise SystemExit(f"las columnas {encabezados} no caben en la página")
    columnas = "|" + "|".join(f"L{{{a:.1f}pt}}" for a in medidas) + "|"
    # \hspace{0pt} deja que LaTeX parta con guion también la primera palabra de la celda
    cabecera = " & ".join(f"\\textbf{{\\hspace{{0pt}}{tex(h)}}}" for h in encabezados) + " \\\\ \\hline"
    lineas = [AVISO.rstrip(), f"\\begin{{center}}{tamano}\\setlength{{\\tabcolsep}}{{2pt}}",
              f"\\begin{{longtable}}{{{columnas}}}", "\\hline", cabecera, "\\endfirsthead",
              "\\hline", cabecera, "\\endhead"]
    lineas += [" & ".join(tex(v) for v in f) + " \\\\ \\hline" for f in filas]
    lineas += ["\\end{longtable}", "\\end{center}", ""]
    return "\n".join(lineas)


# ------------------------------------------------------------ cobertura
def cobertura(servidor):
    """Para cada columna con valores fijos en un CHECK, las filas de cada valor."""
    definiciones = ejecutar(
        "SELECT OBJECT_NAME(parent_object_id), CAST(REPLACE(REPLACE(definition, CHAR(13), ' '), CHAR(10), ' ') AS NVARCHAR(4000)) "
        "FROM sys.check_constraints", servidor)
    dominios = {}
    for tabla, definicion in definiciones:
        for columna, valor in re.findall(r"\[(\w+)\]='([^']*)'", definicion):
            dominios.setdefault((tabla, columna), [])
            if valor not in dominios[(tabla, columna)]:
                dominios[(tabla, columna)].append(valor)
    orden = [t["nombre"] for t in json.loads((AQUI.parent / "er" / "esquema.json").read_text(encoding="utf-8-sig"))]
    filas, completos, valores_total, valores_con_filas = [], 0, 0, 0
    for tabla, columna in sorted(dominios, key=lambda k: (orden.index(k[0]), k[1])):
        cuenta = {v: int(c) for v, c in ejecutar(
            f"SELECT ISNULL(CAST({columna} AS VARCHAR(40)), 'NULL'), COUNT(*) FROM dbo.{tabla} GROUP BY {columna}", servidor)}
        dominio = dominios[(tabla, columna)]
        presentes = [f"{v} ({cuenta[v]})" for v in dominio if v in cuenta]
        if "NULL" in cuenta:
            presentes.append(f"NULL ({cuenta['NULL']})")
        faltan = [v for v in dominio if v not in cuenta]
        valores_total += len(dominio)
        valores_con_filas += len(dominio) - len(faltan)
        completos += not faltan
        filas.append([f"{tabla}.{columna}", ", ".join(presentes) or "NULL", ", ".join(faltan) or "—"])
    return filas, dict(dnNumDominios=len(filas), dnNumDominiosCompletos=completos,
                       dnNumValores=valores_total, dnNumValoresConFilas=valores_con_filas)


def main():
    servidor = sys.argv[sys.argv.index("-S") + 1] if "-S" in sys.argv else "localhost"
    SALIDA.mkdir(parents=True, exist_ok=True)
    macros = {}
    for nombre, titulo, encabezados, sql in consultas():
        filas = ejecutar(sql, servidor)
        if any(len(f) != len(encabezados) for f in filas):
            raise SystemExit(f"{nombre}: la consulta no devuelve {len(encabezados)} columnas")
        (SALIDA / f"{nombre}.sql").write_text(sql.strip() + "\n", encoding="utf-8")
        (SALIDA / f"{nombre}.tex").write_text(tabla_tex(encabezados, filas), encoding="utf-8")
        print(f"{nombre:20} {len(filas):4} filas  {titulo}")
    rechazos = ejecutar((AQUI / "pruebas_rechazo.sql").read_text(encoding="utf-8-sig").replace("USE Bastion;\nGO\n", ""), servidor)
    (SALIDA / "rechazos.tex").write_text(
        tabla_tex(["Núm.", "Operación que se intenta", "Regla", "Error", "Rechazada por"], rechazos), encoding="utf-8")
    macros["dnNumPruebasRechazo"] = len(rechazos)
    macros["dnNumPruebasRechazadas"] = sum(1 for f in rechazos if f[3] != "0")
    print(f"{'rechazos':20} {len(rechazos):4} filas")
    filas, cifras = cobertura(servidor)
    (SALIDA / "cobertura.tex").write_text(
        tabla_tex(["Columna", "Valores con filas (filas)", "Valores sin filas"], filas), encoding="utf-8")
    macros.update(cifras)
    print(f"{'cobertura':20} {len(filas):4} filas")
    (SALIDA / "datos-resumen.tex").write_text(
        AVISO + "".join(f"\\newcommand{{\\{k}}}{{{v}}}\n" for k, v in macros.items()), encoding="utf-8")


if __name__ == "__main__":
    main()
