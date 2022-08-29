import std/[strformat, sugar]
import std/[sequtils, strutils, hashes, sets, tables]
import rationals
import typetraits
import patty
export rationals, sets, tables

import basic, constraints
export basic, constraints

type
  GridNodes* = concept node
    node.box = uiBox(0, 0, 0, 0)

type
  GridDir* = enum
    dcol
    drow

  GridFlow* = enum
    grRow
    grRowDense
    grColumn
    grColumnDense


proc repr*(a: ConstraintSize): string =
  match a:
    UiFrac(frac): result = $frac & "'fr"
    UiFixed(coord): result = $coord & "'ui"
    UiPerc(perc): result = $perc & "'perc"
    UiAuto(): result = "auto"
    UiEnd(): result = "ends"

type
  LineName* = distinct int
  LinePos* = int16

  GridLine* = object
    aliases*: HashSet[LineName]
    track*: ConstraintSize
    start*: UiScalar
    width*: UiScalar

  GridTemplate* = ref object
    lines*: array[GridDir, seq[GridLine]]
    autos*: array[GridDir, ConstraintSize]
    gaps*: array[GridDir, UiScalar]
    justifyItems*: Constraint
    alignItems*: Constraint
    justifyContent*: Constraint
    alignContent*: Constraint
    autoFlow*: GridFlow

  GridIndex* = object
    line*: LineName
    isSpan*: bool
    isName*: bool
  
  GridSpan* = array[GridDir, Slice[int16]]
  
  GridItem* = ref object
    span*: GridSpan
    columns*: Slice[GridIndex]
    rows*: Slice[GridIndex]

var lineName: Table[int, string]

proc columns*(grid: GridTemplate): seq[GridLine] =
  grid.lines[dcol]
proc rows*(grid: GridTemplate): seq[GridLine] =
  grid.lines[drow]

proc `==`*(a, b: LineName): bool {.borrow.}
proc hash*(a: LineName): Hash {.borrow.}
proc hash*(a: GridItem): Hash =
  if a != nil:
    result = hash(a.span[drow]) !& hash(a.span[dcol])

proc `$`*(a: LineName): string =
  if a.int in lineName:
    lineName[a.int]
  else:
    "int:" & $a.int

proc `$`*(a: HashSet[LineName]): string =
  result = "{" & a.toSeq().mapIt($it).join(", ") & "}"

# proc `repr`*(a: HashSet[LineName]): string =
#   result = "{" & a.toSeq().mapIt(repr it).join(", ") & "}"

proc `$`*(a: GridIndex): string =
  result = "GridIdx{"
  if a.isName:
    result &= "" & $lineName.getOrDefault(a.line.int, $a.line.int)
  else:
    result &= "" & $a.line.int
  result &= ",s:" & $a.isSpan
  result &= ",n:" & $a.isName
  result &= "}"

proc `$`*(a: GridItem): string =
  if a != nil:
    result = "GridItem{" 
    result &= " span[dcol]: " & $a.span[dcol]
    result &= ", span[drow]: " & $a.span
    result &= "\n\t\t"
    result &= ", cS: " & repr a.columns.a
    result &= "\n\t\t"
    result &= ", cE: " & repr a.columns.b
    result &= "\n\t\t"
    result &= ", rS: " & repr a.rows.a
    result &= "\n\t\t"
    result &= ", rE: " & repr a.rows.b
    result &= "}"

proc toLineName*(name: int): LineName =
  result = LineName(name)
  lineName[result.int] = "idx:" & $name
proc toLineName*(name: string): LineName =
  result = LineName(name.hash())
  if result.int in lineName:
    assert lineName[result.int] == name
  else:
    lineName[result.int] = name

proc toLineNames*(names: varargs[LineName, toLineName]): HashSet[LineName] =
  toHashSet names

proc mkIndex*(line: Positive, isSpan = false, isName = false): GridIndex =
  GridIndex(line: line.toLineName(), isSpan: isSpan, isName: isName)

proc mkIndex*(name: string, isSpan = false): GridIndex =
  GridIndex(line: name.toLineName(), isSpan: isSpan, isName: true)

proc mkIndex*(index: GridIndex): GridIndex =
  result = index

proc span*(a: int): GridIndex =
  result.line = a.LineName
  result.isSpan = true
proc span*(a: GridIndex): GridIndex =
  result.line = a.line
  result.isName = a.isName
  result.isSpan = true

proc `//`*(a, b: int|GridIndex): Slice[GridIndex] =
  result.a = mkIndex(a)
  result.b = mkIndex(b)
  when not b.typeof is GridIndex:
    result.b.isSpan = false

proc `$`*(a: GridLine): string =
  result = fmt"GL({$a.track}; <{$a.start} x {$a.width}'w> <- {$a.aliases})"

proc repr*(a: GridLine): string =
  result = fmt"GL({a.track.repr}; <{$a.start} x {$a.width}'w> <- {$a.aliases})"
proc repr*(a: GridTemplate): string =
  result = "GridTemplate:"
  result &= "\n\tcols: "
  for c in a.lines[dcol]:
    result &= &"\n\t\t{c.repr}"
  result &= "\n\trows: "
  for r in a.lines[drow]:
    result &= &"\n\t\t{r.repr}"

proc initGridLine*(
    track = csFrac(1),
    aliases: varargs[LineName, toLineName],
): GridLine =
  GridLine(track: track, aliases: toHashSet(aliases))

proc toGridLine*(
    arg: (HashSet[LineName], ConstraintSize)
): GridLine =
  GridLine(track: arg[1], aliases: arg[0])

proc gl*(track: ConstraintSize): GridLine =
  GridLine(track: track)

proc newGridTemplate*(
  columns: seq[GridLine] = @[],
  rows: seq[GridLine] = @[],
): GridTemplate =
  new(result)
  result.lines[dcol] = columns
  result.lines[drow] = rows
  result.autos[dcol] = csFixed(0)
  result.autos[drow] = csFixed(0)

proc newGridItem*(): GridItem =
  new(result)

proc `$`*(a: GridTemplate): string =
  result = a.repr
