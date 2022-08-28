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
  var idx = 0
  var idxLit: NimNode = newIntLitNode(idx)
  var node: NimNode = arg
  let isCmdStyle: bool = arg.kind == nnkStmtList
  template idxIncr(idx: untyped) =
    idx.inc
    idxLit = newIntLitNode(idx)
  proc handleDotExpr(result, item, tgt: NimNode) =
    result.add quote do:
      `tgt`[`idxLit`].track = `item`
  proc prepareNames(item: NimNode): NimNode =
    result = newStmtList()
    for x in item:
      let n = newLit x.strVal
      result.add quote do:
        `tgt`[`idxLit`].aliases.incl toLineName(`n`)
  if isCmdStyle:
    for node in arg:
      var item: NimNode = node
      ## handle `\` for line wrap
      case node.kind:
      of nnkBracket:
        result[1].add prepareNames(item)
      of nnkDotExpr:
        result[1].handleDotExpr(item, tgt)
        idx.idxIncr()
      of nnkCommand:
        let brack = node[0]
        let dotexpr = node[1]
        brack.expectKind(nnkBracket)
        dotexpr.expectKind(nnkDotExpr)
        # handle bracket
        result[1].add prepareNames(brack)
        # handle dotexpr
        result[1].handleDotExpr(dotexpr, tgt)
        idx.idxIncr()
      else:
        discard
  ## add final implicit line
  if node.kind == nnkBracket:
    result[1].add prepareNames(node)
  elif node.kind == nnkDotExpr:
    var item = node
    result[1].handleDotExpr(item, tgt)
    idx.idxIncr()

  result[1].add quote do:
    `tgt`[`idxLit`].track = csEnd()
  result[0] = idx + 1

macro gridTemplateImpl*(gridTmpl, args: untyped, field: untyped) =
  echo "gridTemplateImpl: ", args.treeRepr
  result = newStmtList()
  let tgt = quote do:
    `gridTmpl`.`field`
  let fargs = args.flatten()
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
