import unittest
import typetraits
import sequtils

import unittest
import cssgrid/numberTypes
import cssgrid/gridtypes
import cssgrid/basiclayout
import cssgrid/layout
import cssgrid/parser
import cssgrid/prettyprints

import pretty

type
  Box* = UiBox

import commontestutils

suite "Compute Layout Tests":
  test "Basic node without grid":
    # Test simple node with basic constraints
    let node = newTestNode("root", 0, 0, 400, 300)
    node.cxSize[dcol] = 200'ux
    node.cxSize[drow] = 150'ux
    
    computeLayout(node, 0)
    
    check node.box.w == 200
    check node.box.h == 150

  test "Parent with basic constrained children":

    let parent = newTestNode("parent") #, 0, 0, 400, 300)
    let child1 = newTestNode("child1", 10, 10, 100, 100, parent)
    let child2 = newTestNode("child2", 10, 120, 100, 100, parent)
    
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
    
    computeLayout(parent)
    
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
      # prettyPrintWriteMode = cmTerminal
      # defer: prettyPrintWriteMode = cmNone

      let parent = newTestNode("scroll", 0, 0, 400, 300)
      let body = newTestNode("scrollBody", parent)
      let items = newTestNode("items", body)

      parseGridTemplateColumns items.gridTemplate, 1'fr
      parent.cxSize = [96'pp, 90'pp]
      body.cxSize = [cx"auto", cx"max-content"]
      body.cxOffset = [cx"auto", cx"auto"]

      items.cxSize = [cx"auto", cx"auto"]
      items.gridTemplate.autoFlow = grRow
      items.gridTemplate.gaps[drow] = 3
      items.gridTemplate.autos[drow] = csAuto()
      items.gridTemplate.justifyItems = CxCenter
      items.gridTemplate.alignItems = CxCenter

      for i in 0..1:
        let child = newTestNode("story-" & $i, items)
        let text = newTestNode("text-" & $i, child)

        # child.cxSize = [1'fr, csAuto()]
        # child.cxSize = [1'fr, max(40'ux, cx"fit-content")]
        child.cxPadOffset[drow] = 21.01'ux
        child.cxPadSize[drow] = 22.20'ux

        text.cxSize = [cx"auto", 33.33'ux]
        text.cxMin = [40'ux, 20.00'ux]
        text.cxMax = [200'ux, 300.00'ux]
      
      computeLayout(parent)
      printLayout(parent, cmTerminal)

      check items.children[0].box.w == 768
      # check items.children[0].box.h == 63.21.UiScalar
      check items.children[0].box.h == 84.22.UiScalar
  
  test "vertical layout auto with grandchild":
    when true:
      # prettyPrintWriteMode = cmTerminal
      # defer: prettyPrintWriteMode = cmNone

      let parent = newTestNode("scroll", 0, 0, 400, 300)
      let items = newTestNode("items", parent)

      parent.cxSize = [400'ux, 300'ux]

      items.cxSize = [cx"auto", cx"max-content"]

      block story0:
        let story = newTestNode("story", items)
        parseGridTemplateColumns story.gridTemplate, 1'fr
        story.cxSize = [cx"auto", cx"auto"]
        story.gridTemplate.autoFlow = grRow
        story.gridTemplate.autos[drow] = csAuto()

        block rect0:
          let rect = newTestNode("rect-0", story)

          block text0:
            let text = newTestNode("text-0", rect)
            text.cxSize = [cx"auto", cx"none"]
            text.cxMin = [40'ux, 42.50'ux]
            text.cxMax = [200'ux, 300.00'ux]

        block rect1:
          let rect = newTestNode("rect-1", story)

          block text1:
            let text = newTestNode("text-1", rect)
            text.cxSize = [cx"auto", cx"none"]
            text.cxMin = [40'ux, 20.50'ux]
            text.cxMax = [200'ux, 300.00'ux]

      computeLayout(parent)
      # printLayout(parent, cmTerminal)
      check items.children[0].children[0].box.h.float32 == 42.50
      check items.children[0].children[1].box.h.float32 == 20.50
      check items.children[0].box.h.float32 == 63.00
      check items.box.h.float32 == 63.00

      check items.children[0].children[0].bmin.h.float32 == 42.50
      check items.children[0].children[1].bmin.h.float32 == 20.50
      check items.children[0].bmin.h.float32 == 63.00
      check items.bmin.h.float32 == 63.00

  test "vertical layout max-content":
    # prettyPrintWriteMode = cmTerminal
    # defer: prettyPrintWriteMode = cmNone

    let parent = newTestNode("grid-parent", 0, 0, 400, 300)
    let scrollpane = newTestNode("scrollpane", parent)
    let scrollbody = newTestNode("scrollbody", scrollpane)
    let vertical = newTestNode("vertical", scrollbody)

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
      let child = newTestNode("grid-child-" & $i, 0, 0, 100, 100, vertical)
      child.cxSize = [1'fr, 50'ux]
      if i in [3, 7]:
        child.cxSize = [0.9'fr, 120'ux]

    computeLayout(parent)
    # printLayout(parent, cmTerminal)

    check scrollpane.box.w == 384
    check scrollpane.box.h == 950
    check scrollbody.box.w == 384
    check scrollbody.box.h == 950
    check vertical.box.w == 374
    check vertical.box.h == UiScalar(50*14 + 120*2)

  test "Simple grid layout":
      let parent = newTestNode("grid-parent", 0, 0, 400, 300)
      let child1 = newTestNode("grid-child1", 0, 0, 100, 100, parent)
      let child2 = newTestNode("grid-child2", 0, 0, 100, 100, parent)
      
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
      
      # Children should each take up half the width
      check child1.box.w == 200  # Half of parent width
      check child2.box.w == 200  # Half of parent width
      check child1.box.h == 100  # Fixed height from grid
      check child2.box.h == 100  # Fixed height from grid
      check child1.box.x == 0  # Fixed height from grid
      check child2.box.x == 200  # Fixed height from grid

  test "Grid with mixed units":
    when true:
      # Create all nodes with parent-child relationships in a more concise way
      let parent = newTestTree("mixed-grid", 0, 0, 400, 300, 
        newTestNode("fixed-child", 0, 0, 100, 100),
        newTestTree("frac-child", 0, 0, 100, 100,
          newTestNode("frac-grandchild", 0, 0, 50, 50)
        ),
        newTestTree("auto-child", 0, 0, 100, 100,
          newTestNode("auto-grandchild", 0, 0, 50, 50)
        )
      )
      
      # Access child nodes by index for further configuration
      let child1 = parent.children[0]
      let child2 = parent.children[1]
      let child21 = child2.children[0]
      let child3 = parent.children[2]
      let child31 = child3.children[0]
      
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
      check child2.box.w > 100   # Should get remaining space
      check child3.box.w > 0     # Should get minimum required space

  test "Grid with content sizing":
    when true:
      let parent = newTestNode("content-grid", 0, 0, 400, 300)
      let child1 = newTestNode("content-child1", 0, 0, 150, 100, parent)
      let child2 = newTestNode("content-child2", 0, 0, 100, 100, parent)
      
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

      let parent = newTestNode("nested-grid", 0, 0, 400, 300)
      let gridChild = newTestNode("grid-child", 0, 0, 200, 200, parent)
      let innerChild = newTestNode("inner-child", gridChild)
      
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
      let parent = newTestNode("autoflow-grid", 0, 0, 400, 300)
      var children: seq[TestNode]
      
      # Setup grid template
      parent.cxSize[dcol] = 400'ux  # set fixed parent
      parent.cxSize[drow] = 300'ux  # set fixed parent

      # Create 4 children
      for i in 1..4:
        let child = newTestNode("child" & $i, 0, 0, 100, 100, parent)
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
      prettyprints.printLayout(parent)
      
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
    let parent = newTestNode("stretch-grid", 0, 0, 400, 400)
    let child1 = newTestNode("stretch-child1", 0, 0, 50, 50, parent)
    let child2 = newTestNode("stretch-child2", 0, 0, 50, 50, parent)
    let child3 = newTestNode("stretch-child3", 0, 0, 50, 50, parent)
    let child4 = newTestNode("stretch-child4", 0, 0, 50, 50, parent)
    
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
    let parent = newTestNode("start-grid", 0, 0, 400, 400)
    let child1 = newTestNode("start-child1", 0, 0, 100, 100, parent)
    let child2 = newTestNode("start-child2", 0, 0, 100, 100, parent)
    let child3 = newTestNode("start-child3", 0, 0, 100, 100, parent)
    let child4 = newTestNode("start-child4", 0, 0, 100, 100, parent)
    
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
    let parent = newTestNode("end-grid", 0, 0, 400, 400)
    let child1 = newTestNode("end-child1", 0, 0, 100, 100, parent)
    let child2 = newTestNode("end-child2", 0, 0, 100, 100, parent)
    let child3 = newTestNode("end-child3", 0, 0, 100, 100, parent)
    let child4 = newTestNode("end-child4", 0, 0, 100, 100, parent)
    
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
    let parent = newTestNode("center-grid", 0, 0, 400, 400)
    let child1 = newTestNode("center-child1", 0, 0, 100, 100, parent)
    let child2 = newTestNode("center-child2", 0, 0, 100, 100, parent)
    let child3 = newTestNode("center-child3", 0, 0, 100, 100, parent)
    let child4 = newTestNode("center-child4", 0, 0, 100, 100, parent)
    
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
    let parent = newTestNode("mixed-grid", 0, 0, 400, 400)
    let child1 = newTestNode("mixed-child1", 0, 0, 100, 100, parent)
    let child2 = newTestNode("mixed-child2", 0, 0, 100, 100, parent)
    let child3 = newTestNode("mixed-child3", 0, 0, 100, 100, parent)
    let child4 = newTestNode("mixed-child4", 0, 0, 100, 100, parent)
    
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
