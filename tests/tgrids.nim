import typetraits
import sequtils

import unittest
import cssgrid/basic
import cssgrid/gridtypes
import cssgrid/layout

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
      columns = @[initGridLine(mkFrac(1))],
      rows = @[initGridLine(mkFrac(1))],
    )
    check gt.columns.len() == 1
    check gt.rows.len() == 1

  test "basic grid compute":
    var gt = newGridTemplate(
      columns = @[initGridLine 1'fr, initGridLine 1'fr],
      rows = @[gl 1'fr, gl 1'fr],
    )
    gt.computeLayout(uiBox(0, 0, 100, 100))
    # print "grid template: ", gt

    check gt.columns[0].start == 0.UiScalar
    check gt.columns[1].start == 50.UiScalar
    check gt.rows[0].start == 0.UiScalar
    check gt.rows[1].start == 50.UiScalar

  test "3x3 grid compute with frac's":
    var gt = newGridTemplate(
      columns = @[gl 1'fr, gl 1'fr, gl 1'fr],
      rows = @[gl 1'fr, gl 1'fr, gl 1'fr],
    )
    gt.computeLayout(uiBox(0, 0, 100, 100))
    # print "grid template: ", gt

    check abs(gt.columns[0].start.float - 0.0) < 1.0e-3
    check abs(gt.columns[1].start.float - 33.3333) < 1.0e-3
    check abs(gt.columns[2].start.float - 66.6666) < 1.0e-3
    check abs(gt.rows[0].start.float - 0.0) < 1.0e-3
    check abs(gt.rows[1].start.float - 33.3333) < 1.0e-3
    check abs(gt.rows[2].start.float - 66.6666) < 1.0e-3

  test "4x1 grid test":
    var gt = newGridTemplate(
      columns = @[1'fr.gl, initGridLine(5.mkFixed), 1'fr.gl, 1'fr.gl],
    )
    gt.computeLayout(uiBox(0, 0, 100, 100))
    # print "grid template: ", gt

    check abs(gt.columns[0].start.float - 0.0) < 1.0e-3
    check abs(gt.columns[1].start.float - 31.6666) < 1.0e-3
    check abs(gt.columns[2].start.float - 36.6666) < 1.0e-3
    check abs(gt.columns[3].start.float - 68.3333) < 1.0e-3
    check abs(gt.rows[0].start.float - 0.0) < 1.0e-3

  test "initial macros":
    var gridTemplate: GridTemplate

    # grid-template-columns: [first] 40px [line2] 50px [line3] auto [col4-start] 50px [five] 40px [end];
    parseGridTemplateColumns gridTemplate, ["first"] 40'ui ["second", "line2"] 50'perc ["line3"] auto ["col4-start"] 50'ui ["five"] 40'ui ["end"]

    # gridTemplate.computeLayout(uiBox(0, 0, 100, 100))
    let gt = gridTemplate

    check gt.columns[0].track.kind == grFixed
    check gt.columns[0].track.coord == 40.0.UiScalar
    echo repr gt.columns[0].aliases.toSeq.mapIt(it.int), repr toLineNames("first").toSeq.mapIt(it.int)
    check gt.columns[0].aliases == toLineNames("first")
    check gt.columns[1].track.kind == grPerc
    check gt.columns[1].track.perc == 50.0.UiScalar
    check gt.columns[1].aliases == toLineNames("second", "line2")
    check gt.columns[2].track.kind == grAuto
    check gt.columns[2].aliases == toLineNames("line3")
    check gt.columns[3].track.kind == grFixed
    check gt.columns[3].track.coord == 50.0.UiScalar
    check gt.columns[3].aliases == toLineNames("col4-start")
    check gt.columns[4].track.kind == grFixed
    check gt.columns[4].track.coord == 40.0.UiScalar
    check gt.columns[4].aliases == toLineNames("five")
    check gt.columns[5].track.kind == grEnd
    check toLineNames("end") == gt.columns[5].aliases

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
    parseGridTemplateRows tmpl, ["row1-start"] 25'perc ["row1-end"] 100'ui ["third-line"] auto ["last-line"]

    tmpl.computeLayout(uiBox(0, 0, 1000, 1000))
    let gt = tmpl
    # print "grid template: ", gridTemplate
    check abs(gt.columns[0].start.float - 0.0) < 1.0e-3
    check abs(gt.columns[1].start.float - 40.0) < 1.0e-3
    check abs(gt.columns[2].start.float - 90.0) < 1.0e-3
    check abs(gt.columns[3].start.float - 910.0) < 1.0e-3
    check abs(gt.columns[4].start.float - 960.0) < 1.0e-3
    check abs(gt.columns[5].start.float - 1000.0) < 1.0e-3

    check abs(gt.rows[0].start.float - 0.0) < 1.0e-3
    check abs(gt.rows[1].start.float - 250.0) < 1.0e-3
    check abs(gt.rows[2].start.float - 350.0) < 1.0e-3
    check abs(gt.rows[3].start.float - 1000.0) < 1.0e-3
    # echo "grid template: ", repr tmpl
    
  test "compute others":
    var gt: GridTemplate

    parseGridTemplateColumns gt, ["first"] 40'ui \
      ["second", "line2"] 50'ui \
      ["line3"] auto \
      ["col4-start"] 50'ui \
      ["five"] 40'ui ["end"]
    parseGridTemplateRows gt, ["row1-start"] 25'perc ["row1-end"] 100'ui ["third-line"] auto ["last-line"]

    gt.columnGap = 10.UiScalar
    gt.rowGap = 10.UiScalar
    gt.computeLayout(uiBox(0, 0, 1000, 1000))
    # print "grid template: ", gt
    check abs(gt.columns[0].start.float - 0.0) < 1.0e-3
    check abs(gt.columns[1].start.float - 40.0 - 10.0) < 1.0e-3
    check abs(gt.columns[2].start.float - 90.0 - 20.0) < 1.0e-3
    check abs(gt.columns[3].start.float - 910.0 + 20.0) < 1.0e-3
    check abs(gt.columns[4].start.float - 960.0 + 10.0) < 1.0e-3
    check abs(gt.columns[5].start.float - 1000.0) < 1.0e-3

    check abs(gt.rows[0].start.float - 0.0) < 1.0e-3
    check abs(gt.rows[1].start.float - 250.0 - 10.0) < 1.0e-3
    check abs(gt.rows[2].start.float - 350.0 - 20.0) < 1.0e-3
    check abs(gt.rows[3].start.float - 1000.0) < 1.0e-3
    
  test "compute macro and item layout":
    var gridTemplate: GridTemplate

    # grid-template-columns: [first] 40px [line2] 50px [line3] auto [col4-start] 50px [five] 40px [end];
    parseGridTemplateColumns gridTemplate, ["first"] 40'ui ["second", "line2"] 50'ui ["line3"] auto ["col4-start"] 50'ui ["five"] 40'ui ["end"]
    parseGridTemplateRows gridTemplate, ["row1-start"] 25'perc ["row1-end"] 100'ui ["third-line"] auto ["last-line"]
    gridTemplate.computeLayout(uiBox(0, 0, 1000, 1000))
    echo "grid template: ", repr gridTemplate

    var gridItem = newGridItem()
    gridItem.columnStart = 2.mkIndex
    gridItem.columnEnd = "five".mkIndex
    gridItem.rowStart = "row1-start".mkIndex
    gridItem.rowEnd = 3.mkIndex
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
    parseGridTemplateColumns gridTemplate, ["first"] 40'ui ["second", "line2"] 50'ui ["line3"] auto ["col4-start"] 50'ui ["five"] 40'ui ["end"]
    parseGridTemplateRows gridTemplate, ["row1-start"] 25'perc ["row1-end"] 100'ui ["third-line"] auto ["last-line"]
    gridTemplate.computeLayout(uiBox(0, 0, 1000, 1000))
    # echo "grid template: ", repr gridTemplate

    var gridItem = newGridItem()
    gridItem.columnStart = 2.mkIndex
    gridItem.columnEnd = "five".mkIndex
    gridItem.rowStart = "row1-start".mkIndex
    gridItem.rowEnd = 3.mkIndex
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
    gridTemplate.justifyItems = gcStart
    gridTemplate.alignItems = gcStart
    itemBox = gridItem.computePosition(gridTemplate, contentSize)
    # print itemBox
    check abs(itemBox.x.float - 40.0) < 1.0e-3
    check abs(itemBox.w.float - 500.0) < 1.0e-3
    check abs(itemBox.y.float - 0.0) < 1.0e-3
    check abs(itemBox.h.float - 200.0) < 1.0e-3

    ## test end
    gridTemplate.justifyItems = gcEnd
    gridTemplate.alignItems = gcEnd
    itemBox = gridItem.computePosition(gridTemplate, contentSize)
    print itemBox
    check abs(itemBox.x.float - 460.0) < 1.0e-3
    check abs(itemBox.w.float - 500.0) < 1.0e-3
    check abs(itemBox.y.float - 150.0) < 1.0e-3
    check abs(itemBox.h.float - 200.0) < 1.0e-3
    
    ## test start / stretch
    gridTemplate.justifyItems = gcStart
    gridTemplate.alignItems = gcStretch
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
    check gridTemplate.columns.len() == 3
    check gridTemplate.rows.len() == 3
    gridTemplate.computeLayout(uiBox(0, 0, 1000, 1000))
    # echo "grid template: ", repr gridTemplate

    let contentSize = uiSize(30, 30)

    # item a
    var itema = newGridItem()
    itema.column= 1 // 2
    itema.row= 2 // 3

    let boxa = itema.computePosition(gridTemplate, contentSize)
    # echo "grid template post: ", repr gridTemplate
    # print boxa

    check abs(boxa.x.float - 0.0) < 1.0e-3
    check abs(boxa.w.float - 60.0) < 1.0e-3
    check abs(boxa.y.float - 90.0) < 1.0e-3
    check abs(boxa.h.float - 90.0) < 1.0e-3

    # item b
    var itemb = newGridItem()
    itemb.column= 5 // 6
    itemb.row= 2 // 3

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
    gridTemplate.autoColumns = 60.mkFixed()
    gridTemplate.autoRows = 20.mkFixed()
    # echo "grid template pre: ", repr gridTemplate
    check gridTemplate.columns.len() == 3
    check gridTemplate.rows.len() == 3
    gridTemplate.computeLayout(uiBox(0, 0, 1000, 1000))
    # echo "grid template: ", repr gridTemplate

    let contentSize = uiSize(30, 30)

    # item a
    var itema = newGridItem()
    itema.column= 1 // 2
    itema.row= 2 // 3

    let boxa = itema.computePosition(gridTemplate, contentSize)
    # echo "grid template post: ", repr gridTemplate
    # print boxa

    check abs(boxa.x.float - 0.0) < 1.0e-3
    check abs(boxa.w.float - 60.0) < 1.0e-3
    check abs(boxa.y.float - 90.0) < 1.0e-3
    check abs(boxa.h.float - 90.0) < 1.0e-3

    # item b
    var itemb = newGridItem()
    itemb.column= 5 // 6
    itemb.row= 3 // 4

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
    gridTemplate.justifyItems = gcStretch
    # echo "grid template pre: ", repr gridTemplate
    check gridTemplate.columns.len() == 6
    check gridTemplate.rows.len() == 3
    gridTemplate.computeLayout(uiBox(0, 0, 1000, 1000))
    # echo "grid template: ", repr gridTemplate
    var parent = GridNode()

    let contentSize = uiSize(30, 30)
    var nodes = newSeq[GridNode](8)

    # item a
    var itema = newGridItem()
    itema.column= 1 // 2
    itema.row= 1 // 3
    # let boxa = itema.computePosition(gridTemplate, contentSize)
    nodes[0] = GridNode(id: "a", gridItem: itema)

    # ==== item e ====
    var iteme = newGridItem()
    iteme.column= 5 // 6
    iteme.row= 1 // 3
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

