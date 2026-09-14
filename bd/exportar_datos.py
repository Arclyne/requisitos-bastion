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


def tabla_tex(encabezados, filas):
    """Tabla larga con anchos proporcionales al contenido de cada columna."""
    n = len(encabezados)
    if not filas:
        return AVISO + "\\textit{La consulta no devuelve filas.}\n"
    necesidad = []
    for i, h in enumerate(encabezados):
        valores = [len(f[i]) if f[i] != "NULL" else 4 for f in filas]
        palabra = max(len(p) for p in h.split())
        necesidad.append(max(3, 0.8 * palabra, min(max(valores), 42)))
    disponible = 0.985 - n * 0.0135 - (n + 1) * 0.001
    anchos = [disponible * x / sum(necesidad) for x in necesidad]
    columnas = "|" + "|".join(f"L{{{a:.3f}\\linewidth}}" for a in anchos) + "|"
    tamano = "\\scriptsize" if n >= 7 else "\\footnotesize"
    cabecera = " & ".join(f"\\textbf{{{tex(h)}}}" for h in encabezados) + " \\\\ \\hline"
    lineas = [AVISO.rstrip(), f"\\begin{{center}}{tamano}\\setlength{{\\tabcolsep}}{{3pt}}",
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
