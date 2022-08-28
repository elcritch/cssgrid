import std/[strformat, sugar]
import std/[sequtils, strutils, hashes, sets, tables]
import rationals
import typetraits
import patty

import basic, constraints
export basic, sets, tables, constraints

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
    columns*: seq[GridLine]
    rows*: seq[GridLine]
    autoColumns*: ConstraintSize
    autoRows*: ConstraintSize
    rowGap*: UiScalar
    columnGap*: UiScalar
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
    columnStart*: GridIndex
    columnEnd*: GridIndex
    rowStart*: GridIndex
    rowEnd*: GridIndex

var lineName: Table[LineName, string]

proc `==`*(a, b: LineName): bool {.borrow.}
proc hash*(a: LineName): Hash {.borrow.}
proc hash*(a: GridItem): Hash =
  if a != nil:
    result = hash(a.span[drow]) !& hash(a.span[dcol])

proc `$`*(a: LineName): string = lineName[a]

proc `$`*(a: HashSet[LineName]): string =
  result = "{" & a.toSeq().mapIt($it).join(", ") & "}"

# proc `repr`*(a: HashSet[LineName]): string =
#   result = "{" & a.toSeq().mapIt(repr it).join(", ") & "}"

proc `$`*(a: GridIndex): string =
  result = "GridIdx{"
  if a.isName:
    result &= "" & $lineName.getOrDefault(a.line, $a.line.int)
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
    result &= ", cS: " & repr a.columnStart
    result &= "\n\t\t"
    result &= ", cE: " & repr a.columnEnd
    result &= "\n\t\t"
    result &= ", rS: " & repr a.rowStart
    result &= "\n\t\t"
    result &= ", rE: " & repr a.rowEnd
    result &= "}"

proc toLineName*(name: int): LineName =
  result = LineName(name)
  lineName[result] = "idx:" & $name
proc toLineName*(name: string): LineName =
  result = LineName(name.hash())
  if result in lineName:
    assert lineName[result] == name
  else:
    lineName[result] = name

proc toLineNames*(names: varargs[string, toLineName]): HashSet[LineName] =
  toHashSet names.toSeq().mapIt(it.toLineName())

proc mkIndex*(line: Positive, isSpan = false, isName = false): GridIndex =
  GridIndex(line: line.toLineName(), isSpan: isSpan, isName: isName)

proc mkIndex*(name: string, isSpan = false): GridIndex =
  GridIndex(line: name.toLineName(), isSpan: isSpan, isName: true)

proc mkIndex*(index: GridIndex): GridIndex =
  result = index

proc `column=`*(item: GridItem, rat: Rational[int]) =
  item.columnStart = rat.num.mkIndex
  item.columnEnd = rat.den.mkIndex
proc `row=`*(item: GridItem, rat: Rational[int]) =
  item.rowStart = rat.num.mkIndex
  item.rowEnd = rat.den.mkIndex

proc `$`*(a: GridLine): string =
  result = fmt"GL({$a.track}; <{$a.start} x {$a.width}'w> <- {$a.aliases})"

proc repr*(a: GridLine): string =
  result = fmt"GL({a.track.repr}; <{$a.start} x {$a.width}'w> <- {$a.aliases})"
proc repr*(a: GridTemplate): string =
  result = "GridTemplate:"
  result &= "\n\tcols: "
  for c in a.columns:
    result &= &"\n\t\t{c.repr}"
  result &= "\n\trows: "
  for r in a.rows:
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
  result.columns = columns
  result.rows = rows
  result.autoColumns = csFixed(0)
  result.autoRows = csFixed(0)

proc newGridItem*(): GridItem =
  new(result)

proc `$`*(a: GridTemplate): string =
  result = a.repr
