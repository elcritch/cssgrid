import typetraits
import sequtils

import unittest
import cssgrid/numberTypes
import cssgrid/gridtypes
import cssgrid/parser
import cssgrid/prettyprints

# import cssgrid/layout
import cssgrid/computelayout

import pretty
import macros

import commontestutils

suite "grids":

  test "3x3 grid compute with frac's":
    var parent = TestNode(box: uiBox(0, 0, 100, 100))
    parent.gridTemplate = newGridTemplate(
      columns = @[gl 1'fr, gl 1'fr, gl 1'fr],
      rows = @[gl 1'fr, gl 1'fr, gl 1'fr],
    )
    
    # Create some child nodes to ensure the grid is processed
    var nodes = newSeq[TestNode](3)
    for i in 0..<nodes.len:
      nodes[i] = TestNode(name: "child" & $i)
      nodes[i].gridItem = newGridItem()
      nodes[i].gridItem.column = i+1
      nodes[i].gridItem.row = 1
      
    parent.children = nodes
    
    discard parent.gridTemplate.computeNodeLayout(parent)
    
    # Check grid line positions
    checks parent.gridTemplate.lines[dcol][0].start.float == 0.0
    checks parent.gridTemplate.lines[dcol][1].start.float == 33.3333.toVal
    checks parent.gridTemplate.lines[dcol][2].start.float == 66.6666.toVal
    checks parent.gridTemplate.lines[drow][0].start.float == 0.0
    checks parent.gridTemplate.lines[drow][1].start.float == 33.3333.toVal
    checks parent.gridTemplate.lines[drow][2].start.float == 66.6666.toVal

  test "compute layout with auto flow":
    var gridTemplate: GridTemplate

    # grid-template-columns: [first] 40px [line2] 50px [line3] auto [col4-start] 50px [five] 40px [end];
    parseGridTemplateColumns gridTemplate, 60'ux 60'ux 60'ux 60'ux 60'ux
    parseGridTemplateRows gridTemplate, 33'ux 33'ux
    gridTemplate.justifyItems = CxStretch
    gridTemplate.autoFlow = grRow
    # echo "grid template pre: ", repr gridTemplate
    check gridTemplate.lines[dcol].len() == 6
    check gridTemplate.lines[drow].len() == 3
    var computedSizes: array[GridDir, Table[int, ComputedTrackSize]]
    # gridTemplate.computeTracks(uiBox(0, 0, 1000, 1000), computedSizes)
    # echo "grid template: ", repr gridTemplate
    var parent = TestNode()
    parent.gridTemplate = gridTemplate

    let contentSize = uiSize(30, 30)
    var nodes = newSeq[TestNode](8)

    # item a
    var itema = newGridItem()
    itema.column = 1 // 2
    itema.row = 1 // 3
    # let boxa = itema.computeTracks(gridTemplate, contentSize)
    nodes[0] = TestNode(name: "a", gridItem: itema)

    # ==== item e ====
    var iteme = newGridItem()
    iteme.column = 5 // 6
    iteme.row = 1 // 3
    nodes[1] = TestNode(name: "e", gridItem: iteme)

    # ==== item b's ====
    for i in 2 ..< nodes.len():
      nodes[i] = TestNode(name: "b" & $(i-2))

    # ==== process grid ====
    parent.children = nodes

    # setPrettyPrintMode(cmTerminal)
    # defer: setPrettyPrintMode(cmNone)
    discard gridTemplate.computeNodeLayout(parent)

    # echo "grid template post: ", repr gridTemplate
    # ==== item a ====
    check nodes[0].box == uiBox(0, 0, 60, 66)

    # ==== item e ====
    # print nodes[1].box
    check nodes[1].box == uiBox(240, 0, 60, 66)

    # ==== item b's ====
    # printChildrens(2)

    check nodes[2].box.x == 60
    check nodes[2].box.y == 0
    check nodes[3].box.x == 120
    check nodes[3].box.y == 0
    check nodes[4].box.x == 180
    check nodes[4].box.y == 0

    check nodes[5].box.x == 60
    check nodes[5].box.y == 33
    check nodes[6].box.x == 120
    check nodes[6].box.y == 33
    check nodes[7].box.x == 180
    check nodes[7].box.y == 33

    for i in 2 ..< nodes.len() - 1:
      check nodes[i].box.w == 60
      check nodes[i].box.h == 33

  test "compute layout auto flow overflow":
    var gridTemplate: GridTemplate

    parseGridTemplateColumns gridTemplate, 100'ux
    parseGridTemplateRows gridTemplate, 100'ux
    gridTemplate.autos[drow] = csFixed 100.0
    gridTemplate.justifyItems = CxStretch
    var computedSizes: array[GridDir, Table[int, ComputedTrackSize]]
    # gridTemplate.computeTracks(uiBox(0, 0, 1000, 1000), computedSizes)
    var parent = TestNode()

    var nodes = newSeq[TestNode](4)

    # ==== item a's ====
    for i in 0 ..< nodes.len():
      nodes[i] = TestNode(name: "b" & $(i))

    # ==== process grid ====
    parent.children = nodes
    parent.gridTemplate = gridTemplate
    let box = gridTemplate.computeNodeLayout(parent)

    check box.w == 100
    check box.h == 400

    check nodes[0].gridItem.span[dcol] == 1'i16 .. 2'i16
    check nodes[0].gridItem.span[drow] == 1'i16 .. 2'i16
    check nodes[1].gridItem.span[dcol] == 1'i16 .. 2'i16
    check nodes[1].gridItem.span[drow] == 2'i16 .. 3'i16

    check nodes[0].box == uiBox(0, 0, 100, 100)
    check nodes[1].box == uiBox(0, 100, 100, 100)
    check nodes[3].box == uiBox(0, 300, 100, 100)

  test "compute layout auto flow overflow (colums)":
    # prettyPrintWriteMode = cmTerminal
    # defer: prettyPrintWriteMode = cmNone

    var gridTemplate: GridTemplate
    parseGridTemplateColumns gridTemplate, 1'fr
    parseGridTemplateRows gridTemplate, 1'fr
    gridTemplate.autos[dcol] = csFixed 100.0
    gridTemplate.justifyItems = CxStart
    gridTemplate.alignItems = CxStart
    gridTemplate.autoFlow = grColumn

    var parent = TestNode()
    parent.cxOffset = [0'ux, 0'ux]
    parent.cxSize = [50'ux, 50'ux]
    parent.frame = Frame(windowSize: uiBox(0, 0, 400, 50))
    parent.gridTemplate = gridTemplate

    var nodes = newSeq[TestNode](4)

    # ==== item a's ====
    for i in 0 ..< nodes.len():
      nodes[i] = TestNode(name: "b" & $(i), box: uiBox(0,0,50,50), parent: parent)

    nodes[0].cxSize = [40'ux, 40'ux]
    # ==== process grid ====
    parent.children = nodes
    parent.gridTemplate = gridTemplate
    # discard gridTemplate.computeNodeLayout(parent)
    # let box = gridTemplate.computeNodeLayout(parent)
    computeLayout(parent)

    # TODO: FIXME!!!
    # check box.w == 750
    check parent.box.h == 50
    check nodes[0].gridItem.span[dcol] == 1'i16 .. 2'i16
    check nodes[0].gridItem.span[drow] == 1'i16 .. 2'i16
    check nodes[1].gridItem.span[dcol] == 2'i16 .. 3'i16
    check nodes[1].gridItem.span[drow] == 1'i16 .. 2'i16

    printLayout(parent, cmTerminal)
    # TODO: FIXME!!!
    # the min fr track len should account for the min-content size
    check nodes[0].box == uiBox(0, 0, 40, 40)
    # check nodes[1].box == uiBox(40, 0, 50, 50)

  test "compute layout overflow (columns)":

    var gridTemplate: GridTemplate

    parseGridTemplateColumns gridTemplate, cx"auto"
    parseGridTemplateRows gridTemplate, cx"auto"
    gridTemplate.autos[dcol] = csAuto()
    gridTemplate.justifyItems = CxStretch
    gridTemplate.autoFlow = grColumn
    var parent = TestNode(name: "parent", gridTemplate: gridTemplate)
    parent.cxSize[dcol] = cx"min-content" # set fixed parent
    # parent.cxSize[dcol] = cx"auto" # set fixed parent
    parent.cxSize[drow] = csFixed(50)  # set fixed parent
    parent.frame = Frame(windowSize: uiBox(0, 0, 400, 50))

    var nodes = newSeq[TestNode](8)

    # ==== item a's ====
    for i in 0 ..< nodes.len():
      nodes[i] = TestNode(name: "b" & $(i),
                          cxMin: [50'ux, 50'ux],
                          gridItem: GridItem())
      nodes[i].gridItem.index[drow] = mkIndex(1) .. mkIndex(2)
      nodes[i].gridItem.index[dcol] = mkIndex(i+1) .. mkIndex(i+2)
      parent.children.add(nodes[i])
      nodes[i].parent = parent
    nodes[7].cxMin[dcol] = csFixed(150)

    # ==== process grid ====
    # prettyPrintWriteMode = cmTerminal
    # defer: prettyPrintWriteMode = cmNone
    computeLayout(parent)
    # printLayout(parent, cmTerminal)

    check parent.box.w == 500
    check parent.box.h == 50

    check nodes[0].gridItem.span[dcol] == 1'i16 .. 2'i16
    check nodes[0].gridItem.span[drow] == 1'i16 .. 2'i16
    check nodes[1].gridItem.span[dcol] == 2'i16 .. 3'i16
    check nodes[1].gridItem.span[drow] == 1'i16 .. 2'i16

    check nodes[0].box == uiBox(0, 0, 50, 50)
    check nodes[1].box == uiBox(50, 0, 50, 50)
    for i in 0..6:
      check nodes[i].box.w == 50
      check nodes[i].box.h == 50

    check nodes[7].box == uiBox(350, 0, 150, 50)

  test "compute layout overflow (rows)":
    var gridTemplate: GridTemplate

    parseGridTemplateColumns gridTemplate, 1'fr
    parseGridTemplateRows gridTemplate, 50'ux
    gridTemplate.autos[drow] = 50'ux
    gridTemplate.justifyItems = CxStretch
    gridTemplate.autoFlow = grRow
    var parent = TestNode()
    parent.box.w = 50
    parent.box.h = 50

    let contentSize = uiSize(30, 30)
    var nodes = newSeq[TestNode](8)

    # ==== item a's ====
    for i in 0 ..< nodes.len():
      nodes[i] = TestNode(name: "b" & $(i),
                          box: uiBox(0,0,50,50),
                          gridItem: nil)
      parent.children.add(nodes[i])
      nodes[i].parent = parent
      # nodes[i].gridItem.index[drow] = mkIndex(1) .. mkIndex(2)
      # nodes[i].gridItem.index[dcol] = mkIndex(i+1) .. mkIndex(i+2)
    # nodes[7].box.w = 150
    check gridTemplate.lines[dcol][0].track == 1'fr

    # ==== process grid ====
    let box = gridTemplate.computeNodeLayout(parent)

    check nodes[0].gridItem.span[dcol] == 1'i16 .. 2'i16
    check nodes[0].gridItem.span[drow] == 1'i16 .. 2'i16
    check nodes[1].gridItem.span[dcol] == 1'i16 .. 2'i16
    check nodes[1].gridItem.span[drow] == 2'i16 .. 3'i16

    check nodes[0].box == uiBox(0, 0, 50, 50)
    check nodes[1].box == uiBox(0, 50, 50, 50)

    for i in 0..6:
      check nodes[i].box.w == 50
      check nodes[i].box.h == 50

    check nodes[7].box == uiBox(0, 350, 50, 50)

  test "compute layout manual overflow (rows)":
    # prettyPrintWriteMode = cmTerminal
    # defer: prettyPrintWriteMode = cmNone
    var gridTemplate: GridTemplate

    parseGridTemplateColumns gridTemplate, cx"auto"
    parseGridTemplateRows gridTemplate, cx"auto"
    gridTemplate.autos[drow] = csAuto()
    gridTemplate.justifyItems = CxStretch
    gridTemplate.autoFlow = grRow
    var parent = TestNode(name: "parent", gridTemplate: gridTemplate)
    parent.cxSize[dcol] = csFixed(50)  # set fixed parent
    parent.cxSize[drow] = cx"max-content" # set fixed parent
    parent.frame = Frame(windowSize: uiBox(0, 0, 600, 50))

    let contentSize = uiSize(30, 30)
    var nodes = newSeq[TestNode](8)

    # ==== item a's ====
    for i in 0 ..< nodes.len():
      nodes[i] = TestNode(name: "b" & $(i),
                          cxMin: [50'ux, 50'ux],
                          gridItem: GridItem())
      nodes[i].gridItem.index[dcol] = mkIndex(1) .. mkIndex(2)
      nodes[i].gridItem.index[drow] = mkIndex(i+1) .. mkIndex(i+2)
      parent.children.add(nodes[i])
      nodes[i].parent = parent
    nodes[2].cxMin[drow] = csFixed(150)
    check gridTemplate.lines[dcol][0].track == csAuto()

    # ==== process grid ====
    computeLayout(parent)

    check parent.box.w == 50
    check parent.box.h == 500
    check nodes[0].gridItem.span[dcol] == 1'i16 .. 2'i16
    check nodes[0].gridItem.span[drow] == 1'i16 .. 2'i16
    check nodes[1].gridItem.span[dcol] == 1'i16 .. 2'i16
    check nodes[1].gridItem.span[drow] == 2'i16 .. 3'i16

    check nodes[0].box == uiBox(0, 0, 50, 50)
    check nodes[1].box == uiBox(0, 50, 50, 50)
    check nodes[2].box == uiBox(0, 100, 50, 150)
    check nodes[3].box == uiBox(0, 250, 50, 50)

    for i in 0..7:
      if i != 2:
        check nodes[i].box.w == 50
        check nodes[i].box.h == 50

    check nodes[7].box == uiBox(0, 450, 50, 50)

  test "compute layout manual overflow rows fracs":
    # prettyPrintWriteMode = cmTerminal
    # defer: prettyPrintWriteMode = cmNone

    var gridTemplate: GridTemplate

    parseGridTemplateColumns gridTemplate, 1'fr
    parseGridTemplateRows gridTemplate, 1'fr
    gridTemplate.autos[drow] = 1'fr
    gridTemplate.justifyItems = CxStart
    gridTemplate.autoFlow = grRow
    var parent = TestNode(name: "parent", gridTemplate: gridTemplate)
    parent.cxSize[dcol] = csFixed(50)  # set fixed parent
    parent.cxSize[drow] = cx"max-content"  # set fixed parent
    # parent.cxSize[drow] = cx"auto"  # set fixed parent
    parent.frame = Frame(windowSize: uiBox(0, 0, 50, 400))

    var nodes = newSeq[TestNode](8)

    # ==== item a's ====
    for i in 0 ..< nodes.len():
      nodes[i] = TestNode(name: "b" & $(i),
                          cxMin: [50'ux, 50'ux],
                          gridItem: GridItem())
      nodes[i].gridItem.index[dcol] = mkIndex(1) .. mkIndex(2)
      nodes[i].gridItem.index[drow] = mkIndex(i+1) .. mkIndex(i+2)
      parent.children.add(nodes[i])
      nodes[i].parent = parent
      
    nodes[2].cxMin[drow] = csFixed(150)
    check gridTemplate.lines[dcol][0].track == 1'fr

    # ==== process grid ====
    computeLayout(parent)

    check parent.box.w == 50
    check parent.box.h == 500
    check nodes[0].gridItem.span[dcol] == 1'i16 .. 2'i16
    check nodes[0].gridItem.span[drow] == 1'i16 .. 2'i16
    check nodes[1].gridItem.span[dcol] == 1'i16 .. 2'i16
    check nodes[1].gridItem.span[drow] == 2'i16 .. 3'i16

    check nodes[0].box == uiBox(0, 0, 50, 50)

    check nodes[1].box == uiBox(0, 50, 50, 50)
    check nodes[2].box == uiBox(0, 100, 50, 150)
    check nodes[3].box == uiBox(0, 250, 50, 50)

    for i in 0..7:
      if i != 2:
        check nodes[i].box.w == 50
        check nodes[i].box.h == 50

    check nodes[7].box == uiBox(0, 450, 50, 50)
    # echo "nodes[7]: ", nodes[7].box

  test "compute layout auto only":
    var gridTemplate: GridTemplate

    parseGridTemplateColumns gridTemplate, 1'fr
    # parseGridTemplateRows gridTemplate, 1'fr
    gridTemplate.autos[drow] = 90'ux
    gridTemplate.justifyItems = CxStart
    gridTemplate.autoFlow = grRow
    var parent = TestNode()
    parent.box.w = 50
    parent.box.h = 400

    var nodes = newSeq[TestNode](8)

    # ==== item a's ====
    for i in 0 ..< nodes.len():
      nodes[i] = TestNode(name: "b" & $(i),
                          box: uiBox(0,0,200,200),
                          gridItem: GridItem())
      # nodes[i].gridItem.index[dcol] = mkIndex(1) .. mkIndex(2)
      # nodes[i].gridItem.index[drow] = mkIndex(i+1) .. mkIndex(i+2)
    nodes[2].box.h = 150
    check gridTemplate.lines[dcol][0].track == 1'fr

    # ==== process grid ====
    parent.children = nodes
    let box1 = gridTemplate.computeNodeLayout(parent)
    let box = gridTemplate.computeNodeLayout(parent)
    echo "grid template:post: ", gridTemplate
    echo ""
    # printChildrens()
    # print gridTemplate.overflowSizes

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