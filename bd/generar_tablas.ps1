# Genera las tablas del modelo de datos del documento a partir de bd/bastion.sql,
# para que el documento y el script no puedan contradecirse.
#
# Uso, desde la raíz del repositorio:
#     powershell -ExecutionPolicy Bypass -File bd\generar_tablas.ps1
#
# Lee del script:
#   -- @entidad Nombre | descripción      antes de cada CREATE TABLE
#   -- @fn texto                          observación de normalización ("[3FN]" si no llega a FNBC)
#   columna TIPO ... ,  -- descripción    una columna por línea
#   CONSTRAINT ... PRIMARY KEY / UNIQUE / FOREIGN KEY ...  -- [cardinalidad |] descripción
#   CREATE UNIQUE INDEX ... WHERE ...;  -- descripción
# En las descripciones, `x` se escribe como código y *X* en cursiva.
param(
    [string]$Sql = (Join-Path $PSScriptRoot 'bastion.sql'),
    [string]$Salida = (Join-Path $PSScriptRoot 'tex')
)
$ErrorActionPreference = 'Stop'
$utf8 = New-Object System.Text.UTF8Encoding($false)
if (-not (Test-Path $Salida)) { New-Item -ItemType Directory -Path $Salida | Out-Null }

#---------------------------------------------------------------------
# Conversión de texto a LaTeX
#---------------------------------------------------------------------
function TexCodigo([string]$s) { '\texttt{' + $s.Replace('_', '\_\allowbreak{}') + '}' }

function Tex([string]$s) {
    $partes = $s.Split('`')
    $sb = New-Object System.Text.StringBuilder
    for ($i = 0; $i -lt $partes.Length; $i++) {
        $p = $partes[$i]
        if ($i % 2 -eq 1) { [void]$sb.Append((TexCodigo $p)); continue }
        $p = $p.Replace('\', '\textbackslash{}').Replace('&', '\&').Replace('%', '\%').Replace('#', '\#').Replace('$', '\$')
        $p = $p.Replace('->', '$\rightarrow$')
        $p = [regex]::Replace($p, '\*([A-Za-z]+)\*', '\textit{$1}')
        $p = [regex]::Replace($p, '\b[a-z][a-z0-9]*(?:_[a-z0-9]+)+\b',
            [System.Text.RegularExpressions.MatchEvaluator]{ param($m) TexCodigo $m.Value })
        $p = [regex]::Replace($p, '\b(?:CU|RN|FA|EX|PRE|POST|CON|D)-\d{2}\b',
            [System.Text.RegularExpressions.MatchEvaluator]{ param($m) '\mbox{' + $m.Value + '}' })
        [void]$sb.Append($p)
    }
    $sb.ToString()
}

function Cols([string]$s) { @($s -split ',\s*' | ForEach-Object { $_.Trim() } | Where-Object { $_ }) }
function TexCols($cols) { '(' + ((@($cols) | ForEach-Object { TexCodigo $_ }) -join ', ') + ')' }
function Ent([string]$n) { '\textit{' + [regex]::Replace($n, '(?<=[a-z])(?=[A-Z])', '\-') + '}' }

#---------------------------------------------------------------------
# Lectura del script
#---------------------------------------------------------------------
$tablas = New-Object System.Collections.Specialized.OrderedDictionary
$area = $null; $descPend = $null; $fnPend = $null; $actual = $null

function NuevaFk($tabla, $nombre, $cols, $ref, $refCols, $comentario) {
    $card = '1:N'; $texto = $comentario
    if ($comentario -match '^(\S+) \| (.*)$') { $card = $matches[1]; $texto = $matches[2] }
    [pscustomobject]@{ Tabla = $tabla; Nombre = $nombre; Cols = @(Cols $cols); Ref = $ref; RefCols = @(Cols $refCols); Card = $card; Texto = $texto }
}

foreach ($l in [IO.File]::ReadAllLines($Sql, [Text.Encoding]::UTF8)) {
    if ($l -match '^  \d+\. (.+)$') { $area = $matches[1].Trim(); continue }
    if ($l -match '^-- @entidad (\w+) \| (.+)$') { $descPend = $matches[2]; $fnPend = $null; continue }
    if ($l -match '^-- @fn (.+)$') { $fnPend = $matches[1]; continue }
    if ($l -match '^CREATE TABLE dbo\.(\w+) \($') {
        $actual = [pscustomobject]@{
            Nombre = $matches[1]; Area = $area; Desc = $descPend; Fn = $fnPend
            Columnas = New-Object System.Collections.ArrayList
            Pk = @(); Uq = New-Object System.Collections.ArrayList
            Fk = New-Object System.Collections.ArrayList; UqIdx = New-Object System.Collections.ArrayList
        }
        $tablas[$actual.Nombre] = $actual
        continue
    }
    if ($l -match '^ALTER TABLE dbo\.(\w+) ADD CONSTRAINT (\w+) FOREIGN KEY \(([^)]*)\) REFERENCES dbo\.(\w+) \(([^)]*)\);\s+--\s(.*)$') {
        [void]$tablas[$matches[1]].Fk.Add((NuevaFk $matches[1] $matches[2] $matches[3] $matches[4] $matches[5] $matches[6]))
        continue
    }
    if ($l -match '^CREATE UNIQUE INDEX (\w+) ON dbo\.(\w+) \(([^)]*)\) WHERE (.+?);\s+--\s(.*)$') {
        [void]$tablas[$matches[2]].UqIdx.Add([pscustomobject]@{ Nombre = $matches[1]; Cols = @(Cols $matches[3]); Filtro = $matches[4]; Desc = $matches[5] })
        continue
    }
    if (-not $actual) { continue }
    if ($l -match '^\);') { $actual = $null; continue }

    $def = $l; $comentario = ''
    $k = $l.IndexOf(' -- ')
    if ($k -ge 0) { $def = $l.Substring(0, $k); $comentario = $l.Substring($k + 4).Trim() }
    $def = $def.Trim().TrimEnd(',').Trim()

    if ($def -match '^CONSTRAINT \w+ PRIMARY KEY \(([^)]*)\)') { $actual.Pk = @(Cols $matches[1]); continue }
    if ($def -match '^CONSTRAINT (\w+) UNIQUE \(([^)]*)\)') {
        [void]$actual.Uq.Add([pscustomobject]@{ Nombre = $matches[1]; Cols = @(Cols $matches[2]); Desc = $comentario }); continue
    }
    if ($def -match '^CONSTRAINT (\w+) FOREIGN KEY \(([^)]*)\) REFERENCES dbo\.(\w+) \(([^)]*)\)') {
        [void]$actual.Fk.Add((NuevaFk $actual.Nombre $matches[1] $matches[2] $matches[3] $matches[4] $comentario)); continue
    }
    if ($def -notmatch '^([a-z][a-z0-9_]*)\s+(INT|SMALLINT|TINYINT|BIGINT|BIT|DATE|DATETIME2|VARCHAR|NVARCHAR|CHAR|VARBINARY|DECIMAL|AS)\b(.*)$') { continue }

    $col = [pscustomobject]@{ Nombre = $matches[1]; Tipo = ''; Nulo = ''; Calculada = $false; Desc = $comentario }
    if ($matches[2] -eq 'AS') {
        $col.Tipo = 'calculada'; $col.Nulo = '---'; $col.Calculada = $true
    } else {
        $resto = $matches[2] + $matches[3]
        $identidad = $resto -match 'IDENTITY'
        $col.Nulo = if ($resto -match '\bNOT NULL\b') { 'No' } else { 'Sí' }
        if ($resto -match 'DEFAULT \((.*)\)\s*$') {
            $v = $matches[1]
            if ($v -eq 'SYSUTCDATETIME()') { $col.Desc += ' Por omisión, la fecha actual.' }
            else { $v = $v.Trim('(', ')').Trim("'"); $col.Desc += " Por omisión, ``$v``." }
        }
        $tipo = ($resto -replace '\s+IDENTITY\(1,1\)', '' -replace '\s+COLLATE \S+', '' -replace '\s+(NOT )?NULL.*$', '').Trim()
        $col.Tipo = (TexCodigo $tipo) + $(if ($identidad) { ', identidad' } else { '' })
    }
    [void]$actual.Columnas.Add($col)
}

#---------------------------------------------------------------------
# Datos derivados
#---------------------------------------------------------------------
function ColsFk($t) { @($t.Fk | ForEach-Object { $_.Cols }) }

function TipoEntidad($t) {
    $fkCols = ColsFk $t
    $pkEnFk = @($t.Pk | Where-Object { $fkCols -contains $_ })
    if ($t.Area -like 'Catálogos*') {
        if ($t.Pk.Count -ge 2) { return 'Catálogo asociativo' } else { return 'Catálogo' }
    }
    if ($t.Pk.Count -ge 2 -and $pkEnFk.Count -eq $t.Pk.Count) { return 'Asociativa (N:M)' }
    if ($t.Pk.Count -ge 2) { return 'Débil' }
    if ($pkEnFk.Count -eq 1) { return 'Dependiente (1:0..1)' }
    return 'Fuerte'
}

function ClaseLlave($t) {
    if ($t.Pk.Count -ge 2) { return 'Compuesta' }
    $c = $t.Columnas | Where-Object { $_.Nombre -eq $t.Pk[0] }
    if ($c.Tipo -like '*identidad') { return 'Simple, sustituta' }
    if ((ColsFk $t) -contains $t.Pk[0]) { return 'Simple, igual a la llave foránea' }
    return 'Simple, asignada en la carga'
}

function LlavesCandidatas($t) {
    $lista = @(, $t.Pk)
    foreach ($u in $t.Uq) {
        $contienePk = @($t.Pk | Where-Object { $u.Cols -notcontains $_ }).Count -eq 0
        if (-not $contienePk) { $lista += , $u.Cols }
    }
    $lista
}

function Llave($t, $nombreCol) {
    $m = @()
    if ($t.Pk -contains $nombreCol) { $m += 'PK' }
    if ((ColsFk $t) -contains $nombreCol) { $m += 'FK' }
    if (-not ($t.Pk -contains $nombreCol) -and @($t.Uq | Where-Object { $_.Cols -contains $nombreCol -and $_.Cols.Count -eq 1 }).Count) { $m += 'UQ' }
    $m -join ', '
}

function Escribir($archivo, $lineas) { [IO.File]::WriteAllText((Join-Path $Salida $archivo), (($lineas -join "`n") + "`n"), $utf8) }

$aviso = '% Archivo generado por bd/generar_tablas.ps1 a partir de bd/bastion.sql. No editar a mano.'
$areas = @($tablas.Values | ForEach-Object { $_.Area } | Select-Object -Unique)

#---------------------------------------------------------------------
# 1. Identificación de entidades
#---------------------------------------------------------------------
$o = @($aviso, '\begin{center}\small', '\begin{longtable}{|L{0.24\textwidth}|L{0.17\textwidth}|L{0.49\textwidth}|}',
    '\hline', '\textbf{Entidad} & \textbf{Clase} & \textbf{Qué representa} \\ \hline', '\endfirsthead',
    '\hline', '\textbf{Entidad} & \textbf{Clase} & \textbf{Qué representa} \\ \hline', '\endhead')
foreach ($a in $areas) {
    $o += '\multicolumn{3}{|l|}{\textbf{' + (Tex $a) + '}} \\ \hline'
    foreach ($t in @($tablas.Values | Where-Object { $_.Area -eq $a })) {
        $o += (Ent $t.Nombre) + ' & ' + (TipoEntidad $t) + ' & ' + (Tex $t.Desc) + ' \\ \hline'
    }
}
$o += '\end{longtable}', '\end{center}'
Escribir 'entidades.tex' $o

#---------------------------------------------------------------------
# 2. Atributos de cada entidad
#---------------------------------------------------------------------
$o = @($aviso)
foreach ($a in $areas) {
    $o += '\subsubsection*{' + (Tex $a) + '}', ''
    foreach ($t in @($tablas.Values | Where-Object { $_.Area -eq $a })) {
        $o += '\atributosde{' + $t.Nombre + '}{' + (Tex $t.Desc) + '}'
        $o += '\begin{tablaatributos}'
        foreach ($c in $t.Columnas) {
            $o += (TexCodigo $c.Nombre) + ' & ' + $c.Tipo + ' & ' + $c.Nulo + ' & ' + (Llave $t $c.Nombre) + ' & ' + (Tex $c.Desc) + ' \\ \hline'
        }
        $o += '\end{tablaatributos}', ''
    }
}
Escribir 'atributos.tex' $o

#---------------------------------------------------------------------
# 3. Llaves primarias y restricciones de unicidad
#---------------------------------------------------------------------
$o = @($aviso, '\begin{center}\small', '\begin{longtable}{|L{0.21\textwidth}|L{0.28\textwidth}|L{0.18\textwidth}|L{0.21\textwidth}|}',
    '\hline', '\textbf{Entidad} & \textbf{Llave primaria} & \textbf{Clase} & \textbf{Otras llaves candidatas} \\ \hline', '\endfirsthead',
    '\hline', '\textbf{Entidad} & \textbf{Llave primaria} & \textbf{Clase} & \textbf{Otras llaves candidatas} \\ \hline', '\endhead')
foreach ($t in $tablas.Values) {
    $otras = @(LlavesCandidatas $t | Select-Object -Skip 1 | ForEach-Object { TexCols $_ })
    $o += (Ent $t.Nombre) + ' & ' + (TexCols $t.Pk) + ' & ' + (ClaseLlave $t) + ' & ' + $(if ($otras.Count) { $otras -join '; ' } else { '---' }) + ' \\ \hline'
}
$o += '\end{longtable}', '\end{center}'
Escribir 'llaves-primarias.tex' $o

$o = @($aviso, '\begin{center}\small', '\begin{longtable}{|L{0.2\textwidth}|L{0.25\textwidth}|L{0.45\textwidth}|}',
    '\hline', '\textbf{Entidad} & \textbf{Columnas y condición} & \textbf{Regla que garantiza} \\ \hline', '\endfirsthead',
    '\hline', '\textbf{Entidad} & \textbf{Columnas y condición} & \textbf{Regla que garantiza} \\ \hline', '\endhead')
foreach ($t in $tablas.Values) {
    foreach ($u in $t.Uq) { $o += (Ent $t.Nombre) + ' & ' + (TexCols $u.Cols) + ' & ' + (Tex $u.Desc) + ' \\ \hline' }
    foreach ($u in $t.UqIdx) {
        $o += (Ent $t.Nombre) + ' & ' + (TexCols $u.Cols) + ', si ' + (TexCodigo ($u.Filtro.Replace("'", ''))) + ' & ' + (Tex $u.Desc) + ' \\ \hline'
    }
}
$o += '\end{longtable}', '\end{center}'
Escribir 'unicidad.tex' $o

#---------------------------------------------------------------------
# 4. Llaves foráneas
#---------------------------------------------------------------------
$o = @($aviso, '\begin{center}\small', '\begin{longtable}{|L{0.21\textwidth}|L{0.26\textwidth}|L{0.29\textwidth}|L{0.12\textwidth}|}',
    '\hline', '\textbf{Entidad} & \textbf{Llave foránea} & \textbf{Referencia} & \textbf{Obligatoria} \\ \hline', '\endfirsthead',
    '\hline', '\textbf{Entidad} & \textbf{Llave foránea} & \textbf{Referencia} & \textbf{Obligatoria} \\ \hline', '\endhead')
$totalFk = 0
foreach ($t in $tablas.Values) {
    foreach ($f in $t.Fk) {
        $nulas = @($f.Cols | Where-Object { $c = $_; ($t.Columnas | Where-Object { $_.Nombre -eq $c }).Nulo -eq 'Sí' }).Count
        $o += (Ent $t.Nombre) + ' & ' + (TexCols $f.Cols) + ' & ' + (Ent $f.Ref) + ' ' + (TexCols $f.RefCols) + ' & ' + $(if ($nulas) { 'No' } else { 'Sí' }) + ' \\ \hline'
        $totalFk++
    }
}
$o += '\end{longtable}', '\end{center}'
Escribir 'llaves-foraneas.tex' $o

#---------------------------------------------------------------------
# 5. Relaciones y cardinalidades
#---------------------------------------------------------------------
$o = @($aviso, '\begin{center}\small', '\begin{longtable}{|L{0.2\textwidth}|L{0.2\textwidth}|L{0.1\textwidth}|L{0.38\textwidth}|}',
    '\hline', '\textbf{Entidad padre} & \textbf{Entidad hija} & \textbf{Card.} & \textbf{Significado} \\ \hline', '\endfirsthead',
    '\hline', '\textbf{Entidad padre} & \textbf{Entidad hija} & \textbf{Card.} & \textbf{Significado} \\ \hline', '\endhead')
foreach ($a in $areas) {
    $filas = @()
    foreach ($t in @($tablas.Values | Where-Object { $_.Area -eq $a })) {
        foreach ($f in $t.Fk) {
            $opcional = @($f.Cols | Where-Object { $c = $_; ($t.Columnas | Where-Object { $_.Nombre -eq $c }).Nulo -eq 'Sí' }).Count -gt 0
            $card = $f.Card
            if ($opcional -and $card.StartsWith('1:')) { $card = '0..1:' + $card.Substring(2) }
            $filas += (Ent $f.Ref) + ' & ' + (Ent $t.Nombre) + ' & ' + $card + ' & ' + (Tex $f.Texto) + ' \\ \hline'
        }
    }
    if ($filas.Count) { $o += '\multicolumn{4}{|l|}{\textbf{' + (Tex $a) + '}} \\ \hline'; $o += $filas }
}
$o += '\end{longtable}', '\end{center}'
Escribir 'relaciones.tex' $o

#---------------------------------------------------------------------
# 6. Verificación de la forma normal, tabla por tabla
#---------------------------------------------------------------------
$o = @($aviso, '\begin{center}\small', '\begin{longtable}{|L{0.19\textwidth}|L{0.23\textwidth}|L{0.08\textwidth}|L{0.38\textwidth}|}',
    '\hline', '\textbf{Entidad} & \textbf{Llaves candidatas} & \textbf{Forma} & \textbf{Justificación} \\ \hline', '\endfirsthead',
    '\hline', '\textbf{Entidad} & \textbf{Llaves candidatas} & \textbf{Forma} & \textbf{Justificación} \\ \hline', '\endhead')
$soloTercera = 0
foreach ($t in $tablas.Values) {
    $fnTexto = $t.Fn; $forma = 'FNBC'
    if ($fnTexto -like '`[3FN`]*') { $forma = '3FN'; $fnTexto = $fnTexto.Substring(5).Trim(); $soloTercera++ }
    $llaves = @(LlavesCandidatas $t | ForEach-Object { TexCols $_ }) -join '; '
    $o += (Ent $t.Nombre) + ' & ' + $llaves + ' & ' + $forma + ' & ' + (Tex $fnTexto) + ' \\ \hline'
}
$o += '\end{longtable}', '\end{center}'
Escribir 'normalizacion.tex' $o

#---------------------------------------------------------------------
# Resumen para el texto del documento
#---------------------------------------------------------------------
$cols = ($tablas.Values | ForEach-Object { $_.Columnas.Count } | Measure-Object -Sum).Sum
$calc = ($tablas.Values | ForEach-Object { @($_.Columnas | Where-Object { $_.Calculada }).Count } | Measure-Object -Sum).Sum
$resumen = @($aviso,
    "\newcommand{\bdNumTablas}{$($tablas.Count)}",
    "\newcommand{\bdNumColumnas}{$cols}",
    "\newcommand{\bdNumCalculadas}{$calc}",
    "\newcommand{\bdNumForaneas}{$totalFk}",
    "\newcommand{\bdNumFNBC}{$($tablas.Count - $soloTercera)}")
Escribir 'resumen.tex' $resumen
"Tablas: $($tablas.Count); columnas: $cols; calculadas: $calc; llaves foráneas: $totalFk; solo 3FN: $soloTercera"
