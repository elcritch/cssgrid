import basic, gridtypes
import typetraits
import macros except `$`
import std/macrocache
import std/macros

export gridtypes

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

macro findLineNameImpl(name: typed): LineName =
  let nm = name.strVal
  if nm in lnTable:
    result = lnTable[nm]
  else:
    error("[cssgrid] LineName not declared: " & nm)

template findLineName*(name: static string): LineName =
  findLineNameImpl(name)

proc flatten(arg: NimNode): NimNode {.compileTime.} =
  ## flatten the representation
  result = newStmtList()
  if arg.kind == nnkStmtList:
    for node in arg:
      if node.kind == nnkCommand:
        result.add node[0]
        result.add node[1]
      else:
        result.add node
  else:
    var node: NimNode = arg
    while node.kind == nnkCommand:
      result.add node[0]
      node = node[1]
      if node.kind == nnkInfix:
        result.add node[1]
        node = node[2]
    result.add node

proc parseTmplCmd*(tgt, arg: NimNode): (int, NimNode) {.compileTime.} =
  result = (0, newStmtList())
  var idxLit: NimNode = newIntLitNode(result[0])
  # process templates
  for node in arg:
    case node.kind:
    of nnkBracket:
      for name in node:
        let n = newLit name.strVal
        result[1].add quote do:
          `tgt`[`idxLit`].aliases.incl declLineName(`n`)
    of nnkDotExpr:
      result[1].add quote do:
        `tgt`[`idxLit`].track = `node`
      result[0].inc()
      idxLit = newIntLitNode(result[0])
    of nnkIdent:
      if node.strVal == "auto":
        result[1].add quote do:
          `tgt`[`idxLit`].track = csAuto()
      else:
        error("unknown argument: " & node.repr)
    else:
      error("unknown argument: " & node.repr)

  result[1].add quote do:
    `tgt`[`idxLit`].track = csEnd()
  result[0] = result[0] + 1
  # echo "parseTmpl: ", result[1].repr

var doPrints* {.compileTime.} = false

macro gridTemplateImpl*(gridTmpl, args: untyped, field: untyped) =
  result = newStmtList()
  let tgt = quote do:
    `gridTmpl`.`field`
  if doPrints: echo "\ngridTemplateImpl: ", args.treeRepr
  let fargs = args.flatten()
  if doPrints: echo "\ngridTemplatePost: ", fargs.treeRepr
  let (colCount, cols) = parseTmplCmd(tgt, fargs)
  result.add quote do:
    if `gridTmpl`.isNil:
      `gridTmpl` = newGridTemplate()
    block:
      if `gridTmpl`.`field`.len() < `colCount`:
        `gridTmpl`.`field`.setLen(`colCount`)
        `cols`
  echo "result: ", result.repr

template `!`*(arg: untyped{nkBracket}): auto =
  toLineNames(arg)

template parseGridTemplateColumns*(gridTmpl, args: untyped) =
  gridTemplateImpl(gridTmpl, args, columns)

template parseGridTemplateRows*(gridTmpl, args: untyped) =
  gridTemplateImpl(gridTmpl, args, rows)

proc gridTemplate*(gt: GridTemplate, dir: GridDir, args: varargs[(HashSet[LineName], ConstraintSize), initGridLine]) =
  if dir == dcol:
    gt.columns.setLen(args.len())
    for i, arg in args:
      gt.columns[i] = arg.toGridLine()