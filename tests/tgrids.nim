import typetraits
import sequtils

import unittest
import cssgrid/numberTypes
import cssgrid/gridtypes
import cssgrid/layout
import cssgrid/parser

import pretty
import macros


type
  GridNode* = ref object
    id: string
    box: UiBox
    gridItem: GridItem

proc `box=`*[T](v: T, box: UiBox) = 
  v.box = box

template printChildrens(start = 0) =
  for i in start ..< nodes.len():
    # echo "child:cols: ", nodes[i].id, " :: ", nodes[i].gridItem.span[dcol].repr, " x ", nodes[i].gridItem.span[drow].repr
    echo "\tchild:box: ", nodes[i].id, " => ", nodes[i].box, " span: ", nodes[i].gridItem.span.repr

template checkUiFloats(af, bf, ln, ls) =
  if abs(af.float-bf.float) >= 1.0e-3:
    checkpoint(`ln` & ":\n\tCheck failed: " & `ls` & "\n\tfield: " & astToStr(af) & " " & " value was: " & $af & " expected: " & $bf)
    fail()

macro checks(args: untyped{nkInfix}) =
  let a = args[1]
  let b = args[2]
  let ln = args.lineinfo()
  let ls = args.repr()
  result = quote do:

    when `a` is SomeFloat:
      if abs(`a`-`b`) >= 1.0e-3:
        checkpoint(`ln` & ": Check failed: " & `ls` & " value was: " & $`a` & " expected: " & $`b`)
        fail()
    when `a` is UiBox:
      checkUiFloats(`a`.x,`b`.x, `ln`, `ls`)
      checkUiFloats(`a`.y,`b`.y, `ln`, `ls`)
      checkUiFloats(`a`.w,`b`.w, `ln`, `ls`)
      checkUiFloats(`a`.h,`b`.h, `ln`, `ls`)
    when `a` is UiSize:
      checkUiFloats(`a`.x,`b`.x, `ln`, `ls`)
      checkUiFloats(`a`.y,`b`.y, `ln`, `ls`)
  result.copyLineInfo(args)

suite "grids":

  test "basic grid template":
    var gt = newGridTemplate(
      columns = @[initGridLine(csFrac(1))],
      rows = @[initGridLine(csFrac(1))],
    )
    check gt.lines[dcol].len() == 1
    check gt.lines[drow].len() == 1

  test "basic grid compute":
    var gt = newGridTemplate(
      columns = @[initGridLine 1'fr, initGridLine 1'fr],
      rows = @[gl 1'fr, gl 1'fr],
    )
    gt.computeTracks(uiBox(0, 0, 100, 100))
    # print "grid template: ", gt

    check gt.lines[dcol][0].start == 0.UiScalar
    check gt.lines[dcol][1].start == 50.UiScalar
    check gt.lines[drow][0].start == 0.UiScalar
    check gt.lines[drow][1].start == 50.UiScalar

  test "3x3 grid compute with frac's":
    var gt = newGridTemplate(
      columns = @[gl 1'fr, gl 1'fr, gl 1'fr],
      rows = @[gl 1'fr, gl 1'fr, gl 1'fr],
    )
    gt.computeTracks(uiBox(0, 0, 100, 100))
    # print "grid template: ", gt

    checks gt.lines[dcol][0].start.float == 0.0
    checks gt.lines[dcol][1].start.float == 33.3333
    checks gt.lines[dcol][2].start.float == 66.6666
    checks gt.lines[drow][0].start.float == 0.0
    checks gt.lines[drow][1].start.float == 33.3333
    checks gt.lines[drow][2].start.float == 66.6666

  test "4x1 grid test":
    var gt = newGridTemplate(
      columns = @[1'fr.gl, initGridLine(5.csFixed), 1'fr.gl, 1'fr.gl, initGridLine(csEnd())],
      rows = @[initGridLine(csEnd())],
    )
    gt.computeTracks(uiBox(0, 0, 100, 100))
    echo "grid template: ", gt

    checks gt.lines[dcol][0].start.float == 0.0
    checks gt.lines[dcol][1].start.float == 31.6666
    checks gt.lines[dcol][2].start.float == 36.6666
    checks gt.lines[dcol][3].start.float == 68.3333
    checks gt.lines[drow][0].start.float == 0.0

  test "initial macros":
    var gridTemplate: GridTemplate

    # grid-template-columns: [first] 40px [line2] 50px [line3] auto [col4-start] 50px [five] 40px [end];
    parseGridTemplateColumns gridTemplate, ["first"] 40'ux ["second", "line2"] 50'pp ["line3"] auto ["col4-start"] 50'ux ["five"] 40'ux ["end"]

    # gridTemplate.computeTracks(uiBox(0, 0, 100, 100))
    let gt = gridTemplate

    check gt.lines[dcol][0].track.value.kind == UiFixed
    check gt.lines[dcol][0].track.value.coord == 40.0.UiScalar
    # echo repr gt.lines[dcol][0].aliases.toSeq.mapIt(it.int), toLineNames("first").toSeq.mapIt(it.int)
    check gt.lines[dcol][0].aliases == toLineNames("first")
    check gt.lines[dcol][1].track.value.kind == UiPerc
    check gt.lines[dcol][1].track.value.perc == 50.0.UiScalar
    check gt.lines[dcol][1].aliases == toLineNames("second", "line2")
    check gt.lines[dcol][2].track.value.kind == UiAuto
    check gt.lines[dcol][2].aliases == toLineNames("line3")
    check gt.lines[dcol][3].track.value.kind == UiFixed
    check gt.lines[dcol][3].track.value.coord == 50.0.UiScalar
    check gt.lines[dcol][3].aliases == toLineNames("col4-start")
    check gt.lines[dcol][4].track.value.kind == UiFixed
    check gt.lines[dcol][4].track.value.coord == 40.0.UiScalar
    check gt.lines[dcol][4].aliases == toLineNames("five")
    check gt.lines[dcol][5].track.kind == UiEnd
    check toLineNames("end") == gt.lines[dcol][5].aliases

    # print "grid template: ", gridTemplate
    # echo "grid template: ", repr gridTemplate

  test "compute macros":
    var tmpl: GridTemplate

    # grid-template-columns: [first] 40px [line2] 50px [line3] auto [col4-start] 50px [five] 40px [end];
    parseGridTemplateColumns tmpl, ["first"] 40'ux \
      ["second", "line2"] 50'ux \
      ["line3"] auto \
      ["col4-start"] 50'ux \
      ["five"] 40'ux ["end"]
    parseGridTemplateRows tmpl, ["row1-start"] 25'pp ["row1-end"] 100'ux ["third-line"] auto ["last-line"]

    tmpl.computeTracks(uiBox(0, 0, 1000, 1000))
    let gt = tmpl
    # print "grid template: ", gridTemplate
    checks gt.lines[dcol][0].start.float == 0.0
    checks gt.lines[dcol][1].start.float == 40.0
    checks gt.lines[dcol][2].start.float == 90.0
    checks gt.lines[dcol][3].start.float == 910.0
    checks gt.lines[dcol][4].start.float == 960.0
    checks gt.lines[dcol][5].start.float == 1000.0

    checks gt.lines[drow][0].start.float == 0.0
    checks gt.lines[drow][1].start.float == 250.0
    checks gt.lines[drow][2].start.float == 350.0
    checks gt.lines[drow][3].start.float == 1000.0
    # echo "grid template: ", repr tmpl
    
  test "compute others":
    var gt: GridTemplate

    parseGridTemplateColumns gt, ["first"] 40'ux \
      ["second", "line2"] 50'ux \
      ["line3"] auto \
      ["col4-start"] 50'ux \
      ["five"] 40'ux ["end"]
    parseGridTemplateRows gt, ["row1-start"] 25'pp \
      ["row1-end"] 100'ux \
      ["third-line"] auto ["last-line"]

    gt.gaps[dcol] = 10.UiScalar
    gt.gaps[drow] = 10.UiScalar
    gt.computeTracks(uiBox(0, 0, 1000, 1000))
    # print "grid template: ", gt
    checks gt.lines[dcol][0].start.float == 0.0
    checks gt.lines[dcol][1].start.float == 50.0
    checks gt.lines[dcol][2].start.float == 110.0
    checks gt.lines[dcol][3].start.float == 890.0
    checks gt.lines[dcol][4].start.float == 950.0
    checks gt.lines[dcol][5].start.float == 1000.0

    checks gt.lines[drow][0].start.float == 0.0
    checks gt.lines[drow][1].start.float == 260.0
    checks gt.lines[drow][2].start.float == 370.0
    checks gt.lines[drow][3].start.float == 1000.0
    
  test "compute macro and item layout":
    var gridTemplate: GridTemplate

    # grid-template-columns: [first] 40px [line2] 50px [line3] auto [col4-start] 50px [five] 40px [end];
    parseGridTemplateColumns gridTemplate, ["first"] 40'ux ["second", "line2"] 50'ux ["line3"] auto ["col4-start"] 50'ux ["five"] 40'ux ["end"]
    parseGridTemplateRows gridTemplate, ["row1-start"] 25'pp ["row1-end"] 100'ux ["third-line"] auto ["last-line"]
    gridTemplate.computeTracks(uiBox(0, 0, 1000, 1000))
    # echo "grid template: ", repr gridTemplate

    var gridItem = newGridItem()
    gridItem.column.a = 2.mkIndex
    gridItem.column.b = "five".mkIndex
    gridItem.row.a = "row1-start".mkIndex
    gridItem.row.b = 3.mkIndex
    # print gridItem
    let node = GridNode(box: uiBox(0, 0, 0, 0), gridItem: gridItem)
    gridItem.setGridSpans(gridTemplate, node.box.wh)

    let itemBox = node.computeBox(gridTemplate)
    # print itemBox
    # print "post: ", gridItem

    check gridItem.span[dcol].a == 2
    check gridItem.span[dcol].b == 5
    checks itemBox.x.float == 40.0
    checks itemBox.w.float == 920.0
    checks itemBox.y.float == 0.0
    checks itemBox.h.float == 350.0

  test "compute macro and item layout":
    var gridTemplate: GridTemplate

    # grid-template-columns: [first] 40px [line2] 50px [line3] auto [col4-start] 50px [five] 40px [end];
    parseGridTemplateColumns gridTemplate, [first] 40'ux ["second", "line2"] 50'ux \
        ["line3"] auto ["col4-start"] 50'ux ["five"] 40'ux ["end"]
    parseGridTemplateRows gridTemplate, ["row1-start"] 25'pp ["row1-end"] 100'ux \
        ["third-line"] auto ["last-line"]
    gridTemplate.computeTracks(uiBox(0, 0, 1000, 1000))
    # echo "grid template: ", repr gridTemplate

    let contentSize = uiSize(500, 200)
    var gridItem = newGridItem()
    gridItem.column.a = 2.mkIndex
    gridItem.column.b = "five".mkIndex
    gridItem.row.a = "row1-start".mkIndex
    gridItem.row.b = 3.mkIndex
    gridItem.setGridSpans(gridTemplate, contentSize)
    let node = GridNode(box: uiBox(0, 0, contentSize.x.float, contentSize.y.float), gridItem: gridItem)
    echo gridTemplate

    ## test stretch
    var itemBox: UiBox
    gridTemplate.justifyItems = CxStretch
    gridTemplate.alignItems = CxStretch
    itemBox = node.computeBox(gridTemplate)
    # print itemBox
    checks itemBox == uiBox(40, 0, 920, 350)

    ## test start
    gridTemplate.justifyItems = CxStart
    gridTemplate.alignItems = CxStart
    itemBox = node.computeBox(gridTemplate)
    # print itemBox
    checks itemBox == uiBox(40, 0, 500, 200)

    ## test end
    gridTemplate.justifyItems = CxEnd
    gridTemplate.alignItems = CxEnd
    itemBox = node.computeBox(gridTemplate)
    # print itemBox
    checks itemBox == uiBox(460, 150, 500, 200)
    
    ## test start / stretch
    gridTemplate.justifyItems = CxStart
    gridTemplate.alignItems = CxStretch
    itemBox = node.computeBox(gridTemplate)
    echo ""
    print itemBox
    checks itemBox == uiBox(40, 0, 500, 350)

    ## test stretch / start
    gridTemplate.justifyItems = CxStretch
    gridTemplate.alignItems = CxStart
    itemBox = node.computeBox(gridTemplate)
    echo ""
    print itemBox
    checks itemBox == uiBox(40, 0, 920, 200)
    
    ## test stretch / start
    gridTemplate.justifyItems = CxCenter
    gridTemplate.alignItems = CxCenter
    itemBox = node.computeBox(gridTemplate)
    echo ""
    print itemBox
    # 920/2-500/2+40
    # 350/2-200/2+0
    checks itemBox == uiBox(250, 75, 500, 200)
    
    
  test "compute layout with auto columns":
    var gridTemplate: GridTemplate

    # grid-template-columns: [first] 40px [line2] 50px [line3] auto [col4-start] 50px [five] 40px [end];
    parseGridTemplateColumns gridTemplate, ["a"] 60'ux ["b"] 60'ux
    parseGridTemplateRows gridTemplate, 90'ux 90'ux
    # echo "grid template pre: ", repr gridTemplate
    check gridTemplate.lines[dcol].len() == 3
    check gridTemplate.lines[drow].len() == 3
    # echo "grid template: ", repr gridTemplate

    let contentSize = uiSize(120, 90)

    # item a
    var itema = newGridItem()
    itema.column = 1 // 2
    itema.row = 2 // 3

    itema.setGridSpans(gridTemplate, contentSize)

    # item b
    var itemb = newGridItem()
    itemb.column = 5 // 6
    itemb.row = 2 // 3

    itemb.setGridSpans(gridTemplate, contentSize)

    gridTemplate.computeTracks(uiBox(0, 0, 1000, 1000))
    ## computes
    ## 
    let nodea = GridNode(box: uiBox(0, 0, contentSize.x.float, contentSize.y.float),
                         gridItem: itema)
    let nodeb = GridNode(box: uiBox(0, 0, contentSize.x.float, contentSize.y.float),
                         gridItem: itemb)

    echo "BOXA: ", nodea.gridItem
    echo "BOXB: ", nodeb.gridItem
    let boxa = nodea.computeBox(gridTemplate)
    let boxb = nodeb.computeBox(gridTemplate)

    gridTemplate.computeTracks(uiBox(0, 0, 1000, 1000))

    echo "gridTemplate: ", gridTemplate
    checks boxa == uiBox(0, 90, 60, 90)
    checks boxb == uiBox(120, 90, 00, 90)

  test "compute layout with fixed 1x1":
    var gridTemplate: GridTemplate

    parseGridTemplateColumns gridTemplate, 60'ux
    parseGridTemplateRows gridTemplate, 90'ux
    # echo "grid template pre: ", repr gridTemplate
    check gridTemplate.lines[dcol].len() == 2
    check gridTemplate.lines[drow].len() == 2
    # echo "grid template: ", repr gridTemplate

    let contentSize = uiSize(120, 90)

    # item a
    var itema = newGridItem()
    itema.column = 1 // 2
    itema.row = 1 // 2

    itema.setGridSpans(gridTemplate, contentSize)
    gridTemplate.computeTracks(uiBox(0, 0, 1000, 1000))
    let nodea = GridNode(box: uiBox(0, 0, contentSize.x.float, contentSize.y.float), gridItem: itema)
    let boxa = nodea.computeBox(gridTemplate)
    checks boxa == uiBox(0, 0, 60, 90)
    

  test "compute layout with auto columns with fixed size":
    var gridTemplate: GridTemplate

    # grid-template-columns: [first] 40px [line2] 50px [line3] auto [col4-start] 50px [five] 40px [end];
    parseGridTemplateColumns gridTemplate, ["a"] 60'ux ["b"] 60'ux
    parseGridTemplateRows gridTemplate, 90'ux 90'ux
    gridTemplate.autos[dcol] = 60.csFixed()
    gridTemplate.autos[drow] = 20.csFixed()
    # echo "grid template pre: ", repr gridTemplate
    check gridTemplate.lines[dcol].len() == 3
    check gridTemplate.lines[drow].len() == 3

    let contentSize = uiSize(30, 30)

    # item a
    var itema = newGridItem()
    itema.column = 1 // 2
    itema.row = 2 // 3
    itema.setGridSpans(gridTemplate, contentSize)

    # item b
    var itemb = newGridItem()
    itemb.column = 5 // 6
    itemb.row = 3 // 4
    itemb.setGridSpans(gridTemplate, contentSize)

    gridTemplate.computeTracks(uiBox(0, 0, 1000, 1000))
    let nodea = GridNode(box: uiBox(0, 0, contentSize.x.float, contentSize.y.float), gridItem: itema)
    let nodeb = GridNode(box: uiBox(0, 0, contentSize.x.float, contentSize.y.float), gridItem: itemb)
    let boxa = nodea.computeBox(gridTemplate)
    checks boxa == uiBox(0, 90, 60, 90)

    let boxb = nodeb.computeBox(gridTemplate)
    checks boxb == uiBox(240, 180, 60, 20)

  test "compute layout with auto flow":
    var gridTemplate: GridTemplate

    # grid-template-columns: [first] 40px [line2] 50px [line3] auto [col4-start] 50px [five] 40px [end];
    parseGridTemplateColumns gridTemplate, 60'ux 60'ux 60'ux 60'ux 60'ux
    parseGridTemplateRows gridTemplate, 33'ux 33'ux
    gridTemplate.justifyItems = CxStretch
    # echo "grid template pre: ", repr gridTemplate
    check gridTemplate.lines[dcol].len() == 6
    check gridTemplate.lines[drow].len() == 3
    gridTemplate.computeTracks(uiBox(0, 0, 1000, 1000))
    # echo "grid template: ", repr gridTemplate
    var parent = GridNode()

    let contentSize = uiSize(30, 30)
    var nodes = newSeq[GridNode](8)

    # item a
    var itema = newGridItem()
    itema.column = 1 // 2
    itema.row = 1 // 3
    # let boxa = itema.computeTracks(gridTemplate, contentSize)
    nodes[0] = GridNode(id: "a", gridItem: itema)

    # ==== item e ====
    var iteme = newGridItem()
    iteme.column = 5 // 6
    iteme.row = 1 // 3
    nodes[1] = GridNode(id: "e", gridItem: iteme)

    # ==== item b's ====
    for i in 2 ..< nodes.len():
      nodes[i] = GridNode(id: "b" & $(i-2))

    # ==== process grid ====
    discard gridTemplate.computeNodeLayout(parent, nodes)

    # echo "grid template post: ", repr gridTemplate
    # ==== item a ====
    checks nodes[0].box == uiBox(0, 0, 60, 66)

    # ==== item e ====
    # print nodes[1].box
    checks nodes[1].box == uiBox(240, 0, 60, 66)

    # ==== item b's ====
    # printChildrens(2)

    checks nodes[2].box.xy == uiSize(60, 0)
    checks nodes[3].box.xy == uiSize(120, 0)
    checks nodes[4].box.xy == uiSize(180, 0)

    checks nodes[5].box.xy == uiSize(60, 33)
    checks nodes[6].box.xy == uiSize(120, 33)
    checks nodes[7].box.xy == uiSize(180, 33)

    for i in 2 ..< nodes.len() - 1:
      checks nodes[i].box.wh == uiSize(60, 33)

  test "compute layout auto flow overflow":
    var gridTemplate: GridTemplate

    parseGridTemplateColumns gridTemplate, 100'ux
    parseGridTemplateRows gridTemplate, 100'ux
    gridTemplate.autos[drow] = csFixed 100.0
    gridTemplate.justifyItems = CxStretch
    gridTemplate.computeTracks(uiBox(0, 0, 1000, 1000))
    var parent = GridNode()

    var nodes = newSeq[GridNode](4)

    # ==== item a's ====
    for i in 0 ..< nodes.len():
      nodes[i] = GridNode(id: "b" & $(i))

    # ==== process grid ====
    let box = gridTemplate.computeNodeLayout(parent, nodes)

    check box.w == 100
    check box.h == 400

    check nodes[0].gridItem.span[dcol] == 1'i16 .. 2'i16
    check nodes[0].gridItem.span[drow] == 1'i16 .. 2'i16
    check nodes[1].gridItem.span[dcol] == 1'i16 .. 2'i16
    check nodes[1].gridItem.span[drow] == 2'i16 .. 3'i16

    checks nodes[0].box == uiBox(0, 0, 100, 100)
    checks nodes[1].box == uiBox(0, 100, 100, 100)
    checks nodes[3].box == uiBox(0, 300, 100, 100)

  test "compute layout auto flow overflow (columnar)":
    var gridTemplate: GridTemplate

    parseGridTemplateColumns gridTemplate, 1'fr
    parseGridTemplateRows gridTemplate, 1'fr
    gridTemplate.autos[dcol] = csFixed 100.0
    gridTemplate.justifyItems = CxStretch
    gridTemplate.autoFlow = grColumn
    # echo "grid template pre: ", repr gridTemplate
    # gridTemplate.computeTracks(uiBox(0, 0, 1000, 1000))
    # echo "grid template: ", repr gridTemplate
    var parent = GridNode()
    parent.box.w = 50
    parent.box.h = 50

    var nodes = newSeq[GridNode](8)

    # ==== item a's ====
    for i in 0 ..< nodes.len():
      nodes[i] = GridNode(id: "b" & $(i), box: uiBox(0,0,50,50))

    # ==== process grid ====
    discard gridTemplate.computeNodeLayout(parent, nodes)
    # echo "grid template:1: ", repr gridTemplate
    let box = gridTemplate.computeNodeLayout(parent, nodes)
    # echo "grid template:2: ", repr gridTemplate
    # print box

    # echo "grid template post: ", repr gridTemplate
    # ==== item a's ====
    # printChildrens(0)
    # echo "grid template:post: ", gridTemplate
    # print gridTemplate.overflowSizes

    check box.w == 750
    check box.h == 50
    checks nodes[0].gridItem.span[dcol] == 1'i16 .. 2'i16
    checks nodes[0].gridItem.span[drow] == 1'i16 .. 2'i16
    checks nodes[1].gridItem.span[dcol] == 2'i16 .. 3'i16
    checks nodes[1].gridItem.span[drow] == 1'i16 .. 2'i16

    checks nodes[0].box == uiBox(0, 0, 50, 50)
    checks nodes[1].box == uiBox(50, 0, 100, 50)

  test "compute layout overflow (columnar)":
    var gridTemplate: GridTemplate

    parseGridTemplateColumns gridTemplate, 1'fr
    parseGridTemplateRows gridTemplate, 1'fr
    gridTemplate.autos[dcol] = csContentMax()
    gridTemplate.justifyItems = CxStretch
    gridTemplate.autoFlow = grColumn
    # echo "grid template pre: ", repr gridTemplate
    # gridTemplate.computeTracks(uiBox(0, 0, 1000, 1000))
    # echo "grid template: ", repr gridTemplate
    var parent = GridNode()
    parent.box.w = 50
    parent.box.h = 50

    let contentSize = uiSize(30, 30)
    var nodes = newSeq[GridNode](8)

    # ==== item a's ====
    for i in 0 ..< nodes.len():
      nodes[i] = GridNode(id: "b" & $(i),
                          box: uiBox(0,0,50,50),
                          gridItem: GridItem())
      nodes[i].gridItem.index[drow] = mkIndex(1) .. mkIndex(2)
      nodes[i].gridItem.index[dcol] = mkIndex(i+1) .. mkIndex(i+2)
    nodes[7].box.w = 150

    # ==== process grid ====
    let box = gridTemplate.computeNodeLayout(parent, nodes)
    # echo "grid template:1: ", repr gridTemplate
    # print box
    # echo "grid template post: ", gridTemplate

    # echo "grid template post: ", repr gridTemplate
    # ==== item a's ====
    # printChildrens(0)

    # echo "grid template:post: ", gridTemplate
    print gridTemplate.overflowSizes

    check box.w == 500
    check box.h == 50
    check nodes[0].gridItem.span[dcol] == 1'i16 .. 2'i16
    check nodes[0].gridItem.span[drow] == 1'i16 .. 2'i16
    check nodes[1].gridItem.span[dcol] == 2'i16 .. 3'i16
    check nodes[1].gridItem.span[drow] == 1'i16 .. 2'i16

    checks nodes[0].box == uiBox(0, 0, 50, 50)
    checks nodes[1].box == uiBox(50, 0, 50, 50)
    for i in 0..6:
      checks nodes[i].box.wh == uiSize(50, 50)

    checks nodes[7].box == uiBox(350, 0, 150, 50)

  test "compute layout overflow (rows)":
    var gridTemplate: GridTemplate

    parseGridTemplateColumns gridTemplate, 1'fr
    parseGridTemplateRows gridTemplate, 50'ux
    gridTemplate.autos[drow] = 50'ux
    gridTemplate.justifyItems = CxStretch
    gridTemplate.autoFlow = grRow
    var parent = GridNode()
    parent.box.w = 50
    parent.box.h = 50

    let contentSize = uiSize(30, 30)
    var nodes = newSeq[GridNode](8)

    # ==== item a's ====
    for i in 0 ..< nodes.len():
      nodes[i] = GridNode(id: "b" & $(i),
                          box: uiBox(0,0,50,50),
                          gridItem: nil)
      # nodes[i].gridItem.index[drow] = mkIndex(1) .. mkIndex(2)
      # nodes[i].gridItem.index[dcol] = mkIndex(i+1) .. mkIndex(i+2)
    nodes[7].box.w = 150
    check gridTemplate.lines[dcol][0].track == 1'fr

    # ==== process grid ====
    let box = gridTemplate.computeNodeLayout(parent, nodes)
    # echo "grid template:post: ", gridTemplate
    # echo "grid template:post: ", repr gridTemplate
    # echo ""
    # printChildrens()
    # print gridTemplate.overflowSizes

    # check box.w == 50
    # check box.h == 500
    check nodes[0].gridItem.span[dcol] == 1'i16 .. 2'i16
    check nodes[0].gridItem.span[drow] == 1'i16 .. 2'i16
    check nodes[1].gridItem.span[dcol] == 1'i16 .. 2'i16
    check nodes[1].gridItem.span[drow] == 2'i16 .. 3'i16

    checks nodes[0].box == uiBox(0, 0, 50, 50)
    checks nodes[1].box == uiBox(0, 50, 50, 50)

    for i in 0..6:
      checks nodes[i].box.wh == uiSize(50, 50)

    checks nodes[7].box == uiBox(0, 350, 50, 50)

  test "compute layout manual overflow (rows)":
    var gridTemplate: GridTemplate

    parseGridTemplateColumns gridTemplate, 1'fr
    # parseGridTemplateRows gridTemplate, 1'fr
    gridTemplate.autos[drow] = csContentMin()
    gridTemplate.justifyItems = CxStretch
    gridTemplate.autoFlow = grRow
    var parent = GridNode()
    parent.box.w = 50
    parent.box.h = 50

    let contentSize = uiSize(30, 30)
    var nodes = newSeq[GridNode](8)

    # ==== item a's ====
    for i in 0 ..< nodes.len():
      nodes[i] = GridNode(id: "b" & $(i),
                          box: uiBox(0,0,50,50),
                          gridItem: GridItem())
      nodes[i].gridItem.index[dcol] = mkIndex(1) .. mkIndex(2)
      nodes[i].gridItem.index[drow] = mkIndex(i+1) .. mkIndex(i+2)
    nodes[2].box.h = 150
    check gridTemplate.lines[dcol][0].track == 1'fr

    # ==== process grid ====
    let box1 = gridTemplate.computeNodeLayout(parent, nodes)
    let box = gridTemplate.computeNodeLayout(parent, nodes)
    # echo "grid template:post: ", gridTemplate
    # echo ""
    # printChildrens()
    # print gridTemplate.overflowSizes

    check box.w == 50
    check box.h == 500
    check nodes[0].gridItem.span[dcol] == 1'i16 .. 2'i16
    check nodes[0].gridItem.span[drow] == 1'i16 .. 2'i16
    check nodes[1].gridItem.span[dcol] == 1'i16 .. 2'i16
    check nodes[1].gridItem.span[drow] == 2'i16 .. 3'i16

    checks nodes[0].box == uiBox(0, 0, 50, 50)
    checks nodes[1].box == uiBox(0, 50, 50, 50)
    checks nodes[2].box == uiBox(0, 100, 50, 150)
    checks nodes[3].box == uiBox(0, 250, 50, 50)

    for i in 0..7:
      if i != 2:
        checks nodes[i].box.wh == uiSize(50, 50)

    checks nodes[7].box == uiBox(0, 450, 50, 50)

  test "compute layout manual overflow (rows)":
    var gridTemplate: GridTemplate

    parseGridTemplateColumns gridTemplate, 1'fr
    parseGridTemplateRows gridTemplate, 1'fr
    gridTemplate.autos[drow] = 1'fr
    gridTemplate.justifyItems = CxStart
    gridTemplate.autoFlow = grRow
    var parent = GridNode()
    parent.box.w = 50
    parent.box.h = 400

    var nodes = newSeq[GridNode](8)

    # ==== item a's ====
    for i in 0 ..< nodes.len():
      nodes[i] = GridNode(id: "b" & $(i),
                          box: uiBox(0,0,200,200),
                          gridItem: GridItem())
      nodes[i].gridItem.index[dcol] = mkIndex(1) .. mkIndex(2)
      nodes[i].gridItem.index[drow] = mkIndex(i+1) .. mkIndex(i+2)
    nodes[2].box.h = 150
    check gridTemplate.lines[dcol][0].track == 1'fr

    # ==== process grid ====
    let box1 = gridTemplate.computeNodeLayout(parent, nodes)
    let box = gridTemplate.computeNodeLayout(parent, nodes)
    echo "grid template:post: ", gridTemplate
    echo ""
    printChildrens()
    print gridTemplate.overflowSizes

    check box.w == 50
    check box.h == 400
    check nodes[0].gridItem.span[dcol] == 1'i16 .. 2'i16
    check nodes[0].gridItem.span[drow] == 1'i16 .. 2'i16
    check nodes[1].gridItem.span[dcol] == 1'i16 .. 2'i16
    check nodes[1].gridItem.span[drow] == 2'i16 .. 3'i16

    checks nodes[0].box == uiBox(0, 0, 50, 50)
    checks nodes[1].box == uiBox(0, 50, 50, 50)
    checks nodes[2].box == uiBox(0, 100, 50, 50)
    checks nodes[3].box == uiBox(0, 150, 50, 50)

    for i in 0..7:
      if i != 2:
        checks nodes[i].box.wh == uiSize(50, 50)

    checks nodes[7].box == uiBox(0, 350, 50, 50)
    # echo "nodes[7]: ", nodes[7].box

  test "compute layout auto only":
    var gridTemplate: GridTemplate

    parseGridTemplateColumns gridTemplate, 1'fr
    # parseGridTemplateRows gridTemplate, 1'fr
    gridTemplate.autos[drow] = 90'ux
    gridTemplate.justifyItems = CxStart
    gridTemplate.autoFlow = grRow
    var parent = GridNode()
    parent.box.w = 50
    parent.box.h = 400

    var nodes = newSeq[GridNode](8)

    # ==== item a's ====
    for i in 0 ..< nodes.len():
      nodes[i] = GridNode(id: "b" & $(i),
                          box: uiBox(0,0,200,200),
                          gridItem: GridItem())
      # nodes[i].gridItem.index[dcol] = mkIndex(1) .. mkIndex(2)
      # nodes[i].gridItem.index[drow] = mkIndex(i+1) .. mkIndex(i+2)
    nodes[2].box.h = 150
    check gridTemplate.lines[dcol][0].track == 1'fr

    # ==== process grid ====
    let box1 = gridTemplate.computeNodeLayout(parent, nodes)
    let box = gridTemplate.computeNodeLayout(parent, nodes)
    echo "grid template:post: ", gridTemplate
    echo ""
    printChildrens()
    print gridTemplate.overflowSizes

    check gridTemplate.lines[drow].len() == 9
    # check box.w == 50
    # check box.h == 400
    # check nodes[0].gridItem.span[dcol] == 1'i16 .. 2'i16
    # check nodes[0].gridItem.span[drow] == 1'i16 .. 2'i16
    # check nodes[1].gridItem.span[dcol] == 1'i16 .. 2'i16
    # check nodes[1].gridItem.span[drow] == 2'i16 .. 3'i16

    # checks nodes[0].box == uiBox(0, 0, 50, 50)
    # checks nodes[1].box == uiBox(0, 50, 50, 50)
    # checks nodes[2].box == uiBox(0, 100, 50, 50)
    # checks nodes[3].box == uiBox(0, 150, 50, 50)

    # for i in 0..7:
    #   if i != 2:
    #     checks nodes[i].box.wh == uiSize(50, 50)

    # checks nodes[7].box == uiBox(0, 350, 50, 50)