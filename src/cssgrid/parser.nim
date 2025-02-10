import typetraits
import macros except `$`
import numberTypes, gridtypes

export gridtypes

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
  proc incrIdx(res: var (int, NimNode), idxLit: var NimNode) =
      res[0].inc()
      idxLit = newIntLitNode(res[0])
      # res[1].add quote do:
      #   `tgt`[`idxLit`].aliases.clear()
  for node in arg:
    # echo "node: ", node.kind, " repr: ", node.treeRepr
    case node.kind:
    of nnkBracket:
      for name in node:
        let n = newStrLitNode name.strVal
        result[1].add quote do:
          `tgt`[`idxLit`].aliases.incl atom(`n`)
    of nnkDotExpr:
      result[1].add quote do:
        `tgt`[`idxLit`].track = `node`
      incrIdx(result, idxLit)
    of nnkIdent:
      if node.strVal == "auto":
        result[1].add quote do:
          `tgt`[`idxLit`].track = csAuto()
        incrIdx(result, idxLit)
      else:
        error("unknown argument: " & node.repr)
    of nnkCall:
      if node[0].repr == "repeat":
        echo "node:call: ", node.treeRepr
        let subnode = node[^1]
        for i in 0 ..< node[1].intVal:
          result[1].add quote do:
            `tgt`[`idxLit`].track = `subnode`
          incrIdx(result, idxLit)
      else:
        result[1].add quote do:
          `tgt`[`idxLit`].track = `node`
        incrIdx(result, idxLit)
    else:
      # error("unknown argument: " & node.repr)
      result[1].add quote do:
        `tgt`[`idxLit`].track = `node`
      incrIdx(result, idxLit)

  result[1].add quote do:
    `tgt`[`idxLit`].track = csEnd()
  result[0] = result[0] + 1
  # echo "parseTmpl: ", result[1].repr

macro gridTemplateImpl*(gridTmpl, args: untyped, field: untyped) =
  result = newStmtList()
  let tgt = quote do:
    `gridTmpl`.lines[`field`]
  # echo "\ngridTemplateImpl: ", args.treeRepr
  let fargs = args.flatten()
  # echo "\ngridTemplatePost: ", fargs.treeRepr
  let (colCount, cols) = parseTmplCmd(tgt, fargs)
  result.add quote do:
    if `gridTmpl`.isNil:
      `gridTmpl` = newGridTemplate()
    block:
      `gridTmpl`.lines[`field`].setLen(`colCount`)
      `cols`
  # echo "gt:result: ", result.repr

macro `!@`*(arg: untyped{nkBracket}): auto =
  result = nnkBracket.newTree()
  for a in arg:
    result.add quote do:
      toLineName(`a`)
  result = quote do:
    toLineNames(`result`)
  # echo "r: ", result.repr

template parseGridTemplateColumns*(gridTmpl, args: untyped) =
  gridTemplateImpl(gridTmpl, args, dcol)

template parseGridTemplateRows*(gridTmpl, args: untyped) =
  gridTemplateImpl(gridTmpl, args, drow)

proc gridTemplate*(gt: GridTemplate, dir: GridDir, args: varargs[(HashSet[LineName], Constraint), initGridLine]) =
  if dir == dcol:
    gt.lines[dcol].setLen(args.len())
    for i, arg in args:
      gt.lines[dcol][i] = arg.toGridLine()

proc span*(name: static string): GridIndex =
  GridIndex(line: atom(name), isSpan: true, isName: true)

proc mkIndex*(name: static string, isSpan = false): GridIndex =
  GridIndex(line: atom(name), isSpan: isSpan, isName: true)

proc `//`*(a, b: static[string]|string|int|GridIndex): Slice[GridIndex] =
  result.a = mkIndex(a)
  result.b = mkIndex(b)
  when not b.typeof is GridIndex:
    result.b.isSpan = false

