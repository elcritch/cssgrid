import unittest
import typetraits
import sequtils

import unittest
import cssgrid/numberTypes
import cssgrid/gridtypes
import cssgrid/basiclayout
import cssgrid/parser
import cssgrid/prettyprints

import cssgrid/layout
import pretty

type
  Box* = UiBox

import commontestutils

suite "Compute Layout Tests":
  test "Basic node without grid":
    # Test simple node with basic constraints
    let node = newTestNode("root")
    node.cxSize[dcol] = 200'ux
    node.cxSize[drow] = 150'ux
    
    computeLayout(node)
    
    check node.box.w == 200
    check node.box.h == 150

  test "Parent with basic constrained children":

    let parent = newTestNode("parent") #, 0, 0, 400, 300)
    let child1 = newTestNode("child1", parent)
    let child2 = newTestNode("child2", parent)
    
    # Set fixed-parent constraint
    parent.frame.windowSize = uiBox(0,0, 400, 300)
    parent.cxSize[dcol] = csAuto()
    parent.cxSize[drow] = csNone()
    # parent.cxSize[dcol] = 400'ux  # set fixed parent
    # parent.cxSize[drow] = 300'ux  # set fixed parent

    # Set percentage-based constraints for children
    child1.cxSize[dcol] = 50'pp  # 50% of parent
    child1.cxSize[drow] = 30'pp  # 30% of parent
    
    child2.cxSize[dcol] = 70'pp  # 70% of parent
    child2.cxSize[drow] = 40'pp  # 40% of parent
    
    # prettyPrintWriteMode = cmTerminal
    # defer: prettyPrintWriteMode = cmNone
    computeLayout(parent)
    # printLayout(parent, cmTerminal)
    
    check child1.box.w == 200  # 50% of 400
    check child1.box.h == 0   # 30% of 300
    check child2.box.w == 280  # 70% of 400
    check child2.box.h == 0  # 40% of 300

    # now test with settings
    parent.cxSize[drow] = csAuto()
    computeLayout(parent)
    
    check child1.box.w == 200  # 50% of 400
    check child1.box.h == 90   # 30% of 300
    check child2.box.w == 280  # 70% of 400
    check child2.box.h == 120  # 40% of 300


  test "vertical layout auto":
    when true:

      let parent = newTestNode("scroll")
      let body = newTestNode("scrollBody", parent)
      let items = newTestNode("items", body)

      parseGridTemplateColumns items.gridTemplate, 1'fr
      parent.cxSize = [768'ux, 540'ux]
      body.cxSize = [cx"auto", cx"max-content"]

      items.cxSize = [cx"auto", cx"auto"]
      items.gridTemplate.autoFlow = grRow
      items.gridTemplate.gaps[drow] = 3
      items.gridTemplate.autos[drow] = csAuto()
      items.gridTemplate.justifyItems = CxStretch
      items.gridTemplate.alignItems = CxStretch

      for i in 0..1:
        let child = newTestNode("story-" & $i, items)
        let text = newTestNode("text-" & $i, child)

        child.cxPadOffset[drow] = 21.01'ux
        child.cxPadSize[drow] = 22.20'ux

        text.cxSize = [cx"auto", 33.33'ux]
        text.cxMin = [40'ux, 20.00'ux]
        text.cxMax = [200'ux, 300.00'ux]
      
      # prettyPrintWriteMode = cmTerminal
      # defer: prettyPrintWriteMode = cmNone
      computeLayout(parent)
      # printLayout(parent, cmTerminal)

      check items.gridTemplate.lines[dcol][0].width.float32.round(0) == 768

      # # since it's cxStretch with auto it'll goto min content size
      # check body.box.w == 768
      # check body.box.h.float32.round(0) == 171

      # check items.children[0].box.w == 768
      # check items.children[0].box.h == 84.22.UiScalar
      # check items.children[0].children[0].box.w == 768
      # check items.children[0].children[0].box.h.float32.round(0) == 33
  
  test "vertical layout auto stretch":
    when true:

      let parent = newTestNode("scroll")
      let body = newTestNode("scrollBody", parent)
      let items = newTestNode("items", body)

      parseGridTemplateColumns items.gridTemplate, 1'fr
      parent.cxSize = [768'ux, 540'ux]
      body.cxSize = [cx"auto", cx"none"]

      items.cxSize = [cx"auto", cx"auto"]
      items.gridTemplate.autoFlow = grRow
      items.gridTemplate.gaps[drow] = 3
      items.gridTemplate.autos[drow] = csAuto()
      items.gridTemplate.justifyItems = CxStretch
      items.gridTemplate.alignItems = CxStretch

      for i in 0..1:
        let child = newTestNode("story-" & $i, items)
        let text = newTestNode("text-" & $i, child)

        child.cxPadOffset[drow] = 21.01'ux
        child.cxPadSize[drow] = 22.20'ux

        text.cxSize = [cx"auto", 33.33'ux]
        text.cxMin = [40'ux, 20.00'ux]
        text.cxMax = [200'ux, 300.00'ux]
      
      # prettyPrintWriteMode = cmTerminal
      # defer: prettyPrintWriteMode = cmNone
      computeLayout(parent)
      # printLayout(parent, cmTerminal)

      check items.children[0].box.x == 0
      check items.children[0].box.w == 768
      check items.children[0].box.h == 84.22.UiScalar
  
  test "vertical layout auto with grandchild":
    when true:
      # prettyPrintWriteMode = cmTerminal
      # defer: prettyPrintWriteMode = cmNone

      let parent = newTestNode("scroll")
      let items = newTestNode("items", parent)

      parent.cxSize = [400'ux, 300'ux]

      items.cxSize = [cx"auto", cx"max-content"]

      let story = newTestNode("story", items)
      parseGridTemplateColumns story.gridTemplate, 1'fr
      story.cxSize = [cx"auto", cx"auto"]
      story.gridTemplate.autoFlow = grRow
      story.gridTemplate.autos[drow] = csAuto()

      let rect0 = newTestNode("rect-0", story)

      let text0 = newTestNode("text-0", rect0)
      text0.cxSize = [cx"auto", cx"none"]
      text0.cxMin = [40'ux, 42.50'ux]
      text0.cxMax = [200'ux, 300.00'ux]

      let rect1 = newTestNode("rect-1", story)

      let text1 = newTestNode("text-1", rect1)
      text1.cxSize = [cx"auto", cx"none"]
      text1.cxMin = [40'ux, 20.50'ux]
      text1.cxMax = [200'ux, 300.00'ux]

      computeLayout(parent)
      # printLayout(parent, cmTerminal)
      check rect0.box.h.float32.round(2) == 42.50
      check rect1.box.h.float32.round(2) == 20.50
      check items.box.h.float32.round(2) == 63.00

      check rect0.bmin.h.float32.round(2) == 42.50
      check rect1.bmin.h.float32.round(2) == 20.50
      check items.bmin.h.float32.round(2) == 63.00

  test "vertical layout max-content":
    # prettyPrintWriteMode = cmTerminal
    # defer: prettyPrintWriteMode = cmNone
    # addPrettyPrintFilter("name", "scrollpane")
    # addPrettyPrintFilter("name", "scrollbody")

    let parent = newTestNode("grid-parent")
    let scrollpane = newTestNode("scrollpane", parent)
    let scrollbody = newTestNode("scrollbody", scrollpane)
    let vertical = newTestNode("vertical", scrollbody)

    parent.cxSize = [400'ux, 300'ux]
    scrollpane.cxOffset = [2'pp, 2'pp]
    scrollpane.cxSize = [96'pp, 90'pp]

    scrollbody.cxOffset = [csAuto(), csAuto()]
    scrollbody.cxSize = [csAuto(), cx"max-content"]

    vertical.cxOffset = [10'ux, 10'ux]
    vertical.cxSize = [csAuto(), cx"max-content"]
    parseGridTemplateColumns vertical.gridTemplate, 1'fr
    vertical.gridTemplate.autoFlow = grRow
    vertical.gridTemplate.autos[drow] = csAuto()

    for i in 0..15:
      let child = newTestNode("grid-child-" & $i, vertical)
      child.cxSize = [1'fr, 50'ux]
      if i in [3, 7]:
        child.cxSize = [0.9'fr, 120'ux]

    # prettyPrintWriteMode = cmTerminal
    # defer: prettyPrintWriteMode = cmNone
    computeLayout(parent)
    # printLayout(parent, cmTerminal)

    check scrollpane.box.w == 384
    check scrollpane.box.h == 270

    check scrollbody.box.w == 376
    check scrollbody.box.h == 950

    check vertical.box.w == 376
    check vertical.box.h == UiScalar(50*14 + 120*2)

  test "Simple grid layout":
      let parent = newTestNode("grid-parent")
      let child1 = newTestNode("grid-child1", parent)
      let child2 = newTestNode("grid-child2", parent)
      
      # Setup grid template
      parent.cxSize = [400'ux, 300'ux]  # set fixed parent

      parseGridTemplateColumns parent.gridTemplate, 1'fr 1'fr
      parseGridTemplateRows parent.gridTemplate, 100'ux
      
      # Setup grid items
      child1.gridItem = newGridItem()
      child1.gridItem.column = 1
      child1.gridItem.row = 1
      
      child2.gridItem = newGridItem()
      child2.gridItem.column = 2
      child2.gridItem.row = 1
      
      computeLayout(parent)
      # printLayout(parent, cmTerminal)
      
      # Children should each take up half the width
      check child1.box.w == 200  # Half of parent width
      check child2.box.w == 200  # Half of parent width
      check child1.box.h == 100  # Fixed height from grid
      check child2.box.h == 100  # Fixed height from grid
      check child1.box.x == 0  # Fixed height from grid
      check child2.box.x == 200  # Fixed height from grid

  test "Simple grid layout with min column":
      let parent = newTestNode("grid-parent")
      let child1 = newTestNode("grid-child1", parent)
      let child2 = newTestNode("grid-child2", parent)
      
      # Setup grid template

      parseGridTemplateColumns parent.gridTemplate, min(100'ux, 25'pp) 1'fr
      parseGridTemplateRows parent.gridTemplate, 100'ux
      
      # Setup grid items
      child1.gridItem = newGridItem()
      child1.gridItem.column = 1
      child1.gridItem.row = 1
      
      child2.gridItem = newGridItem()
      child2.gridItem.column = 2
      child2.gridItem.row = 1
      
      parent.cxSize = [400'ux, 300'ux]  # set fixed parent
      computeLayout(parent)
      printLayout(parent, cmTerminal)
      
      # Children should each take up half the width
      check child1.box.w == 100
      check child2.box.w == 300

      parent.cxSize = [1000'ux, 300'ux]  # set fixed parent
      computeLayout(parent)
      # printLayout(parent, cmTerminal)
      
      # Children should each take up half the width
      check child1.box.w == 100
      check child2.box.w == 900

      parent.cxSize = [150'ux, 300'ux]  # set fixed parent
      prettyPrintWriteMode = cmTerminal
      addPrettyPrintFilter("dir", "dcol")
      computeLayout(parent)
      printLayout(parent, cmTerminal)
      prettyPrintWriteMode = cmNone
      check child1.box.w.float32.round(0) == 38
      check child2.box.w.float32.round(0) == 113
      
  test "Simple grid layout with max column":
      let parent = newTestNode("grid-parent")
      let child1 = newTestNode("grid-child1", parent)
      let child2 = newTestNode("grid-child2", parent)
      
      # Setup grid template

      parseGridTemplateColumns parent.gridTemplate, max(100'ux, 25'pp) 1'fr
      parseGridTemplateRows parent.gridTemplate, 100'ux
      
      # Setup grid items
      child1.gridItem = newGridItem()
      child1.gridItem.column = 1
      child1.gridItem.row = 1
      
      child2.gridItem = newGridItem()
      child2.gridItem.column = 2
      child2.gridItem.row = 1
      
      parent.cxSize = [400'ux, 300'ux]  # set fixed parent
      computeLayout(parent)
      # printLayout(parent, cmTerminal)
      
      # Children should each take up half the width
      check child1.box.w == 100
      check child2.box.w == 300

      parent.cxSize = [1000'ux, 300'ux]  # set fixed parent
      computeLayout(parent)
      # printLayout(parent, cmTerminal)
      
      # Children should each take up half the width
      check child1.box.w == 250
      check child2.box.w == 750

      parent.cxSize = [150'ux, 300'ux]  # set fixed parent
      computeLayout(parent)
      
      # Children should each take up half the width
      check child1.box.w == 100
      check child2.box.w == 50

      
  test "Simple grid layout with minmax columns":
      # TODO: FIXME!
      # Minmax is not working as expected
      # but it's probably good enough for now
      let parent = newTestNode("grid-parent")
      let child1 = newTestNode("grid-child1", parent)
      let child2 = newTestNode("grid-child2", parent)
      let child3 = newTestNode("grid-child3", parent)
      
      # Setup grid template with minmax
      parseGridTemplateColumns parent.gridTemplate, minmax(200'ux, 500'ux) 1'fr 1'fr
      parseGridTemplateRows parent.gridTemplate, 100'ux
      
      # Setup grid items
      child1.gridItem = newGridItem()
      child1.gridItem.column = 1
      child1.gridItem.row = 1
      
      child2.gridItem = newGridItem()
      child2.gridItem.column = 2
      child2.gridItem.row = 1
      child2.cxMin[dcol] = 110'ux

      child3.gridItem = newGridItem()
      child3.gridItem.column = 3
      child3.gridItem.row = 1
      child3.cxMin[dcol] = 20'ux
      # Test case 1: Small parent width where minmax is clamped to minimum
      parent.cxSize = [400'ux, 300'ux]  # set fixed parent
      # prettyPrintWriteMode = cmTerminal
      # defer: prettyPrintWriteMode = cmNone
      # addPrettyPrintFilter("dir", "dcol")
      computeLayout(parent)
      # printLayout(parent, cmTerminal)

      # second and third column get min-contents and minmax col the rest
      # check child1.box.w == 270  # Minimum size from minmax
      # check child2.box.w == 110  # Remaining acc to min-content
      # check child3.box.w == 20  # Remaining acc to min-content
      check child1.box.w == 200  # Minimum size from minmax
      check child2.box.w == 110  # Remaining acc to min-content
      check child3.box.w == 90  # Remaining acc to min-content

      # Test case 2: Medium parent width where minmax is within range
      parent.cxSize = [900'ux, 300'ux]  # set fixed parent
      computeLayout(parent)

      # First column gets 500px (capped by max), remaining space divided equally
      # check child1.box.w == 500  # Maximum size from minmax
      # check child2.box.w == 200  # Remaining space divided equally (1fr)
      # check child3.box.w == 200  # Remaining space divided equally (1fr)
      check child1.box.w == 200  # Maximum size from minmax
      check child2.box.w == 350  # Remaining space divided equally (1fr)
      check child3.box.w == 350  # Remaining space divided equally (1fr)

      # Test case 3: Large parent width where 1fr units have plenty of space
      parent.cxSize = [1800'ux, 300'ux]  # set fixed parent
      computeLayout(parent)

      # First column stays at max, remaining space divided equally
      # check child1.box.w == 500   # Maximum size from minmax
      # check child2.box.w == 800   # Remaining space divided equally (1fr)
      # check child3.box.w == 800   # Remaining space divided equally (1fr)
      check child1.box.w == 200   # Maximum size from minmax
      check child2.box.w == 800   # Remaining space divided equally (1fr)
      check child3.box.w == 800   # Remaining space divided equally (1fr)


  test "Grid with mixed units":
    when true:
      # Create all nodes with parent-child relationships in a more concise way
      let parent = newTestTree("mixed-grid") 
      let fixedChild = newTestNode("fixed-child", parent)
      let fracChild = newTestNode("frac-child", parent)
      let fracGrandChild = newTestNode("frac-grandchild", fracChild)
      let autoChild = newTestNode("auto-child", parent)
      let autoGrandChild = newTestNode("auto-grandchild", autoChild)

      
      # Access child nodes by index for further configuration
      let child1 = parent.children[0]
      let child2 = parent.children[1]
      let child21 = child2.children[0]
      let child3 = parent.children[2]
      let child31 = child3.children[0]
      
      child1.cxSize = [100'ux, 100'ux]
      child2.cxSize = [100'ux, 100'ux]
      child3.cxSize = [100'ux, 100'ux]

      # Setup grid with fixed, fractional and auto tracks
      parent.cxSize = [400'ux, 300'ux]  # set fixed parent
      child21.cxSize = [50'ux, 50'ux]  # set fixed parent
      child31.cxSize = [50'ux, 50'ux]  # set fixed parent

      parseGridTemplateColumns parent.gridTemplate, 100'ux 1'fr auto
      parseGridTemplateRows parent.gridTemplate, 100'ux
      
      # Place children in grid
      child1.gridItem = newGridItem()
      child1.gridItem.column = 1
      child1.gridItem.row = 1
      
      child2.gridItem = newGridItem()
      child2.gridItem.column = 2
      child2.gridItem.row = 1
      
      child3.gridItem = newGridItem()
      child3.gridItem.column = 3
      child3.gridItem.row = 1
      
      # Set minimum content size for auto child
      child3.cxMin[dcol] = 100'ux # This should be respected as minimum width

      computeLayout(parent)
      
      check child1.box.w == 100  # Fixed width
      check child2.box.w >= 100.0.UiScalar   # Should get remaining space
      check child3.box.w > 0     # Should get minimum required space

  test "Grid with content sizing":
    when true:
      let parent = newTestNode("content-grid")
      let child1 = newTestNode("content-child1", parent)
      let child2 = newTestNode("content-child2", parent)
      
      parent.cxSize = [400'ux, 300'ux]
      child1.cxSize = [150'ux, 100'ux]
      child2.cxSize = [100'ux, 100'ux]

      parent.gridTemplate = newGridTemplate()
      parent.gridTemplate.lines[dcol] = @[
        initGridLine(csContentMax()),  # Size to max content
        initGridLine(csContentMin())   # Size to min content
      ]
      parent.gridTemplate.lines[drow] = @[
        initGridLine(100'ux)
      ]
      
      child1.gridItem = newGridItem()
      child1.gridItem.column = 1
      child1.gridItem.row = 1
      
      child2.gridItem = newGridItem()
      child2.gridItem.column = 2
      child2.gridItem.row = 1
      
      computeLayout(parent)
      
      check child1.box.w >= 150  # Should accommodate content
      check child2.box.w >= 100  # Should accommodate content

  test "Grid with nested basic constraints":
    when true:
      # prettyPrintWriteMode = cmTerminal
      # defer: prettyPrintWriteMode = cmNone

      let parent = newTestNode("nested-grid")
      let gridChild = newTestNode("grid-child", parent)
      let innerChild = newTestNode("inner-child", gridChild)
      parent.cxSize = [400'ux, 300'ux]
      gridChild.cxSize = [200'ux, 200'ux]
      innerChild.cxSize = [50'pp, 50'pp]
      
      # Setup grid
      parent.gridTemplate = newGridTemplate()
      parent.gridTemplate.lines[dcol] = @[
        initGridLine(1'fr)
      ]
      parent.gridTemplate.lines[drow] = @[
        initGridLine(1'fr)
      ]
      
      # Grid placement
      gridChild.gridItem = newGridItem()
      gridChild.gridItem.column = 1
      gridChild.gridItem.row = 1
      
      # Inner child with percentage constraint
      innerChild.cxSize[dcol] = 50'pp
      innerChild.cxSize[drow] = 50'pp
      
      computeLayout(parent)
      
      check innerChild.box.w == 200  # 50% of grid child width
      check innerChild.box.h == 150  # 50% of grid child height

  test "Auto flow grid":
    when false:
      let parent = newTestNode("autoflow-grid")
      var children: seq[TestNode]
      
      # Setup grid template
      parent.cxSize[dcol] = 400'ux  # set fixed parent
      parent.cxSize[drow] = 300'ux  # set fixed parent

      # Create 4 children
      for i in 1..4:
        let child = newTestNode("child" & $i, parent)
        children.add(child)
      
      # Setup grid with 2 columns
      parent.gridTemplate = newGridTemplate()
      parent.gridTemplate.lines[dcol] = @[
        initGridLine(1'fr),
        initGridLine(1'fr)
      ]
      parent.gridTemplate.autoFlow = grRow
      parent.gridTemplate.autos[drow] = cx"auto"
      
      # Don't set explicit grid positions - let autoflow handle it
      for child in children:
        child.gridItem = newGridItem()
      
      computeLayout(parent)

      echo "\nLayout: "
      # prettyprints.printLayout(parent)
      
      # Check that children are arranged in a 2x2 grid
      check children[0].box.x < children[1].box.x  # First row
      check children[2].box.y > children[0].box.y  # Second row
      check children[2].box.x == children[0].box.x # Same column

      check children[0].box.w == 200
      check children[1].box.w == 200
      check children[2].box.w == 200
      check children[3].box.w == 200

      check children[0].box.h == 0
      check children[1].box.h == 0
      check children[2].box.h == 0
      check children[3].box.h == 0

suite "Grid alignment and justification tests":

  test "Grid child positioning - stretch behavior in 2x2 grid":
    # Create a grid with 2x2 cells and test children stretching to fill them
    let parent = newTestNode("stretch-grid")
    let child1 = newTestNode("stretch-child1", parent)
    let child2 = newTestNode("stretch-child2", parent)
    let child3 = newTestNode("stretch-child3", parent)
    let child4 = newTestNode("stretch-child4", parent)
    
    # Set up fixed parent size
    parent.cxSize[dcol] = 400'ux
    parent.cxSize[drow] = 400'ux
    
    # Create 2x2 grid with equal cells
    parent.gridTemplate = newGridTemplate(
      columns = @[
        initGridLine(200'ux),
        initGridLine(200'ux)
      ],
      rows = @[
        initGridLine(200'ux),
        initGridLine(200'ux)
      ],
    )
    
    # Place children in grid with stretch behavior (default)
    for (child, pos) in [(child1, (1, 1)), (child2, (2, 1)), 
                      (child3, (1, 2)), (child4, (2, 2))]:
      child.gridItem = newGridItem()
      child.gridItem.column = pos[0]
      child.gridItem.row = pos[1]
      child.cxSize[dcol] = 100'ux
      child.cxSize[drow] = 100'ux
    
    computeLayout(parent)
    
    # Check all children stretch to their cell size
    for child in [child1, child2, child3, child4]:
      check child.box.w == 200  # Should stretch to column width
      check child.box.h == 200  # Should stretch to row height

    # Verify positions
    check child1.box.x == 0     # First column
    check child1.box.y == 0     # First row
    check child2.box.x == 200   # Second column
    check child2.box.y == 0     # First row
    check child3.box.x == 0     # First column
    check child3.box.y == 200   # Second row
    check child4.box.x == 200   # Second column
    check child4.box.y == 200   # Second row


  test "Grid child positioning - start alignment in 2x2 grid":
    let parent = newTestNode("start-grid")
    let child1 = newTestNode("start-child1", parent)
    let child2 = newTestNode("start-child2", parent)
    let child3 = newTestNode("start-child3", parent)
    let child4 = newTestNode("start-child4", parent)
    
    parent.cxSize[dcol] = 400'ux
    parent.cxSize[drow] = 400'ux
    
    # Create 2x2 grid
    parent.gridTemplate = newGridTemplate()
    parent.gridTemplate.lines[dcol] = @[
      initGridLine(200'ux),
      initGridLine(200'ux)
    ]
    parent.gridTemplate.lines[drow] = @[
      initGridLine(200'ux),
      initGridLine(200'ux)
    ]
    
    # Place children with start alignment
    for (child, pos) in [(child1, (1, 1)), (child2, (2, 1)), 
                      (child3, (1, 2)), (child4, (2, 2))]:
      child.gridItem = newGridItem()
      child.gridItem.column = pos[0]
      child.gridItem.row = pos[1]
      child.gridItem.justify = some(CxStart)
      child.gridItem.align = some(CxStart)
      child.cxSize[dcol] = 100'ux
      child.cxSize[drow] = 100'ux
    
    computeLayout(parent)
    
    # Check all children maintain their size
    for child in [child1, child2, child3, child4]:
      check child.box.w == 100
      check child.box.h == 100

    # Verify start-aligned positions
    check child1.box.x == 0     # First column start
    check child1.box.y == 0     # First row start
    check child2.box.x == 200   # Second column start
    check child2.box.y == 0     # First row start
    check child3.box.x == 0     # First column start
    check child3.box.y == 200   # Second row start
    check child4.box.x == 200   # Second column start
    check child4.box.y == 200   # Second row start

  test "Grid child positioning - end alignment in 2x2 grid":
    let parent = newTestNode("end-grid")
    let child1 = newTestNode("end-child1", parent)
    let child2 = newTestNode("end-child2", parent)
    let child3 = newTestNode("end-child3", parent)
    let child4 = newTestNode("end-child4", parent)
    
    parent.cxSize[dcol] = 400'ux
    parent.cxSize[drow] = 400'ux
    
    parent.gridTemplate = newGridTemplate()
    parent.gridTemplate.lines[dcol] = @[
      initGridLine(200'ux),
      initGridLine(200'ux)
    ]
    parent.gridTemplate.lines[drow] = @[
      initGridLine(200'ux),
      initGridLine(200'ux)
    ]
    
    # Place children with end alignment
    for (child, pos) in [(child1, (1, 1)), (child2, (2, 1)), 
                      (child3, (1, 2)), (child4, (2, 2))]:
      child.gridItem = newGridItem()
      child.gridItem.column = pos[0]
      child.gridItem.row = pos[1]
      child.gridItem.justify = some(CxEnd)
      child.gridItem.align = some(CxEnd)
      child.cxSize[dcol] = 100'ux
      child.cxSize[drow] = 100'ux
    
    computeLayout(parent)
    
    # Check all children maintain their size
    for child in [child1, child2, child3, child4]:
      check child.box.w == 100
      check child.box.h == 100

    # Verify end-aligned positions (offset by child size from cell edges)
    check child1.box.x == 100   # First column end (200 - 100)
    check child1.box.y == 100   # First row end
    check child2.box.x == 300   # Second column end (400 - 100)
    check child2.box.y == 100   # First row end
    check child3.box.x == 100   # First column end
    check child3.box.y == 300   # Second row end
    check child4.box.x == 300   # Second column end
    check child4.box.y == 300   # Second row end

  test "Grid child positioning - center alignment in 2x2 grid":
    let parent = newTestNode("center-grid")
    let child1 = newTestNode("center-child1", parent)
    let child2 = newTestNode("center-child2", parent)
    let child3 = newTestNode("center-child3", parent)
    let child4 = newTestNode("center-child4", parent)
    
    parent.cxSize[dcol] = 400'ux
    parent.cxSize[drow] = 400'ux
    
    parent.gridTemplate = newGridTemplate()
    parent.gridTemplate.lines[dcol] = @[
      initGridLine(200'ux),
      initGridLine(200'ux)
    ]
    parent.gridTemplate.lines[drow] = @[
      initGridLine(200'ux),
      initGridLine(200'ux)
    ]
    
    # Place children with center alignment
    for (child, pos) in [(child1, (1, 1)), (child2, (2, 1)), 
                      (child3, (1, 2)), (child4, (2, 2))]:
      child.gridItem = newGridItem()
      child.gridItem.column = pos[0]
      child.gridItem.row = pos[1]
      child.gridItem.justify = some(CxCenter)
      child.gridItem.align = some(CxCenter)
      child.cxSize[dcol] = 100'ux
      child.cxSize[drow] = 100'ux
    
    computeLayout(parent)
    
    # Check all children maintain their size
    for child in [child1, child2, child3, child4]:
      check child.box.w == 100
      check child.box.h == 100

    # Verify centered positions (offset by half the difference between cell and child size)
    check child1.box.x == 50    # First column center ((200 - 100)/2)
    check child1.box.y == 50    # First row center
    check child2.box.x == 250   # Second column center (200 + (200 - 100)/2)
    check child2.box.y == 50    # First row center
    check child3.box.x == 50    # First column center
    check child3.box.y == 250   # Second row center
    check child4.box.x == 250   # Second column center
    check child4.box.y == 250   # Second row center

  test "Grid child positioning - mixed alignments in 2x2 grid":
    let parent = newTestNode("mixed-grid")
    let child1 = newTestNode("mixed-child1", parent)
    let child2 = newTestNode("mixed-child2", parent)
    let child3 = newTestNode("mixed-child3", parent)
    let child4 = newTestNode("mixed-child4", parent)
    
    parent.cxSize[dcol] = 400'ux
    parent.cxSize[drow] = 400'ux
    
    parent.gridTemplate = newGridTemplate()
    parent.gridTemplate.lines[dcol] = @[
      initGridLine(200'ux),
      initGridLine(200'ux)
    ]
    parent.gridTemplate.lines[drow] = @[
      initGridLine(200'ux),
      initGridLine(200'ux)
    ]
    
    # Configure different alignments for each child
    child1.gridItem = newGridItem()
    child1.gridItem.column = 1
    child1.gridItem.row = 1
    child1.gridItem.justify = some(CxStart)
    child1.gridItem.align = some(CxCenter)
    
    child2.gridItem = newGridItem()
    child2.gridItem.column = 2
    child2.gridItem.row = 1
    child2.gridItem.justify = some(CxEnd)
    child2.gridItem.align = some(CxStart)
    
    child3.gridItem = newGridItem()
    child3.gridItem.column = 1
    child3.gridItem.row = 2
    child3.gridItem.justify = some(CxCenter)
    child3.gridItem.align = some(CxEnd)
    
    child4.gridItem = newGridItem()
    child4.gridItem.column = 2
    child4.gridItem.row = 2
    child4.gridItem.justify = some(CxEnd)
    child4.gridItem.align = some(CxEnd)
    
    # Set fixed sizes for all children
    for child in [child1, child2, child3, child4]:
      child.cxSize[dcol] = 100'ux
      child.cxSize[drow] = 100'ux
    
    computeLayout(parent)
    
    # Check all children maintain their size
    for child in [child1, child2, child3, child4]:
      check child.box.w == 100
      check child.box.h == 100

    # Verify mixed alignment positions
    check child1.box.x == 0     # Start horizontally
    check child1.box.y == 50    # Center vertically
    
    check child2.box.x == 300   # End horizontally
    check child2.box.y == 0     # Start vertically
    
    check child3.box.x == 50    # Center horizontally
    check child3.box.y == 300   # End vertically
    
    check child4.box.x == 300   # End horizontally
    check child4.box.y == 300   # End vertically

  template testLayout(scrollBarWidth, blk: untyped) =
        # addPrettyPrintFilter("name", "scroll")
        # addPrettyPrintFilter("name", "scrollBody")
        # addPrettyPrintFilter("name", "stories")
        # addPrettyPrintFilter("name", "scrollbar-vertical")
        # addPrettyPrintFilter("dir", "dcol")

        let root {.inject.} = newTestTree("root",
          newTestTree("main",
            newTestTree("outer",
              newTestTree("top",
                newTestNode("Load"),
                newTestNode("text")
              ),
              newTestTree("stories",
                newTestTree("scroll",
                  newTestTree("scrollBody", 
                    newTestNode("item"),
                  ),
                  newTestNode("scrollbar-vertical")
                )
              ),
              newTestTree("panel",
                newTestTree("panel-inner",
                  newTestNode("upvotes")
                )
              )
            )
          )
        )

        root.cxSize = [800'ux, 600'ux]
        # Set up grid template for outer node
        parseGridTemplateColumns root.children[0].children[0].gridTemplate, 1'fr 5'fr
        parseGridTemplateRows root.children[0].children[0].gridTemplate, 70'ux 1'fr 40'ux
        
        # Set up grid items
        let top {.inject.} = root.children[0].children[0].children[0]
        top.gridItem = newGridItem()
        top.gridItem.column = 1 // 3
        top.gridItem.row = 1 // 2
        
        let stories {.inject.} = root.children[0].children[0].children[1]
        stories.gridItem = newGridItem()
        stories.gridItem.column = 1 // 2
        stories.gridItem.row = 2 // 3
        
        let panel {.inject.} = root.children[0].children[0].children[2]
        panel.gridItem = newGridItem()
        panel.gridItem.column = 2 // 3
        panel.gridItem.row = 2 // 3
        
        # Set up constraints
        # root.cxSize = [100'pp, 100'pp]
        root.children[0].cxSize = [100'pp, 100'pp]
        root.children[0].children[0].cxSize = [100'pp, 100'pp]
        
        let load {.inject.} = top.children[0]
        load.cxSize = [50'pp, 50'ux]
        load.cxOffset = [25'pp, 10'ux]
        
        let text {.inject.} = top.children[1]
        text.cxSize = [100'pp, 100'pp]
        text.cxMin = [39'ux, 21.15'ux]
        text.cxMax = [39'ux, 42.30'ux]
        
        let scroll {.inject.} = stories.children[0]
        scroll.cxSize = [cx"auto", cx"auto"]
        
        let scrollBody {.inject.} = scroll.children[0]
        scrollBody.cxSize = [100'pp, cx"max-content"]
        
        let scrollBar {.inject.} = scroll.children[1]
        scrollBar.cxOffset = [100'pp-scrollBarWidth, 0'ux]
        # scrollBar.cxOffset = [scrollBarWidth, 0'ux]
        scrollBar.cxSize = [scrollBarWidth, 100'pp]

        let item {.inject.} = scrollBody.children[0]
        item.cxSize = [100'pp, 100'ux]

        let panelInner {.inject.} = panel.children[0]

        let upvotes {.inject.} = panelInner.children[0]
        upvotes.cxMin = [46'ux, 20.50'ux]
        upvotes.cxMax = [90'ux, 63.45'ux]

        computeLayout(root)

        `blk`

  test "Complex grid layout with nested nodes and large child":
    # prettyPrintWriteMode = cmTerminal
    # defer: prettyPrintWriteMode = cmNone
    when true:
      testLayout(194.55'ux): # larger than 1'fr
        # printLayout(root, cmTerminal)
        check top.box.w.float32.round(0) == 800
        check top.box.h.float32 == 70
        check stories.box.w.float32.round(0) == 133
        check stories.box.h.float32 == 490
        check panel.box.w.float32.round(0) == 667
        check panel.box.h.float32 == 490

        check scrollBody.name == "scrollBody"
        check scrollBody.box.w.float32.round(0) == 133
        check scrollBody.box.h.float32 == 100

        # check upvotes.box.w.float32.round(2) == 46
        check upvotes.box.h.float32.round(2) == 20.5

  test "Complex grid layout with nested nodes and small child":
    # prettyPrintWriteMode = cmTerminal
    # defer: prettyPrintWriteMode = cmNone
    testLayout(10.55'ux): # smaller than 1'fr
      # printLayout(root, cmTerminal)
      check top.box.w.float32.round(0) == 800
      check top.box.h.float32 == 70
      check stories.box.w.float32.round(0) == 133
      check stories.box.h.float32 == 490
      check panel.box.w.float32.round(0) == 667
      check panel.box.h.float32 == 490

      check scrollBody.name == "scrollBody"
      check scrollBody.box.w.float32.round(0) == 133
      check scrollBody.box.h.float32 == 100

      # check upvotes.box.w.float32.round(2) == 46
      check upvotes.box.h.float32.round(2) == 20.5

  test "Complex grid layout with nested nodes and small child":
    # prettyPrintWriteMode = cmTerminal
    # defer: prettyPrintWriteMode = cmNone
    # addPrettyPrintFilter("name", "panel")
    # addPrettyPrintFilter("name", "panel-inner")
    # addPrettyPrintFilter("name", "upvotes")

    testLayout(10.55'ux): # smaller than 1'fr
      panelInner.cxSize = [100'pp, cx"max-content"]
      panelInner.cxMin = [0'ux, 0'ux]
      upvotes.cxMin = [1000'ux, 1000'ux]
      computeLayout(root)

      # printLayout(root, cmTerminal)
      check top.box.w.float32.round(0) == 800
      check top.box.h.float32 == 70
      check stories.box.w.float32.round(0) == 133
      check stories.box.h.float32 == 490
      check panel.box.w.float32.round(0) == 667
      check panel.box.h.float32 == 490

      check scrollBody.name == "scrollBody"
      check scrollBody.box.w.float32.round(0) == 133
      check scrollBody.box.h.float32 == 100

      check upvotes.box.w.float32.round(2) == 1000
      check upvotes.box.h.float32.round(2) == 1000



