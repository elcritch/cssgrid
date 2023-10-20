import std/[strformat]
import std/[sequtils, strutils, hashes, sets, tables]
import std/[typetraits]
import std/[macrocache, macros]
import stack_strings

import numberTypes, constraints
export numberTypes, constraints, stack_strings

const CssGridAtomSize {.intdefine.} = 16

type
  Atom* = StackString[CssGridAtomSize]
  LineName* = Atom

  GridNode* = concept node
    distinctBase(typeof(node.box)) is Rect
    typeof(node.gridItem) is GridItem
  GridBox* = concept box
    distinctBase(typeof(box)) is Rect

  GridDir* = enum
    dcol
    drow

  GridFlow* = enum
    grRow
    grRowDense
    grColumn
    grColumnDense

  GridTemplate* = ref object
    lines*: array[GridDir, seq[GridLine]]
    autos*: array[GridDir, Constraint]
    gaps*: array[GridDir, UiScalar]
    justifyItems*: ConstraintBehavior
    alignItems*: ConstraintBehavior
    autoFlow*: GridFlow
    overflowSizes*: array[GridDir, UiScalar]

  LinePos* = int16

  GridLine* = object
    aliases*: HashSet[Atom]
    track*: Constraint
    start*: UiScalar
    width*: UiScalar
    isAuto*: bool

  GridIndex* = object
    line*: Atom
    isSpan*: bool
    isName*: bool
  
  GridSpan* = array[GridDir, Slice[int16]]
  
  GridItem* = ref object
    span*: GridSpan
    index*: array[GridDir, Slice[GridIndex]]
    justify*: ConstraintBehavior
    align*: ConstraintBehavior

proc atom*(a: static string): Atom =
  discard result.addTruncate a

macro ln*(n: string): GridIndex =
  ## numeric literal view width unit
  result = quote do:
    GridIndex(line: atom(`n`), isName: true)

proc toLineName*(name: int): Atom =
  result.unsafeSetLen(name.sizeof)
  for i in 0..<name.sizeof:
    result[i] = char((name shr (i*8)) and 0xFF)

proc ints*(a: Atom): int =
  if a.len == 0:
    return 0
  let n = min(result.sizeof, a.len)
  for i in 0..<n:
    result = (result shl 8) or int(a[n - i - 1])

proc columns*(grid: GridTemplate): seq[GridLine] =
  grid.lines[dcol]
proc rows*(grid: GridTemplate): seq[GridLine] =
  grid.lines[drow]

proc hash*(a: GridItem): Hash =
  if a != nil:
    result = hash(a.span[drow]) !& hash(a.span[dcol])

proc `repr`*(a: HashSet[LineName]): string =
  result = "{" & a.toSeq().mapIt(repr it).join(", ") & "}"

proc `$`*(a: GridIndex): string =
  result = "GridIdx{"
  if a.isName:
    result &= "'" & $a.line & "'"
  else:
    result &= $(a.line.ints())
  if a.isSpan:
    result &= ",s:" & $a.isSpan
  result &= "}"

proc `$`*(a: GridItem): string =
  if a != nil:
    result = "GridItem{" 
    result &= " span[dcol]: " & $a.span[dcol]
    result &= ", span[drow]: " & $a.span
    result &= ",\n\t\t"
    result &= "col: " & $a.index[dcol].a
    result &= " "
    result &= ", " & $a.index[dcol].b
    result &= " "
    result &= ", row: " & $a.index[drow].a
    result &= " "
    result &= ", " & $a.index[drow].b
    result &= "}"

proc toLineName*(name: string): Atom =
  discard result.addTruncate(name)

proc toLineNames*(names: varargs[LineName, toLineName]): HashSet[LineName] =
  toHashSet names

proc mkIndex*(line: int, isSpan = false, isName = false): GridIndex =
  GridIndex(line: line.toLineName(), isSpan: isSpan, isName: isName)

proc mkIndex*(name: string, isSpan = false): GridIndex =
  GridIndex(line: name.toLineName(), isSpan: isSpan, isName: true)

proc mkIndex*(index: GridIndex): GridIndex =
  result = index

proc span*(a: int): GridIndex =
  result.line = a.toLineName
  result.isSpan = true
proc span*(a: GridIndex): GridIndex =
  result.line = a.line
  result.isName = a.isName
  result.isSpan = true

proc spanCnt*(a: GridIndex): int =
  if a.isSpan: 1 else: 0

proc `//`*(a, b: int|GridIndex): Slice[GridIndex] =
  result.a = mkIndex(a)
  result.b = mkIndex(b)
  when b.typeof isnot GridIndex:
    result.b.isSpan = false

proc `column=`*(grid: GridItem, index: Slice[GridIndex]) =
  grid.index[dcol] = index
proc `row=`*(grid: GridItem, index: Slice[GridIndex]) =
  grid.index[drow] = index

proc `column=`*(grid: GridItem, index: int) =
  grid.index[dcol] = index // (index + 1)
proc `row=`*(grid: GridItem, index: int) =
  grid.index[drow] = index // (index + 1)

proc `column=`*(grid: GridItem, index: static string) =
  grid.index[dcol] = index.mkIndex // span(index.mkIndex)
proc `row=`*(grid: GridItem, index: static string) =
  grid.index[drow] = index.mkIndex // span(index.mkIndex)

proc `column=`*(grid: GridItem, index: GridIndex) =
  grid.index[dcol] = index.mkIndex // span(index.mkIndex)
proc `row=`*(grid: GridItem, index: GridIndex) =
  grid.index[drow] = index.mkIndex // span(index.mkIndex)

proc `column`*(grid: GridItem): var Slice[GridIndex] =
  grid.index[dcol]
proc `row`*(grid: GridItem): var Slice[GridIndex] =
  grid.index[drow]

proc `$`*(a: GridLine): string =
  result = fmt"GL({a.track}; <{$a.start.float.round(2)} x {$a.width.float.round(2)}'w> <- {$a.aliases})"

proc `$`*(a: GridTemplate): string =
  if a.isNil:
    return "nil"
  result = "GridTemplate:"
  result &= "\n   cols: "
  for c in a.lines[dcol]:
    result &= &"\n      {$c}"
  result &= "\n   rows: "
  for r in a.lines[drow]:
    result &= &"\n      {$r}"

proc initGridLine*(
    track = csFrac(1),
    aliases: varargs[LineName, toLineName],
    isAuto = false,
): GridLine =
  GridLine(track: track, aliases: toHashSet(aliases), isAuto: isAuto)

proc toGridLine*(
    arg: (HashSet[LineName], Constraint)
): GridLine =
  GridLine(track: arg[1], aliases: arg[0])

proc gl*(track: Constraint): GridLine =
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
