import std/[strformat, sugar]
import std/[sequtils, strutils, hashes, sets, tables]
import std/[typetraits, sets, tables]
import std/[macrocache, macros]
import patty

import numberTypes, constraints
export numberTypes, constraints

type
  GridNode* = concept node
    distinctBase(node.box) = Rect

type
  GridDir* = enum
    dcol
    drow

  GridFlow* = enum
    grRow
    grRowDense
    grColumn
    grColumnDense

type
  GridTemplate* = ref object
    lines*: array[GridDir, seq[GridLine]]
    autos*: array[GridDir, Constraint]
    gaps*: array[GridDir, UiScalar]
    justifyItems*: ConstraintBehavior
    alignItems*: ConstraintBehavior
    justifyContent*: ConstraintBehavior
    alignContent*: ConstraintBehavior
    autoFlow*: GridFlow

  LineName* = distinct int
  LinePos* = int16

  GridLine* = object
    aliases*: HashSet[LineName]
    track*: Constraint
    start*: UiScalar
    width*: UiScalar

  GridIndex* = object
    line*: LineName
    isSpan*: bool
    isName*: bool
  
  GridSpan* = array[GridDir, Slice[int16]]
  
  GridItem* = ref object
    span*: GridSpan
    index*: array[GridDir, Slice[GridIndex]]


const lnTable = CacheTable"lnTable"

proc contains(ct: CacheTable, nm: string): bool =
  for k, v in ct:
    if nm == k:
      return true

var lnNameCache* {.compileTime.}: Table[int, string]

macro declLineName*(name: typed): LineName =
  let nm = name.strVal
  let id = nm.hash()
  lnNameCache[id.int] = nm
  let res = quote do:
    LineName(`id`)
  if nm in lnTable:
    result = lnTable[nm]
    assert id == result[1].intVal
  else:
    lnTable[nm] = res
    result = res

proc findLN(nm: string, node: NimNode): NimNode {.compileTime.} =
  if nm in lnTable:
    result = lnTable[nm]
  else:
    error("[cssgrid] LineName not declared: " & `nm`, node)

macro findLineName*(name: typed): LineName =
  let nm = name.strVal
  result = findLN(nm, name)

# template findLineName*(name: static string): LineName =
#   findLineNameImpl(name)

var lineName: Table[int, string]

macro ln*(n: string): GridIndex =
  ## numeric literal view width unit
  let val = findLN(n.strVal, n)
  result = quote do:
    GridIndex(line: `val`, isName: true)

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
    result &= ", cS: " & repr a.index[dcol].a
    result &= "\n\t\t"
    result &= ", cE: " & repr a.index[dcol].b
    result &= "\n\t\t"
    result &= ", rS: " & repr a.index[drow].a
    result &= "\n\t\t"
    result &= ", rE: " & repr a.index[drow].b
    result &= "}"

proc toLineName*(name: int): LineName =
  result = LineName(name)
  lineName[result.int] = "idx:" & $name
proc toLineName*(name: string): LineName =
  # echo "line name: ", name
  result = LineName(name.hash())
  if result.int in lineName:
    assert lineName[result.int] == name
  else:
    lineName[result.int] = name

proc toLineNames*(names: varargs[LineName, toLineName]): HashSet[LineName] =
  toHashSet names

proc mkIndex*(line: int, isSpan = false, isName = false): GridIndex =
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

proc spanCnt*(a: GridIndex): int =
  if a.isSpan: 1 else: 0

proc `//`*(a, b: int|GridIndex): Slice[GridIndex] =
  result.a = mkIndex(a)
  result.b = mkIndex(b)
  when not b.typeof is GridIndex:
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
  result = fmt"GL({$a.track}; <{$a.start} x {$a.width}'w> <- {$a.aliases})"

proc repr*(a: GridLine): string =
  result = fmt"GL({a.track.repr}; <{$a.start} x {$a.width}'w> <- {$a.aliases})"
proc repr*(a: GridTemplate): string =
  if a.isNil:
    return "nil"
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

proc `$`*(a: GridTemplate): string =
  result = a.repr
