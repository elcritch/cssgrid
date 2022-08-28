import basic, gridtypes
import typetraits
import macros except `$`

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
          `tgt`[`idxLit`].aliases.incl toLineName(`n`)
    of nnkDotExpr:
      result[1].add quote do:
        `tgt`[`idxLit`].track = `node`
      result[0].inc()
      idxLit = newIntLitNode(result[0])
    else:
      discard

  result[1].add quote do:
    `tgt`[`idxLit`].track = csEnd()
  result[0] = result[0] + 1
  echo "parseTmpl: ", result[1].repr

macro gridTemplateImpl*(gridTmpl, args: untyped, field: untyped) =
  result = newStmtList()
  let tgt = quote do:
    `gridTmpl`.`field`
  let fargs = args.flatten()
  echo "gridTemplateImpl: ", fargs.treeRepr
  let (colCount, cols) = parseTmplCmd(tgt, fargs)
  result.add quote do:
    if `gridTmpl`.isNil:
      `gridTmpl` = newGridTemplate()
    block:
      if `gridTmpl`.`field`.len() < `colCount`:
        `gridTmpl`.`field`.setLen(`colCount`)
        `cols`
  # echo "result: ", result.repr

template parseGridTemplateColumns*(gridTmpl, args: untyped) =
  gridTemplateImpl(gridTmpl, args, columns)

template parseGridTemplateRows*(gridTmpl, args: untyped) =
  gridTemplateImpl(gridTmpl, args, rows)
