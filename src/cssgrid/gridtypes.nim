import std/[strformat, sugar]
import std/[sequtils, strutils, hashes, sets, tables]
import rationals
import typetraits
import patty

import basic
export sets

type
  GridDir* = enum
    dcol
    drow

  GridConstraint* = enum
    gcStretch
    gcStart
    gcEnd
    gcCenter

  GridUnits* = enum
    grFrac
    grAuto
    grPerc
    grFixed
    grEnd

  GridFlow* = enum
    grRow
    grRowDense
    grColumn
    grColumnDense

  TrackSize* = object
    case kind*: GridUnits
    of grFrac:
      frac*: float
    of grAuto:
      discard
    of grPerc:
      perc*: float
    of grFixed:
      coord*: UiScalar
    of grEnd:
      discard
  
  LineName* = distinct int
  LinePos* = int16

  GridLine* = object
    aliases*: HashSet[LineName]
    track*: TrackSize
    start*: UiScalar
    width*: UiScalar

  GridTemplate* = ref object
    columns*: seq[GridLine]
    rows*: seq[GridLine]
    autoColumns*: TrackSize
    autoRows*: TrackSize
    rowGap*: UiScalar
    columnGap*: UiScalar
    justifyItems*: GridConstraint
    alignItems*: GridConstraint
    justifyContent*: GridConstraint
    alignContent*: GridConstraint
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

proc `repr`*(a: LineName): string = lineName[a]
proc `repr`*(a: HashSet[LineName]): string =
  result = "{" & a.toSeq().mapIt(repr it).join(", ") & "}"
proc `repr`*(a: GridIndex): string =
  result = "GridIdx{"
  if a.isName:
    result &= "" & $lineName.getOrDefault(a.line, $a.line.int)
  else:
    result &= "" & $a.line.int
  result &= ",s:" & $a.isSpan
  result &= ",n:" & $a.isName
  result &= "}"

proc `repr`*(a: GridItem): string =
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
  if result.int == 0:
    result = LineName(result.int + 11)
  if result in lineName:
    assert lineName[result] == name
  else:
    lineName[result] = name

proc toLineNames*(names: varargs[string]): HashSet[LineName] =
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


proc repr*(a: TrackSize): string =
  match a:
    grFrac(frac): result = $frac & "'fr"
    grFixed(coord): result = $coord & "'ui"
    grPerc(perc): result = $perc & "'perc"
    grAuto(): result = "auto"
    grEnd(): result = "ends"
proc repr*(a: GridLine): string =
  result = fmt"GL({a.track.repr}; <{$a.start} x {$a.width}'w> <- {a.aliases.repr})"
proc repr*(a: GridTemplate): string =
  result = "GridTemplate:"
  result &= "\n\tcols: "
  for c in a.columns:
    result &= &"\n\t\t{c.repr}"
  result &= "\n\trows: "
  for r in a.rows:
    result &= &"\n\t\t{r.repr}"

proc mkFrac*(size: float): TrackSize = TrackSize(kind: grFrac, frac: size)
proc mkFixed*(coord: UiScalar): TrackSize = TrackSize(kind: grFixed, coord: coord)
proc mkPerc*(perc: float): TrackSize = TrackSize(kind: grPerc, perc: perc)
proc mkAuto*(): TrackSize = TrackSize(kind: grAuto)
proc mkEndTrack*(): TrackSize = TrackSize(kind: grEnd)

proc `'fr`*(n: string): TrackSize =
  ## numeric literal UI Coordinate unit
  let f = parseFloat(n)
  result = TrackSize(kind: grFrac, frac: f)

proc initGridLine*(
    track = mkFrac(1),
    aliases: varargs[LineName, toLineName],
): GridLine =
  GridLine(track: track, aliases: toHashSet(aliases))

proc gl*(track: TrackSize): GridLine =
  GridLine(track: track)
