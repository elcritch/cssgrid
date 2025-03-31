import typetraits
import sequtils

import unittest
import cssgrid/numberTypes
import cssgrid/gridtypes
import cssgrid/parser
import cssgrid/prettyprints

import cssgrid/layout

import pretty
import macros

import commontestutils

suite "grids":

  test "basic grid template":
    var gt = newGridTemplate(
      columns = @[initGridLine(csFrac(1))],
      rows = @[initGridLine(csFrac(1))],
    )
    check gt.lines[dcol].len() == 1
    check gt.lines[drow].len() == 1

  test "basic grid compute":
    # Create a parent node with 2x2 grid template
    var parent = TestNode(name: "parent")
    parent.gridTemplate = newGridTemplate(
      columns = @[initGridLine 1'fr, initGridLine 1'fr], 
      rows = @[gl 1'fr, gl 1'fr]
    )
    parent.cxSize = [100'ux, 100'ux]  # Fixed size container
    parent.frame = Frame(windowSize: uiBox(0, 0, 100, 100))
    
    # Compute the layout
    computeLayout(parent)
    
    # Check grid line positions
    check parent.gridTemplate.lines[dcol][0].start == 0.UiScalar
    check parent.gridTemplate.lines[dcol][1].start == 50.UiScalar
    check parent.gridTemplate.lines[drow][0].start == 0.UiScalar
    check parent.gridTemplate.lines[drow][1].start == 50.UiScalar

  test "3x3 grid compute with frac's":
    # Create a parent node with 3x3 grid template
    var parent = TestNode(name: "parent")
    parent.gridTemplate = newGridTemplate(
      columns = @[gl 1'fr, gl 1'fr, gl 1'fr],
      rows = @[gl 1'fr, gl 1'fr, gl 1'fr]
    )
    parent.cxSize = [100'ux, 100'ux]  # Fixed size container
    parent.frame = Frame(windowSize: uiBox(0, 0, 100, 100))
    
    # Compute the layout
    computeLayout(parent)
    
    # Check grid line positions
    checks parent.gridTemplate.lines[dcol][0].start.float == 0.0
    checks parent.gridTemplate.lines[dcol][1].start.float == 33.3333.toVal
    checks parent.gridTemplate.lines[dcol][2].start.float == 66.6666.toVal
    checks parent.gridTemplate.lines[drow][0].start.float == 0.0
    checks parent.gridTemplate.lines[drow][1].start.float == 33.3333.toVal
    checks parent.gridTemplate.lines[drow][2].start.float == 66.6666.toVal

  test "4x1 grid test":
    # Create a parent node with 4x1 grid template
    var parent = TestNode(name: "parent")
    parent.gridTemplate = newGridTemplate(
      columns = @[1'fr.gl, initGridLine(5.csFixed), 1'fr.gl, 1'fr.gl, initGridLine(csEnd())],
      rows = @[initGridLine(csEnd())]
    )
    parent.cxSize = [100'ux, 100'ux]  # Fixed size container
    parent.frame = Frame(windowSize: uiBox(0, 0, 100, 100))
    
    # Compute the layout
    computeLayout(parent)
    
    # Check grid line positions
    checks parent.gridTemplate.lines[dcol][0].start.float == 0.0
    checks parent.gridTemplate.lines[dcol][1].start.float == 31.6666.toVal
    checks parent.gridTemplate.lines[dcol][2].start.float == 36.6666.toVal
    when distinctBase(UiScalar) is SomeFloat:
      checks parent.gridTemplate.lines[dcol][3].start.float == 68.3333.toVal
    checks parent.gridTemplate.lines[drow][0].start.float == 0.0

  test "initial macros":
    var gridTemplate: GridTemplate

    # grid-template-columns: [first] 40px [line2] 50px [line3] auto [col4-start] 50px [five] 40px [end];
    parseGridTemplateColumns gridTemplate, ["first"] 40'ux ["second", "line2"] 50'pp ["line3"] auto ["col4-start"] 50'ux ["five"] 40'ux ["end"]

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
    # Create a parent node
    var parent = TestNode(name: "parent")
    
    # Create and configure the grid template
    parent.gridTemplate = GridTemplate()
    
    # Same grid template definition as before
    parseGridTemplateColumns parent.gridTemplate, ["first"] 40'ux \
                                  ["second", "line2"] 50'ux \
                                  ["line3"] auto \
                                  ["col4-start"] 50'ux \
                                  ["five"] 40'ux \
                                  ["end"]
    parseGridTemplateRows parent.gridTemplate, ["row1-start"] 25'pp \
                                ["row1-end"] 100'ux \
                                ["third-line"] auto \
                                ["last-line"]
    
    # Set explicit container size
    parent.cxSize = [1000'ux, 1000'ux]
    parent.frame = Frame(windowSize: uiBox(0, 0, 1000, 1000))
    
    # Compute the layout
    computeLayout(parent)
    
    # Check grid line positions
    let gt = parent.gridTemplate
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

  test "compute others":
    # Create a parent node
    var parent = TestNode(name: "parent")
    
    # Create and configure the grid template
    parent.gridTemplate = GridTemplate()
    
    # Parse the grid template columns and rows
    parseGridTemplateColumns parent.gridTemplate, ["first"] 40'ux \
      ["second", "line2"] 50'ux \
      ["line3"] auto \
      ["col4-start"] 50'ux \
      ["five"] 40'ux ["end"]
    parseGridTemplateRows parent.gridTemplate, ["row1-start"] 25'pp \
      ["row1-end"] 100'ux \
      ["third-line"] auto ["last-line"]

    # Set the gaps
    parent.gridTemplate.gaps[dcol] = 10.UiScalar
    parent.gridTemplate.gaps[drow] = 10.UiScalar
    
    # Set explicit container size
    parent.cxSize = [1000'ux, 1000'ux]
    parent.frame = Frame(windowSize: uiBox(0, 0, 1000, 1000))
    
    # Compute the layout
    computeLayout(parent)
    
    # Check grid line positions
    let gt = parent.gridTemplate
    check gt.lines[dcol][0].start.float == 0.0
    check gt.lines[dcol][1].start.float == 50.0
    check gt.lines[dcol][2].start.float == 110.0
    check gt.lines[dcol][3].start.float == 900.0
    check gt.lines[dcol][4].start.float == 960.0
    check gt.lines[dcol][5].start.float == 1000.0

    check gt.lines[drow][0].start.float == 0.0
    check gt.lines[drow][1].start.float == 260.0
    check gt.lines[drow][2].start.float == 370.0
    check gt.lines[drow][3].start.float == 1000.0
    
  test "compute macro and item layout":
    # Create a parent node
    var parent = TestNode(name: "parent")
    
    # Create and configure the grid template
    parent.gridTemplate = GridTemplate()
    
    # Parse the grid template
    parseGridTemplateColumns parent.gridTemplate, ["first"] 40'ux ["second", "line2"] 50'ux ["line3"] auto ["col4-start"] 50'ux ["five"] 40'ux ["end"]
    parseGridTemplateRows parent.gridTemplate, ["row1-start"] 25'pp ["row1-end"] 100'ux ["third-line"] auto ["last-line"]
    
    # Set explicit container size
    parent.cxSize = [1000'ux, 1000'ux]
    parent.frame = Frame(windowSize: uiBox(0, 0, 1000, 1000))
    
    # Create grid item
    var gridItem = newGridItem()
    gridItem.column.a = 2.mkIndex
    gridItem.column.b = "five".mkIndex
    gridItem.row.a = "row1-start".mkIndex
    gridItem.row.b = 3.mkIndex
    
    # Create child node with grid item
    let child = TestNode(name: "child", box: uiBox(0, 0, 0, 0), gridItem: gridItem)
    parent.children.add(child)
    child.parent = parent
    
    # Compute the layout
    computeLayout(parent)
    
    # Verify grid item spans and position
    check gridItem.span[dcol].a == 2
    check gridItem.span[dcol].b == 5
    check child.box.x.float == 40.0
    check child.box.w.float == 920.0
    check child.box.y.float == 0.0
    check child.box.h.float == 350.0

  test "compute item layout with alignment":
    skip()
    # Create a parent node
    var parent = TestNode(name: "parent")
    
    # Create and configure the grid template
    parent.gridTemplate = GridTemplate()
    
    # Parse the grid template
    parseGridTemplateColumns parent.gridTemplate, [first] 40'ux ["second", "line2"] 50'ux \
        ["line3"] auto ["col4-start"] 50'ux ["five"] 40'ux ["end"]
    parseGridTemplateRows parent.gridTemplate, ["row1-start"] 25'pp ["row1-end"] 100'ux \
        ["third-line"] auto ["last-line"]
    
    # Set explicit container size
    parent.cxSize = [1000'ux, 1000'ux]
    parent.frame = Frame(windowSize: uiBox(0, 0, 1000, 1000))
    
    # Create content and grid item
    let contentSize = uiSize(500, 200)
    var gridItem = newGridItem()
    gridItem.column.a = 2.mkIndex
    gridItem.column.b = "five".mkIndex
    gridItem.row.a = "row1-start".mkIndex
    gridItem.row.b = 3.mkIndex
    
    # Create child node with grid item
    let child = TestNode(
      name: "child", 
      box: uiBox(0, 0, contentSize.w.float, contentSize.h.float), 
      gridItem: gridItem
    )
    parent.children.add(child)
    child.parent = parent
    
    # Test stretch alignment
    parent.gridTemplate.justifyItems = CxStretch
    parent.gridTemplate.alignItems = CxStretch
    computeLayout(parent)
    check child.box == uiBox(40, 0, 920, 350)

    # Test start alignment
    parent.gridTemplate.justifyItems = CxStart
    parent.gridTemplate.alignItems = CxStart
    computeLayout(parent)
    check child.box == uiBox(40, 0, 500, 200)

    # Test end alignment
    parent.gridTemplate.justifyItems = CxEnd
    parent.gridTemplate.alignItems = CxEnd
    computeLayout(parent)
    check child.box == uiBox(460, 150, 500, 200)
    
    # Test start / stretch alignment
    parent.gridTemplate.justifyItems = CxStart
    parent.gridTemplate.alignItems = CxStretch
    computeLayout(parent)
    check child.box == uiBox(40, 0, 500, 350)

    # Test stretch / start alignment
    parent.gridTemplate.justifyItems = CxStretch
    parent.gridTemplate.alignItems = CxStart
    computeLayout(parent)
    check child.box == uiBox(40, 0, 920, 200)
    
    # Test center alignment
    parent.gridTemplate.justifyItems = CxCenter
    parent.gridTemplate.alignItems = CxCenter
    computeLayout(parent)
    check child.box == uiBox(250, 75, 500, 200)
    
  test "compute layout with auto columns":
    # Create a parent node
    var parent = TestNode(name: "parent")
    
    # Create and configure the grid template
    parent.gridTemplate = GridTemplate()
    
    # Set up grid with two explicit columns
    parseGridTemplateColumns parent.gridTemplate, ["a"] 60'ux ["b"] 60'ux
    parseGridTemplateRows parent.gridTemplate, 90'ux 90'ux
    
    # Set parent container size
    parent.cxSize = [1000'ux, 1000'ux]
    parent.frame = Frame(windowSize: uiBox(0, 0, 1000, 1000))
    
    let contentSize = uiSize(120, 90)

    # Create first child (item a)
    var itema = newGridItem()
    itema.column = 1 // 2
    itema.row = 2 // 3
    let nodea = TestNode(
      name: "a", 
      box: uiBox(0, 0, contentSize.w.float, contentSize.h.float),
      gridItem: itema
    )
    parent.children.add(nodea)
    nodea.parent = parent

    # Create second child (item b)
    var itemb = newGridItem()
    itemb.column = 5 // 6
    itemb.row = 2 // 3
    let nodeb = TestNode(
      name: "b", 
      box: uiBox(0, 0, contentSize.w.float, contentSize.h.float),
      gridItem: itemb
    )
    parent.children.add(nodeb)
    nodeb.parent = parent
    
    # Compute the layout
    computeLayout(parent)
    
    # Check item positions
    check nodea.box == uiBox(0, 90, 60, 90)
    check nodeb.box == uiBox(120, 90, 0, 90)  # Note: width is reported as 0

  test "compute layout with fixed 1x1":
    # Create a parent node
    var parent = TestNode(name: "parent")
    
    # Create and configure the grid template
    parent.gridTemplate = GridTemplate()
    
    # Set up grid with one column and row
    parseGridTemplateColumns parent.gridTemplate, 60'ux
    parseGridTemplateRows parent.gridTemplate, 90'ux
    
    # Set parent container size
    parent.cxSize = [1000'ux, 1000'ux]
    parent.frame = Frame(windowSize: uiBox(0, 0, 1000, 1000))
    
    let contentSize = uiSize(120, 90)

    # Create child
    var itema = newGridItem()
    itema.column = 1 // 2
    itema.row = 1 // 2
    let nodea = TestNode(
      name: "a", 
      box: uiBox(0, 0, contentSize.w.float, contentSize.h.float),
      gridItem: itema
    )
    parent.children.add(nodea)
    nodea.parent = parent
    
    # Compute the layout
    computeLayout(parent)
    
    # Check item position
    check nodea.box == uiBox(0, 0, 60, 90)

  test "compute layout with auto columns with fixed size":
    # Create a parent node
    var parent = TestNode(name: "parent")
    
    # Create and configure the grid template
    parent.gridTemplate = GridTemplate()
    
    # Set up grid with two columns and two rows
    parseGridTemplateColumns parent.gridTemplate, ["a"] 60'ux ["b"] 60'ux
    parseGridTemplateRows parent.gridTemplate, 90'ux 90'ux
    parent.gridTemplate.autos[dcol] = 60.csFixed()
    parent.gridTemplate.autos[drow] = 20.csFixed()
    
    # Set parent container size
    parent.cxSize = [1000'ux, 1000'ux]
    parent.frame = Frame(windowSize: uiBox(0, 0, 1000, 1000))
    
    let contentSize = uiSize(30, 30)

    # Create first child (item a)
    var itema = newGridItem()
    itema.column = 1 // 2
    itema.row = 2 // 3
    let nodea = TestNode(
      name: "a", 
      box: uiBox(0, 0, contentSize.w.float, contentSize.h.float),
      gridItem: itema
    )
    parent.children.add(nodea)
    nodea.parent = parent

    # Create second child (item b)
    var itemb = newGridItem()
    itemb.column = 5 // 6
    itemb.row = 3 // 4
    let nodeb = TestNode(
      name: "b", 
      box: uiBox(0, 0, contentSize.w.float, contentSize.h.float),
      gridItem: itemb
    )
    parent.children.add(nodeb)
    nodeb.parent = parent
    
    # Compute the layout
    computeLayout(parent)
    
    # Check item positions
    check nodea.box == uiBox(0, 90, 60, 90)
    check nodeb.box == uiBox(240, 180, 60, 20)

  test "compute layout with auto flow":
    # Create a parent node
    var parent = TestNode(name: "parent")
    
    # Create and configure the grid template
    parent.gridTemplate = GridTemplate()
    
    # Set up grid with five columns and two rows
    parseGridTemplateColumns parent.gridTemplate, 60'ux 60'ux 60'ux 60'ux 60'ux
    parseGridTemplateRows parent.gridTemplate, 33'ux 33'ux
    parent.gridTemplate.justifyItems = CxStretch
    
    # Set parent container size
    parent.cxSize = [1000'ux, 1000'ux]
    parent.frame = Frame(windowSize: uiBox(0, 0, 1000, 1000))
    
    let contentSize = uiSize(30, 30)
    
    # Create 8 child nodes
    var nodes = newSeq[TestNode](8)

    # Create item a with fixed position
    var itema = newGridItem()
    itema.column = 1 // 2
    itema.row = 1 // 3
    nodes[0] = TestNode(
      name: "a", 
      box: uiBox(0, 0, contentSize.w.float, contentSize.h.float),
      gridItem: itema
    )
    parent.children.add(nodes[0])
    nodes[0].parent = parent

    # Create item e with fixed position
    var iteme = newGridItem()
    iteme.column = 5 // 6
    iteme.row = 1 // 3
    nodes[1] = TestNode(
      name: "e", 
      box: uiBox(0, 0, contentSize.w.float, contentSize.h.float),
      gridItem: iteme
    )
    parent.children.add(nodes[1])
    nodes[1].parent = parent

    # Create auto-placed items
    for i in 2 ..< nodes.len():
      nodes[i] = TestNode(
        name: "b" & $(i-2),
        box: uiBox(0, 0, contentSize.w.float, contentSize.h.float)
      )
      parent.children.add(nodes[i])
      nodes[i].parent = parent
    
    # Compute the layout
    computeLayout(parent)
    
    # Check item positions
    check nodes[0].box == uiBox(0, 0, 60, 66)
    check nodes[1].box == uiBox(240, 0, 60, 66)
    
    # Check auto-placed items
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
    
    # Check sizes of auto-placed items
    for i in 2 ..< nodes.len() - 1:
      check nodes[i].box.w == 60
      check nodes[i].box.h == 33

  test "compute layout auto flow overflow":
    # Create a parent node
    var parent = TestNode(name: "parent")
    
    # Create and configure the grid template
    parent.gridTemplate = GridTemplate()
    
    # Configure grid with one column and row
    parseGridTemplateColumns parent.gridTemplate, 100'ux
    parseGridTemplateRows parent.gridTemplate, 100'ux
    
    # Set auto row height and alignment
    parent.gridTemplate.autos[drow] = csFixed 100.0
    parent.gridTemplate.justifyItems = CxStretch
    parent.gridTemplate.autoFlow = grRow
    
    # Set parent container size
    parent.cxSize = [100'ux, 100'ux]  # Using same width as the column
    parent.frame = Frame(windowSize: uiBox(0, 0, 100, 100))
    
    # Create four child nodes
    var nodes = newSeq[TestNode](4)
    for i in 0 ..< nodes.len():
      nodes[i] = TestNode(
        name: "b" & $(i),
        box: uiBox(0, 0, 100, 100)  # Set content size equal to grid cell
      )
      parent.children.add(nodes[i])
      nodes[i].parent = parent
    
    # Compute the layout
    computeLayout(parent)
    
    # Check the parent box dimensions (height expanded to fit all auto rows)
    check parent.box.w == 100
    check parent.box.h == 400
    
    # Check that grid items were placed correctly
    check nodes[0].gridItem.span[dcol] == 1'i16 .. 2'i16
    check nodes[0].gridItem.span[drow] == 1'i16 .. 2'i16
    check nodes[1].gridItem.span[dcol] == 1'i16 .. 2'i16
    check nodes[1].gridItem.span[drow] == 2'i16 .. 3'i16
    
    # Check positions of the grid items
    check nodes[0].box == uiBox(0, 0, 100, 100)
    check nodes[1].box == uiBox(0, 100, 100, 100)
    check nodes[3].box == uiBox(0, 300, 100, 100)

  test "compute layout auto flow overflow (colums)":

    var gridTemplate: GridTemplate
    parseGridTemplateColumns gridTemplate, 1'fr
    parseGridTemplateRows gridTemplate, 1'fr
    gridTemplate.autos[dcol] = csFixed 100.0
    gridTemplate.justifyItems = CxStart
    gridTemplate.alignItems = CxStart
    gridTemplate.autoFlow = grColumn

    var parent = TestNode()
    parent.cxOffset = [0'ux, 0'ux]
    parent.cxSize = [400'ux, 50'ux]
    parent.frame = Frame(windowSize: uiBox(0, 0, 400, 50))
    parent.gridTemplate = gridTemplate

    var nodes = newSeq[TestNode](4)

    # ==== item a's ====
    nodes[0] = newTestNode("b0", parent=parent)
    nodes[1] = newTestNode("b1", parent=parent)
    nodes[2] = newTestNode("b2", parent=parent)
    nodes[3] = newTestNode("b3", parent=parent)

    nodes[0].cxSize = [40'ux, 40'ux]
    nodes[1].cxSize = [50'ux, 50'ux]
    nodes[2].cxSize = [50'ux, 50'ux]
    nodes[3].cxSize = [50'ux, 50'ux]

    # ==== process grid ====
    parent.children = nodes
    # prettyPrintWriteMode = cmTerminal
    # defer: prettyPrintWriteMode = cmNone
    computeLayout(parent)
    # printLayout(parent, cmTerminal)

    # TODO: FIXME!!!
    # check box.w == 750
    check parent.box.h == 50
    check nodes[0].gridItem.span[dcol] == 1'i16 .. 2'i16
    check nodes[0].gridItem.span[drow] == 1'i16 .. 2'i16
    check nodes[1].gridItem.span[dcol] == 2'i16 .. 3'i16
    check nodes[1].gridItem.span[drow] == 1'i16 .. 2'i16
    check nodes[2].gridItem.span[dcol] == 3'i16 .. 4'i16
    check nodes[2].gridItem.span[drow] == 1'i16 .. 2'i16
    check nodes[3].gridItem.span[dcol] == 4'i16 .. 5'i16
    check nodes[3].gridItem.span[drow] == 1'i16 .. 2'i16

    # TODO: FIXME!!!
    # the min fr track len should account for the min-content size
    check nodes[0].box == uiBox(0, 0, 40, 40)
    check nodes[1].box == uiBox(100, 0, 50, 50)
    check nodes[2].box == uiBox(200, 0, 50, 50)
    check nodes[3].box == uiBox(300, 0, 50, 50)

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
    parent.gridTemplate = gridTemplate
    let contentSize = uiSize(30, 30)
    var nodes = newSeq[TestNode](8)

    # ==== item a's ====
    for i in 0 ..< nodes.len():
      nodes[i] = TestNode(name: "b" & $(i),
                          box: uiBox(0,0,0,0),
                          gridItem: nil, parent: parent)
      nodes[i].cxSize = [50'ux, 50'ux]
      parent.children.add(nodes[i])
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
    parent.cxSize[drow] = cx"auto"  # set fixed parent
    # parent.cxSize[drow] = cx"max-content"  # set fixed parent
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
    prettyPrintWriteMode = cmTerminal
    defer: prettyPrintWriteMode = cmNone
    computeLayout(parent)
    printLayout(parent, cmTerminal)

    check parent.box.w == 50
    check parent.box.h == 1200
    check nodes[0].gridItem.span[dcol] == 1'i16 .. 2'i16
    check nodes[0].gridItem.span[drow] == 1'i16 .. 2'i16
    check nodes[1].gridItem.span[dcol] == 1'i16 .. 2'i16
    check nodes[1].gridItem.span[drow] == 2'i16 .. 3'i16

    check nodes[0].box == uiBox(0, 0, 50, 150)

    check nodes[1].box == uiBox(0, 150, 50, 150)
    check nodes[2].box == uiBox(0, 300, 50, 150)
    check nodes[3].box == uiBox(0, 450, 50, 150)

    for i in 0..7:
      if i != 2:
        check nodes[i].box.w == 50
        check nodes[i].box.h == 150


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
    parent.gridTemplate = gridTemplate
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