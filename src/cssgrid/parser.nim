import basic, gridtypes
import typetraits
import macros except `$`

proc parseTmplCmd*(tgt, arg: NimNode): (int, NimNode) {.compileTime.} =
  result = (0, newStmtList())
  var idx = 0
  var idxLit: NimNode = newIntLitNode(idx)
  var node: NimNode = arg
  let isCmdStyle: bool = arg.kind == nnkStmtList
  template idxIncr() =
    idx.inc
    idxLit = newIntLitNode(idx)
  proc handleDotExpr(result, item, tgt: NimNode) =
    # echo item.lispRepr
    # if item[0].kind == nnkRStrLit:
    #   let n = item[0].strVal.parseInt()
    #   let kd = item[1].strVal
    #   if kd == "'fr":
    #     result.add quote do:
    #       `tgt`[`idxLit`].track = csFrac(`n`)
    #   elif kd == "'perc":
    #     result.add quote do:
    #       `tgt`[`idxLit`].track = csPerc(`n`)
    #   elif kd == "'ui":
    #     result.add quote do:
    #       `tgt`[`idxLit`].track = csFixed(`n`)
    #   else:
    #     # error("error: unknown argument ", item)
    #     result.add quote do:
    #       `tgt`[`idxLit`].track = csFixed(`item`)
    # else:
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
        idxIncr()
      of nnkCommand:
        let brack = node[0]
        let dotexpr = node[1]
        brack.expectKind(nnkBracket)
        dotexpr.expectKind(nnkDotExpr)
        # handle bracket
        result[1].add prepareNames(brack)
        # handle dotexpr
        result[1].handleDotExpr(dotexpr, tgt)
        idxIncr()
      else:
        discard
  else:
    while node.kind == nnkCommand:
      var item = node[0]
      node = node[1]
      ## handle `\` for line wrap
      if node.kind == nnkInfix:
        node = nnkCommand.newTree(node[1], node[2])
      case item.kind:
      of nnkBracket:
        result[1].add prepareNames(item)
      of nnkIdent:
        if item.strVal != "auto":
          error("argument must be 'auto'", item)
        result[1].add quote do:
          `tgt`[`idxLit`].track = csAuto()
        idxIncr()
      of nnkDotExpr:
        result[1].handleDotExpr(item, tgt)
        idxIncr()
      else:
        discard
  ## add final implicit line
  if node.kind == nnkBracket:
    result[1].add prepareNames(node)
  elif node.kind == nnkDotExpr:
    var item = node
    result[1].handleDotExpr(item, tgt)
    idxIncr()

  result[1].add quote do:
    `tgt`[`idxLit`].track = csEnd()
    # grids.add move(gl)
  result[0] = idx + 1

macro gridTemplateImpl*(gridTmpl, args: untyped, field: untyped) =
  echo "gridTemplateImpl: ", args.treeRepr
  result = newStmtList()
  let tgt = quote do:
    `gridTmpl`.`field`
  let (colCount, cols) = parseTmplCmd(tgt, args)
  result.add quote do:
    if `gridTmpl`.isNil:
      `gridTmpl` = newGridTemplate()
    block:
      if `gridTmpl`.`field`.len() < `colCount`:
        `gridTmpl`.`field`.setLen(`colCount`)
        `cols`
  # echo "result: ", result.repr