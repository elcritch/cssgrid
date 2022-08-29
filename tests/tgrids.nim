import typetraits
import sequtils

import unittest
import cssgrid/basic
import cssgrid/gridtypes
import cssgrid/layout
import cssgrid/parser

import print

type
  GridNode* = ref object
    id: string
    box: UiBox
    gridItem: GridItem

proc `box=`*[T](v: T, box: UiBox) = 
  v.box = box

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
    gt.computeLayout(uiBox(0, 0, 100, 100))
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
    gt.computeLayout(uiBox(0, 0, 100, 100))
    # print "grid template: ", gt

    check abs(gt.lines[dcol][0].start.float - 0.0) < 1.0e-3
    check abs(gt.lines[dcol][1].start.float - 33.3333) < 1.0e-3
    check abs(gt.lines[dcol][2].start.float - 66.6666) < 1.0e-3
    check abs(gt.lines[drow][0].start.float - 0.0) < 1.0e-3
    check abs(gt.lines[drow][1].start.float - 33.3333) < 1.0e-3
    check abs(gt.lines[drow][2].start.float - 66.6666) < 1.0e-3

  test "4x1 grid test":
    var gt = newGridTemplate(
      columns = @[1'fr.gl, initGridLine(5.csFixed), 1'fr.gl, 1'fr.gl],
    )
    gt.computeLayout(uiBox(0, 0, 100, 100))
    # print "grid template: ", gt

    check abs(gt.lines[dcol][0].start.float - 0.0) < 1.0e-3
    check abs(gt.lines[dcol][1].start.float - 31.6666) < 1.0e-3
    check abs(gt.lines[dcol][2].start.float - 36.6666) < 1.0e-3
    check abs(gt.lines[dcol][3].start.float - 68.3333) < 1.0e-3
    check abs(gt.lines[drow][0].start.float - 0.0) < 1.0e-3

  test "initial macros":
    var gridTemplate: GridTemplate

    # grid-template-columns: [first] 40px [line2] 50px [line3] auto [col4-start] 50px [five] 40px [end];
    parseGridTemplateColumns gridTemplate, ["first"] 40'ui ["second", "line2"] 50'pp ["line3"] auto ["col4-start"] 50'ui ["five"] 40'ui ["end"]

    # gridTemplate.computeLayout(uiBox(0, 0, 100, 100))
    let gt = gridTemplate

    check gt.lines[dcol][0].track.kind == UiFixed
    check gt.lines[dcol][0].track.coord == 40.0.UiScalar
    # echo repr gt.lines[dcol][0].aliases.toSeq.mapIt(it.int), toLineNames("first").toSeq.mapIt(it.int)
    check gt.lines[dcol][0].aliases == toLineNames("first")
    check gt.lines[dcol][1].track.kind == UiPerc
    check gt.lines[dcol][1].track.perc == 50.0.UiScalar
    check gt.lines[dcol][1].aliases == toLineNames("second", "line2")
    check gt.lines[dcol][2].track.kind == UiAuto
    check gt.lines[dcol][2].aliases == toLineNames("line3")
    check gt.lines[dcol][3].track.kind == UiFixed
    check gt.lines[dcol][3].track.coord == 50.0.UiScalar
    check gt.lines[dcol][3].aliases == toLineNames("col4-start")
    check gt.lines[dcol][4].track.kind == UiFixed
    check gt.lines[dcol][4].track.coord == 40.0.UiScalar
    check gt.lines[dcol][4].aliases == toLineNames("five")
    check gt.lines[dcol][5].track.kind == UiEnd
    check toLineNames("end") == gt.lines[dcol][5].aliases

    # print "grid template: ", gridTemplate
    # echo "grid template: ", repr gridTemplate

  test "compute macros":
    var tmpl: GridTemplate

    # grid-template-columns: [first] 40px [line2] 50px [line3] auto [col4-start] 50px [five] 40px [end];
    parseGridTemplateColumns tmpl, ["first"] 40'ui \
      ["second", "line2"] 50'ui \
      ["line3"] auto \
      ["col4-start"] 50'ui \
      ["five"] 40'ui ["end"]
    parseGridTemplateRows tmpl, ["row1-start"] 25'pp ["row1-end"] 100'ui ["third-line"] auto ["last-line"]

    tmpl.computeLayout(uiBox(0, 0, 1000, 1000))
    let gt = tmpl
    # print "grid template: ", gridTemplate
    check abs(gt.lines[dcol][0].start.float - 0.0) < 1.0e-3
    check abs(gt.lines[dcol][1].start.float - 40.0) < 1.0e-3
    check abs(gt.lines[dcol][2].start.float - 90.0) < 1.0e-3
    check abs(gt.lines[dcol][3].start.float - 910.0) < 1.0e-3
    check abs(gt.lines[dcol][4].start.float - 960.0) < 1.0e-3
    check abs(gt.lines[dcol][5].start.float - 1000.0) < 1.0e-3

    check abs(gt.lines[drow][0].start.float - 0.0) < 1.0e-3
    check abs(gt.lines[drow][1].start.float - 250.0) < 1.0e-3
    check abs(gt.lines[drow][2].start.float - 350.0) < 1.0e-3
    check abs(gt.lines[drow][3].start.float - 1000.0) < 1.0e-3
    # echo "grid template: ", repr tmpl
    
  test "compute others":
    var gt: GridTemplate

    parseGridTemplateColumns gt, ["first"] 40'ui \
      ["second", "line2"] 50'ui \
      ["line3"] auto \
      ["col4-start"] 50'ui \
      ["five"] 40'ui ["end"]
    parseGridTemplateRows gt, ["row1-start"] 25'pp ["row1-end"] 100'ui ["third-line"] auto ["last-line"]

    gt.gaps[dcol] = 10.UiScalar
    gt.gaps[drow] = 10.UiScalar
    gt.computeLayout(uiBox(0, 0, 1000, 1000))
    # print "grid template: ", gt
    check abs(gt.lines[dcol][0].start.float - 0.0) < 1.0e-3
    check abs(gt.lines[dcol][1].start.float - 40.0 - 10.0) < 1.0e-3
    check abs(gt.lines[dcol][2].start.float - 90.0 - 20.0) < 1.0e-3
    check abs(gt.lines[dcol][3].start.float - 910.0 + 20.0) < 1.0e-3
    check abs(gt.lines[dcol][4].start.float - 960.0 + 10.0) < 1.0e-3
    check abs(gt.lines[dcol][5].start.float - 1000.0) < 1.0e-3

    check abs(gt.lines[drow][0].start.float - 0.0) < 1.0e-3
    check abs(gt.lines[drow][1].start.float - 250.0 - 10.0) < 1.0e-3
    check abs(gt.lines[drow][2].start.float - 350.0 - 20.0) < 1.0e-3
    check abs(gt.lines[drow][3].start.float - 1000.0) < 1.0e-3
    
  test "compute macro and item layout":
    var gridTemplate: GridTemplate

    # grid-template-columns: [first] 40px [line2] 50px [line3] auto [col4-start] 50px [five] 40px [end];
    parseGridTemplateColumns gridTemplate, ["first"] 40'ui ["second", "line2"] 50'ui ["line3"] auto ["col4-start"] 50'ui ["five"] 40'ui ["end"]
    parseGridTemplateRows gridTemplate, ["row1-start"] 25'pp ["row1-end"] 100'ui ["third-line"] auto ["last-line"]
    gridTemplate.computeLayout(uiBox(0, 0, 1000, 1000))
    echo "grid template: ", repr gridTemplate

    var gridItem = newGridItem()
    gridItem.columns.a = 2.mkIndex
    gridItem.columns.b = "five".mkIndex
    gridItem.rows.a = "row1-start".mkIndex
    gridItem.rows.b = 3.mkIndex
    print gridItem

    let contentSize = uiSize(0, 0)
    let itemBox = gridItem.computePosition(gridTemplate, contentSize)
    print itemBox
    print "post: ", gridItem

    check gridItem.span[dcol].a == 2
    check gridItem.span[dcol].b == 5
    check abs(itemBox.x.float - 40.0) < 1.0e-3
    check abs(itemBox.w.float - 920.0) < 1.0e-3
    check abs(itemBox.y.float - 0.0) < 1.0e-3
    check abs(itemBox.h.float - 350.0) < 1.0e-3

  test "compute macro and item layout":
    var gridTemplate: GridTemplate

    # grid-template-columns: [first] 40px [line2] 50px [line3] auto [col4-start] 50px [five] 40px [end];
    parseGridTemplateColumns gridTemplate, [first] 40'ui ["second", "line2"] 50'ui ["line3"] auto ["col4-start"] 50'ui ["five"] 40'ui ["end"]
    parseGridTemplateRows gridTemplate, ["row1-start"] 25'pp ["row1-end"] 100'ui ["third-line"] auto ["last-line"]
    gridTemplate.computeLayout(uiBox(0, 0, 1000, 1000))
    # echo "grid template: ", repr gridTemplate

    var gridItem = newGridItem()
    gridItem.columns.a = 2.mkIndex
    gridItem.columns.b = "five".mkIndex
    gridItem.rows.a = "row1-start".mkIndex
    gridItem.rows.b = 3.mkIndex
    # print gridItem

    let contentSize = uiSize(500, 200)
    var itemBox: UiBox

    ## test stretch
    itemBox = gridItem.computePosition(gridTemplate, contentSize)
    # print itemBox
    check abs(itemBox.x.float - 40.0) < 1.0e-3
    check abs(itemBox.w.float - 920.0) < 1.0e-3
    check abs(itemBox.y.float - 0.0) < 1.0e-3
    check abs(itemBox.h.float - 350.0) < 1.0e-3

    ## test start
    gridTemplate.justifyItems = CxStart
    gridTemplate.alignItems = CxStart
    itemBox = gridItem.computePosition(gridTemplate, contentSize)
    # print itemBox
    check abs(itemBox.x.float - 40.0) < 1.0e-3
    check abs(itemBox.w.float - 500.0) < 1.0e-3
    check abs(itemBox.y.float - 0.0) < 1.0e-3
    check abs(itemBox.h.float - 200.0) < 1.0e-3

    ## test end
    gridTemplate.justifyItems = CxEnd
    gridTemplate.alignItems = CxEnd
    itemBox = gridItem.computePosition(gridTemplate, contentSize)
    print itemBox
    check abs(itemBox.x.float - 460.0) < 1.0e-3
    check abs(itemBox.w.float - 500.0) < 1.0e-3
    check abs(itemBox.y.float - 150.0) < 1.0e-3
    check abs(itemBox.h.float - 200.0) < 1.0e-3
    
    ## test start / stretch
    gridTemplate.justifyItems = CxStart
    gridTemplate.alignItems = CxStretch
    itemBox = gridItem.computePosition(gridTemplate, contentSize)
    # print itemBox
    check abs(itemBox.x.float - 40.0) < 1.0e-3
    check abs(itemBox.w.float - 500.0) < 1.0e-3
    check abs(itemBox.y.float - 0.0) < 1.0e-3
    check abs(itemBox.h.float - 350.0) < 1.0e-3
    
  test "compute layout with auto columns":
    var gridTemplate: GridTemplate

    # grid-template-columns: [first] 40px [line2] 50px [line3] auto [col4-start] 50px [five] 40px [end];
    parseGridTemplateColumns gridTemplate, ["a"] 60'ui ["b"] 60'ui
    parseGridTemplateRows gridTemplate, 90'ui 90'ui
    # echo "grid template pre: ", repr gridTemplate
    check gridTemplate.lines[dcol].len() == 3
    check gridTemplate.lines[drow].len() == 3
    gridTemplate.computeLayout(uiBox(0, 0, 1000, 1000))
    # echo "grid template: ", repr gridTemplate

    let contentSize = uiSize(30, 30)

    # item a
    var itema = newGridItem()
    itema.columns= 1 // 2
    itema.rows= 2 // 3

    let boxa = itema.computePosition(gridTemplate, contentSize)
    # echo "grid template post: ", repr gridTemplate
    # print boxa

    check abs(boxa.x.float - 0.0) < 1.0e-3
    check abs(boxa.w.float - 60.0) < 1.0e-3
    check abs(boxa.y.float - 90.0) < 1.0e-3
    check abs(boxa.h.float - 90.0) < 1.0e-3

    # item b
    var itemb = newGridItem()
    itemb.columns = 5 // 6
    itemb.rows = 2 // 3

    let boxb = itemb.computePosition(gridTemplate, contentSize)
    # echo "grid template post: ", repr gridTemplate
    # print boxb

    check abs(boxb.x.float - 120.0) < 1.0e-3
    check abs(boxb.w.float - 30.0) < 1.0e-3
    check abs(boxb.y.float - 90.0) < 1.0e-3
    check abs(boxb.h.float - 90.0) < 1.0e-3

  test "compute layout with auto columns with fixed size":
    var gridTemplate: GridTemplate

    # grid-template-columns: [first] 40px [line2] 50px [line3] auto [col4-start] 50px [five] 40px [end];
    parseGridTemplateColumns gridTemplate, ["a"] 60'ui ["b"] 60'ui
    parseGridTemplateRows gridTemplate, 90'ui 90'ui
    gridTemplate.autos[dcol] = 60.csFixed()
    gridTemplate.autos[drow] = 20.csFixed()
    # echo "grid template pre: ", repr gridTemplate
    check gridTemplate.lines[dcol].len() == 3
    check gridTemplate.lines[drow].len() == 3
    gridTemplate.computeLayout(uiBox(0, 0, 1000, 1000))
    # echo "grid template: ", repr gridTemplate

    let contentSize = uiSize(30, 30)

    # item a
    var itema = newGridItem()
    itema.columns = 1 // 2
    itema.rows = 2 // 3

    let boxa = itema.computePosition(gridTemplate, contentSize)
    # echo "grid template post: ", repr gridTemplate
    # print boxa

    check abs(boxa.x.float - 0.0) < 1.0e-3
    check abs(boxa.w.float - 60.0) < 1.0e-3
    check abs(boxa.y.float - 90.0) < 1.0e-3
    check abs(boxa.h.float - 90.0) < 1.0e-3

    # item b
    var itemb = newGridItem()
    itemb.columns = 5 // 6
    itemb.rows = 3 // 4

    let boxb = itemb.computePosition(gridTemplate, contentSize)
    # echo "grid template post: ", repr gridTemplate
    # print boxb

    check abs(boxb.x.float - 240.0) < 1.0e-3
    check abs(boxb.w.float - 60.0) < 1.0e-3
    check abs(boxb.y.float - 180.0) < 1.0e-3
    check abs(boxb.h.float - 30.0) < 1.0e-3

  test "compute layout with auto flow":
    var gridTemplate: GridTemplate

    # grid-template-columns: [first] 40px [line2] 50px [line3] auto [col4-start] 50px [five] 40px [end];
    parseGridTemplateColumns gridTemplate, 60'ui 60'ui 60'ui 60'ui 60'ui
    parseGridTemplateRows gridTemplate, 33'ui 33'ui
    gridTemplate.justifyItems = CxStretch
    # echo "grid template pre: ", repr gridTemplate
    check gridTemplate.lines[dcol].len() == 6
    check gridTemplate.lines[drow].len() == 3
    gridTemplate.computeLayout(uiBox(0, 0, 1000, 1000))
    # echo "grid template: ", repr gridTemplate
    var parent = GridNode()

    let contentSize = uiSize(30, 30)
    var nodes = newSeq[GridNode](8)

    # item a
    var itema = newGridItem()
    itema.columns = 1 // 2
    itema.rows = 1 // 3
    # let boxa = itema.computePosition(gridTemplate, contentSize)
    nodes[0] = GridNode(id: "a", gridItem: itema)

    # ==== item e ====
    var iteme = newGridItem()
    iteme.columns = 5 // 6
    iteme.rows = 1 // 3
    nodes[1] = GridNode(id: "e", gridItem: iteme)

    # ==== item b's ====
    for i in 2 ..< nodes.len():
      nodes[i] = GridNode(id: "b" & $(i-2))

    # ==== process grid ====
    gridTemplate.computeGridLayout(parent, nodes)

    echo "grid template post: ", repr gridTemplate
    # ==== item a ====
    check abs(nodes[0].box.x.float - 0.0) < 1.0e-3
    check abs(nodes[0].box.w.float - 60.0) < 1.0e-3
    check abs(nodes[0].box.y.float - 0.0) < 1.0e-3
    check abs(nodes[0].box.h.float - 66.0) < 1.0e-3

    # ==== item e ====
    print nodes[1].box
    check abs(nodes[1].box.x.float - 240.0) < 1.0e-3
    check abs(nodes[1].box.w.float - 60.0) < 1.0e-3
    check abs(nodes[1].box.y.float - 0.0) < 1.0e-3
    check abs(nodes[1].box.h.float - 66.0) < 1.0e-3

    # ==== item b's ====
    for i in 2 ..< nodes.len():
      echo "auto child:cols: ", nodes[i].id, " :: ", nodes[i].gridItem.span[dcol].repr, " x ", nodes[i].gridItem.span[drow].repr
      echo "auto child:cols: ", nodes[i].gridItem.repr
      echo "auto child:box: ", nodes[i].id, " => ", nodes[i].box

    check abs(nodes[2].box.x.float - 60.0) < 1.0e-3
    check abs(nodes[3].box.x.float - 120.0) < 1.0e-3
    check abs(nodes[4].box.x.float - 180.0) < 1.0e-3

    check abs(nodes[2].box.y.float - 0.0) < 1.0e-3
    check abs(nodes[3].box.y.float - 0.0) < 1.0e-3
    check abs(nodes[4].box.y.float - 0.0) < 1.0e-3

    check abs(nodes[5].box.x.float - 60.0) < 1.0e-3
    check abs(nodes[6].box.x.float - 120.0) < 1.0e-3

    check abs(nodes[5].box.y.float - 33.0) < 1.0e-3
    check abs(nodes[6].box.y.float - 33.0) < 1.0e-3
    check abs(nodes[7].box.y.float - 33.0) < 1.0e-3

    # check abs(nodes[8].box.x.float - 0.0) < 1.0e-3
    # check abs(nodes[8].box.y.float - 0.0) < 1.0e-3

    for i in 2 ..< nodes.len() - 1:
      check abs(nodes[i].box.w.float - 60.0) < 1.0e-3
      check abs(nodes[i].box.h.float - 33.0) < 1.0e-3

