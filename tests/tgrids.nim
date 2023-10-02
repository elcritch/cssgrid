import typetraits
import sequtils

import unittest
import cssgrid/numberTypes
import cssgrid/gridtypes
import cssgrid/layout
import cssgrid/parser

import pretty

type
  GridNode* = ref object
    id: string
    box: UiBox
    gridItem: GridItem

proc `box=`*[T](v: T, box: UiBox) = 
  v.box = box

import macros
macro checks(args: untyped{nkInfix}) =
  let a = args[1]
  let b = args[2]
  let ln = args.lineinfo()
  let ls = args.repr()
  result = quote do:
    if abs(`a`-`b`) >= 1.0e-3:
      checkpoint(`ln` & ": Check failed: " & `ls` & " value was: " & $`a`)
      fail()
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
      columns = @[1'fr.gl, initGridLine(5.csFixed), 1'fr.gl, 1'fr.gl],
    )
    gt.computeTracks(uiBox(0, 0, 100, 100))
    # print "grid template: ", gt

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
    check gt.lines[dcol][2].track.kind == UiAuto
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
    let contentSize = uiSize(0, 0)
    gridItem.setGridSpans(gridTemplate, contentSize)

    let itemBox = gridItem.computeBox(gridTemplate, contentSize)
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
    parseGridTemplateColumns gridTemplate, [first] 40'ux ["second", "line2"] 50'ux ["line3"] auto ["col4-start"] 50'ux ["five"] 40'ux ["end"]
    parseGridTemplateRows gridTemplate, ["row1-start"] 25'pp ["row1-end"] 100'ux ["third-line"] auto ["last-line"]
    gridTemplate.computeTracks(uiBox(0, 0, 1000, 1000))
    # echo "grid template: ", repr gridTemplate

    let contentSize = uiSize(500, 200)
    var gridItem = newGridItem()
    gridItem.column.a = 2.mkIndex
    gridItem.column.b = "five".mkIndex
    gridItem.row.a = "row1-start".mkIndex
    gridItem.row.b = 3.mkIndex
    gridItem.setGridSpans(gridTemplate, contentSize)
    # print gridItem

    ## test stretch
    var itemBox: UiBox
    itemBox = gridItem.computeBox(gridTemplate, contentSize)
    # print itemBox
    checks itemBox.x.float == 40.0
    checks itemBox.w.float == 920.0
    checks itemBox.y.float == 0.0
    checks itemBox.h.float == 350.0

    ## test start
    gridTemplate.justifyItems = CxStart
    gridTemplate.alignItems = CxStart
    itemBox = gridItem.computeBox(gridTemplate, contentSize)
    # print itemBox
    checks itemBox.x.float == 40.0
    checks itemBox.w.float == 500.0
    checks itemBox.y.float == 0.0
    checks itemBox.h.float == 200.0

    ## test end
    gridTemplate.justifyItems = CxEnd
    gridTemplate.alignItems = CxEnd
    itemBox = gridItem.computeBox(gridTemplate, contentSize)
    # print itemBox
    checks itemBox.x.float == 460.0
    checks itemBox.w.float == 500.0
    checks itemBox.y.float == 150.0
    checks itemBox.h.float == 200.0
    
    ## test start / stretch
    gridTemplate.justifyItems = CxStart
    gridTemplate.alignItems = CxStretch
    itemBox = gridItem.computeBox(gridTemplate, contentSize)
    # print itemBox
    checks itemBox.x.float == 40.0
    checks itemBox.w.float == 500.0
    checks itemBox.y.float == 0.0
    checks itemBox.h.float == 350.0
    
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
    let boxa = itema.computeBox(gridTemplate, contentSize)
    # echo "grid template post: ", repr gridTemplate

    let boxb = itemb.computeBox(gridTemplate, contentSize)
    # echo "grid template post: ", repr gridTemplate

    gridTemplate.computeTracks(uiBox(0, 0, 1000, 1000))

    # print gridTemplate

    # print boxa
    checks boxa.x.float == 0.0
    checks boxa.y.float == 90.0
    checks boxa.w.float == 60.0
    checks boxa.h.float == 90.0

    # print boxb
    checks boxb.x.float == 120.0
    checks boxb.y.float == 90.0
    checks boxb.w.float == 0.0
    checks boxb.h.float == 90.0

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
    # echo "setGridSpans:itema"
    # print itema

    gridTemplate.computeTracks(uiBox(0, 0, 1000, 1000))
    ## computes
    ## 
    let boxa = itema.computeBox(gridTemplate, contentSize)
    # echo "boxa"
    # print boxa
    # echo "grid template post: ", repr gridTemplate
    # print gridTemplate

    # print boxa
    checks boxa.x.float == 0.0
    checks boxa.y.float == 0.0
    checks boxa.w.float == 60.0
    checks boxa.h.float == 90.0
    

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
    # echo "grid template: ", repr gridTemplate
    # echo "grid template post: ", repr gridTemplate
    # print gridTemplate

    let boxa = itema.computeBox(gridTemplate, contentSize)
    # print boxa

    checks boxa.x.float == 0.0
    checks boxa.w.float == 60.0
    checks boxa.y.float == 90.0
    checks boxa.h.float == 90.0

    let boxb = itemb.computeBox(gridTemplate, contentSize)
    # echo "grid template post: ", repr gridTemplate
    # print boxb
    checks boxb.x.float == 240.0
    checks boxb.y.float == 180.0
    checks boxb.w.float == 60.0
    checks boxb.h.float == 20.0

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
    gridTemplate.computeNodeLayout(parent, nodes)

    # echo "grid template post: ", repr gridTemplate
    # ==== item a ====
    checks nodes[0].box.x.float == 0.0
    checks nodes[0].box.w.float == 60.0
    checks nodes[0].box.y.float == 0.0
    checks nodes[0].box.h.float == 66.0

    # ==== item e ====
    # print nodes[1].box
    checks nodes[1].box.x.float == 240.0
    checks nodes[1].box.w.float == 60.0
    checks nodes[1].box.y.float == 0.0
    checks nodes[1].box.h.float == 66.0

    # ==== item b's ====
    # for i in 2 ..< nodes.len():
    #   echo "auto child:cols: ", nodes[i].id, " :: ", nodes[i].gridItem.span[dcol].repr, " x ", nodes[i].gridItem.span[drow].repr
    #   echo "auto child:cols: ", nodes[i].gridItem.repr
    #   echo "auto child:box: ", nodes[i].id, " => ", nodes[i].box

    checks nodes[2].box.x.float == 60.0
    checks nodes[3].box.x.float == 120.0
    checks nodes[4].box.x.float == 180.0

    checks nodes[2].box.y.float == 0.0
    checks nodes[3].box.y.float == 0.0
    checks nodes[4].box.y.float == 0.0

    checks nodes[5].box.x.float == 60.0
    checks nodes[6].box.x.float == 120.0

    checks nodes[5].box.y.float == 33.0
    checks nodes[6].box.y.float == 33.0
    checks nodes[7].box.y.float == 33.0

    for i in 2 ..< nodes.len() - 1:
      checks nodes[i].box.w.float == 60.0
      checks nodes[i].box.h.float == 33.0

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
    gridTemplate.computeNodeLayout(parent, nodes)

    # echo "grid template post: ", repr gridTemplate
    # ==== item a's ====
    # for i in 0 ..< nodes.len():
    #   echo "auto child:cols: ", nodes[i].id, " :: ", nodes[i].gridItem.span[dcol].repr, " x ", nodes[i].gridItem.span[drow].repr
    #   echo "auto child:cols: ", nodes[i].gridItem.span.repr
    #   echo "auto child:box: ", nodes[i].id, " => ", nodes[i].box

    check parent.box.w == 100
    check parent.box.h == 400

    check nodes[0].gridItem.span[dcol] == 1'i16 .. 2'i16
    check nodes[0].gridItem.span[drow] == 1'i16 .. 2'i16
    check nodes[1].gridItem.span[dcol] == 1'i16 .. 2'i16
    check nodes[1].gridItem.span[drow] == 2'i16 .. 3'i16

    check nodes[0].box.x.float == 0.0
    check nodes[0].box.y.float == 0.0
    check nodes[0].box.w.float == 100.0
    check nodes[0].box.h.float == 100.0

    check nodes[1].box.x.float == 0.0
    check nodes[1].box.y.float == 100.0
    check nodes[1].box.w.float == 100.0
    check nodes[1].box.h.float == 100.0

    check nodes[3].box.x.float == 0.0
    check nodes[3].box.y.float == 300.0
    check nodes[3].box.w.float == 100.0
    check nodes[3].box.h.float == 100.0

  test "compute layout auto flow overflow (columnar)":
    var gridTemplate: GridTemplate

    parseGridTemplateColumns gridTemplate, 1'fr
    parseGridTemplateRows gridTemplate, 1'fr
    gridTemplate.autos[dcol] = csFixed 100.0
    gridTemplate.justifyItems = CxStretch
    gridTemplate.autoFlow = grColumn
    # echo "grid template pre: ", repr gridTemplate
    gridTemplate.computeTracks(uiBox(0, 0, 1000, 1000))
    # echo "grid template: ", repr gridTemplate
    var parent = GridNode()
    parent.box.w = 50
    parent.box.h = 50

    let contentSize = uiSize(30, 30)
    var nodes = newSeq[GridNode](2)

    # ==== item a's ====
    for i in 0 ..< nodes.len():
      nodes[i] = GridNode(id: "b" & $(i))

    # ==== process grid ====
    gridTemplate.computeNodeLayout(parent, nodes)

    # echo "grid template post: ", repr gridTemplate
    # ==== item a's ====
    # for i in 0 ..< nodes.len():
      # echo "auto child:cols: ", nodes[i].id, " :: ", nodes[i].gridItem.span[dcol].repr, " x ", nodes[i].gridItem.span[drow].repr
      # echo "auto child:cols: ", nodes[i].gridItem.span.repr
      # echo "auto child:box: ", nodes[i].id, " => ", nodes[i].box

    # echo "grid template:post: ", repr gridTemplate
    # print gridTemplate.overflowSizes

    check parent.box.w == 150
    check parent.box.h == 50
    check nodes[0].gridItem.span[dcol] == 1'i16 .. 2'i16
    check nodes[0].gridItem.span[drow] == 1'i16 .. 2'i16
    check nodes[1].gridItem.span[dcol] == 2'i16 .. 3'i16
    check nodes[1].gridItem.span[drow] == 1'i16 .. 2'i16

    check nodes[0].box.x.float == 0.0
    check nodes[0].box.y.float == 0.0
    check nodes[0].box.w.float == 50.0
    check nodes[0].box.h.float == 50.0

    check nodes[1].box.x.float == 50.0
    check nodes[1].box.y.float == 0.0
    check nodes[1].box.w.float == 100.0
    check nodes[1].box.h.float == 50.0

suite "syntaxes":

  setup:
    echo "setup"

    var gt: GridTemplate

    # grid-template-columns: [first] 40px [line2] 50px [line3] auto [col4-start] 50px [five] 40px [end];
    parseGridTemplateColumns gt, ["first"] 40'ux ["second", "line2"] 50'ux ["line3"] auto ["col4-start"] 50'ux ["five"] 40'ux ["end"]
    parseGridTemplateRows gt, ["row1-start"] 25'pp ["row1-end"] 100'ux ["third-line"] auto ["last-line"]
    gt.computeTracks(uiBox(0, 0, 1000, 1000))
    # echo "grid template: ", repr gridTemplate

  template checkSpans(gridTemplate: GridTemplate, gridItem: GridItem) =
    # print gridItem
    let contentSize = uiSize(0, 0)
    gridItem.setGridSpans(gt, contentSize)

    check gridItem.index[dcol].a.line == 2.toLineName
    check gridItem.index[dcol].b == ln"five"

    check gridItem.span[dcol].a == 2
    check gridItem.span[dcol].b == 5
    check gridItem.span[drow].a == 1
    check gridItem.span[drow].b == 2

  test "getLine":
    ## mixed
    let first = gt.getLine(dcol, ln"first")
    check first.track == csFixed(40.0)

    let second = gt.getLine(dcol, ln"second")
    check second.track == csFixed(50.0)

    let line3 = gt.getLine(dcol, 3.mkIndex)
    check line3.track == csAuto()

    let five1 = gt.getLine(dcol, ln"five")
    check five1.track == csFixed(40.0)
    gt.getLine(dcol, ln"five").track = csFixed(30.0)
    let five2 = gt.getLine(dcol, ln"five")
    check five2.track == csFixed(30.0)


  test "auto span":
    ## mixed
    
    var gridItem1 = newGridItem()
    gridItem1.column = 2 // ln"five"
    gridItem1.row = "row1-start"
    checkSpans(gt, gridItem1)

  test "manual span":
    ## span
    var gridItem2 = newGridItem()
    gridItem2.column = 2 // ln"five"
    gridItem2.row = "row1-start" // span "row1-start"
    checkSpans(gt, gridItem2)
