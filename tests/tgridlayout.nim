
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
  TestNode = ref object
    box*: UiBox
    bmin*, bmax*: UiSize
    name*: string
    parent*: TestNode
    children*: seq[TestNode]
    cxSize*: array[GridDir, Constraint] = [csAuto(), csNone()]  # For width/height
    cxOffset*: array[GridDir, Constraint] # For x/y positions
    cxMin*: array[GridDir, Constraint] = [csNone(), csNone()] # For x/y positions
    cxMax*: array[GridDir, Constraint] = [csNone(), csNone()] # For x/y positions
    gridItem*: GridItem
    gridTemplate*: GridTemplate
    frame*: Frame

  Frame = ref object
    windowSize*: UiBox

template getParentBoxOrWindows*(node: GridNode): UiBox =
  if node.parent.isNil:
    node.frame.windowSize
  else:
    node.parent.box

proc newTestNode(name: string, x, y, w, h: float32): TestNode =
  result = TestNode(
    name: name,
    box: uiBox(x, y, w, h),
    children: @[],
    frame: Frame(windowSize: uiBox(0, 0, 800, 600))
  )

proc addChild(parent, child: TestNode) =
  parent.children.add(child)
  child.parent = parent

suite "Compute Layout Tests":
  test "Basic node without grid":
    # Test simple node with basic constraints
    let node = newTestNode("root", 0, 0, 400, 300)
    node.cxSize[dcol] = csFixed(200)
    node.cxSize[drow] = csFixed(150)
    
    computeLayout(node, 0)
    
    check node.box.w == 200
    check node.box.h == 150

  test "Parent with basic constrained children":
    let parent = newTestNode("parent", 0, 0, 400, 300)
    let child1 = newTestNode("child1", 10, 10, 100, 100)
    let child2 = newTestNode("child2", 10, 120, 100, 100)
    
    parent.addChild(child1)
    parent.addChild(child2)
    
    # Set fixed-parent constraint
    parent.cxSize[dcol] = csFixed(400)  # set fixed parent
    parent.cxSize[drow] = csFixed(300)  # set fixed parent

    # Set percentage-based constraints for children
    child1.cxSize[dcol] = csPerc(50)  # 50% of parent
    child1.cxSize[drow] = csPerc(30)  # 30% of parent
    
    child2.cxSize[dcol] = csPerc(70)  # 70% of parent
    child2.cxSize[drow] = csPerc(40)  # 40% of parent
    
    computeLayout(parent, 0)
    
    check child1.box.w == 200  # 50% of 400
    check child1.box.h == 90   # 30% of 300
    check child2.box.w == 280  # 70% of 400
    check child2.box.h == 120  # 40% of 300

  test "Simple grid layout":
    when false:
      prettyPrintWriteMode = cmTerminal
      defer: prettyPrintWriteMode = cmNone
      let parent = newTestNode("grid-parent", 0, 0, 400, 300)
      let child1 = newTestNode("grid-child1", 0, 0, 100, 100)
      let child2 = newTestNode("grid-child2", 0, 0, 100, 100)
      
      parent.addChild(child1)
      parent.addChild(child2)
      
      # Setup grid template
      parent.cxSize[dcol] = csFixed(400)  # set fixed parent
      parent.cxSize[drow] = csFixed(300)  # set fixed parent

      # child1.cxSize[dcol] = csFixed(100)  # set fixed parent
      # child1.cxSize[drow] = csFixed(100)  # set fixed parent
      # child2.cxSize[dcol] = csFixed(100)  # set fixed parent
      # child2.cxSize[drow] = csFixed(100)  # set fixed parent

      parent.gridTemplate = newGridTemplate()
      parent.gridTemplate.lines[dcol] = @[
        initGridLine(csFrac(1)),
        initGridLine(csFrac(1))
      ]
      parent.gridTemplate.lines[drow] = @[
        initGridLine(csFixed(100))
      ]
      
      # Setup grid items
      child1.gridItem = newGridItem()
      child1.gridItem.column = 1
      child1.gridItem.row = 1
      
      child2.gridItem = newGridItem()
      child2.gridItem.column = 2
      child2.gridItem.row = 1
      
      computeLayout(parent, 0)
      
      # Children should each take up half the width
      check child1.box.w == 200  # Half of parent width
      check child2.box.w == 200  # Half of parent width
      check child1.box.h == 100  # Fixed height from grid
      check child2.box.h == 100  # Fixed height from grid

  test "Grid with mixed units":
    when false:

      let parent = newTestNode("mixed-grid", 0, 0, 400, 300)
      let child1 = newTestNode("fixed-child", 0, 0, 100, 100)
      let child2 = newTestNode("frac-child", 0, 0, 100, 100)
      let child21 = newTestNode("frac-grandchild", 0, 0, 50, 50)
      let child3 = newTestNode("auto-child", 0, 0, 100, 100)
      let child31 = newTestNode("auto-grandchild", 0, 0, 50, 50)
      
      parent.addChild(child1)
      parent.addChild(child2)
      child2.addChild(child21)
      parent.addChild(child3)
      child3.addChild(child31)
      
      # Setup grid with fixed, fractional and auto tracks
      parent.cxSize[dcol] = csFixed(400)  # set fixed parent
      parent.cxSize[drow] = csFixed(300)  # set fixed parent

      child21.cxSize[dcol] = csFixed(50)  # set fixed parent
      child21.cxSize[drow] = csFixed(50)  # set fixed parent
      child31.cxSize[dcol] = csFixed(50)  # set fixed parent
      child31.cxSize[drow] = csFixed(50)  # set fixed parent

      parent.gridTemplate = newGridTemplate()
      parent.gridTemplate.lines[dcol] = @[
        initGridLine(csFixed(100)),  # Fixed width column
        initGridLine(csFrac(1)),     # Fractional column
        initGridLine(csAuto())       # Auto column
      ]
      parent.gridTemplate.lines[drow] = @[
        initGridLine(csFixed(100))   # Single row
      ]
      
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
      # child3.box.w = 100  # This should be respected as minimum width
      computeLayout(parent, 0)
      
      check child1.box.w == 100  # Fixed width
      check child2.box.w > 100   # Should get remaining space
      check child3.box.w > 0     # Should get minimum required space

  test "Grid with content sizing":
    when false:
      let parent = newTestNode("content-grid", 0, 0, 400, 300)
      let child1 = newTestNode("content-child1", 0, 0, 150, 100)
      let child2 = newTestNode("content-child2", 0, 0, 100, 100)
      
      parent.addChild(child1)
      parent.addChild(child2)
      
      parent.gridTemplate = newGridTemplate()
      parent.gridTemplate.lines[dcol] = @[
        initGridLine(csContentMax()),  # Size to max content
        initGridLine(csContentMin())   # Size to min content
      ]
      parent.gridTemplate.lines[drow] = @[
        initGridLine(csFixed(100))
      ]
      
      child1.gridItem = newGridItem()
      child1.gridItem.column = 1
      child1.gridItem.row = 1
      
      child2.gridItem = newGridItem()
      child2.gridItem.column = 2
      child2.gridItem.row = 1
      
      computeLayout(parent, 0)
      
      check child1.box.w >= 150  # Should accommodate content
      check child2.box.w >= 100  # Should accommodate content

  test "Grid with nested basic constraints":
    when false:
      let parent = newTestNode("nested-grid", 0, 0, 400, 300)
      let gridChild = newTestNode("grid-child", 0, 0, 200, 200)
      let innerChild = newTestNode("inner-child", 0, 0, 100, 100)
      
      parent.addChild(gridChild)
      gridChild.addChild(innerChild)
      
      # Setup grid
      parent.gridTemplate = newGridTemplate()
      parent.gridTemplate.lines[dcol] = @[
        initGridLine(csFrac(1))
      ]
      parent.gridTemplate.lines[drow] = @[
        initGridLine(csFrac(1))
      ]
      
      # Grid placement
      gridChild.gridItem = newGridItem()
      gridChild.gridItem.column = 1
      gridChild.gridItem.row = 1
      
      # Setup parent fixed size
      parent.cxSize[dcol] = csFixed(400)  # set fixed parent
      parent.cxSize[drow] = csFixed(300)  # set fixed parent

      # Inner child with percentage constraint
      innerChild.cxSize[dcol] = csPerc(50)
      innerChild.cxSize[drow] = csPerc(50)
      
      computeLayout(parent, 0)
      
      check innerChild.box.w == 200  # 50% of grid child width
      check innerChild.box.h == 150  # 50% of grid child height

  test "Auto flow grid":
    when false:
      let parent = newTestNode("autoflow-grid", 0, 0, 400, 300)
      var children: seq[TestNode]
      
      # Setup grid template
      parent.cxSize[dcol] = csFixed(400)  # set fixed parent
      parent.cxSize[drow] = csFixed(300)  # set fixed parent

      # Create 4 children
      for i in 1..4:
        let child = newTestNode("child" & $i, 0, 0, 100, 100)
        children.add(child)
        parent.addChild(child)
      
      # Setup grid with 2 columns
      parent.gridTemplate = newGridTemplate()
      parent.gridTemplate.lines[dcol] = @[
        initGridLine(csFrac(1)),
        initGridLine(csFrac(1))
      ]
      parent.gridTemplate.autoFlow = grRow
      parent.gridTemplate.autos[drow] = cx"auto"
      
      # Don't set explicit grid positions - let autoflow handle it
      for child in children:
        child.gridItem = newGridItem()
      
      computeLayout(parent, 0)

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
    let child1 = newTestNode("stretch-child1", 0, 0, 50, 50)
    let child2 = newTestNode("stretch-child2", 0, 0, 50, 50)
    let child3 = newTestNode("stretch-child3", 0, 0, 50, 50)
    let child4 = newTestNode("stretch-child4", 0, 0, 50, 50)
    
    parent.addChild(child1)
    parent.addChild(child2)
    parent.addChild(child3)
    parent.addChild(child4)
    
    # Set up fixed parent size
    parent.cxSize[dcol] = 400'ux
    parent.cxSize[drow] = 400'ux
    
    # Create 2x2 grid with equal cells
    parent.gridTemplate = newGridTemplate()
    var gt = newGridTemplate(
      columns = @[
        initGridLine(200'ux),
        initGridLine(200'ux)
      ],
      rows = @[
        initGridLine(200'ux),
        initGridLine(200'ux)
      ],
    )
    # parent.gridTemplate.lines[dcol] = @[
    #   initGridLine(csFixed(200)),  # First column
    #   initGridLine(csFixed(200))   # Second column
    # ]
    # parent.gridTemplate.lines[drow] = @[
    #   initGridLine(csFixed(200)),  # First row
    #   initGridLine(csFixed(200))   # Second row
    # ]
    
    # Place children in grid with stretch behavior (default)
    for (child, pos) in [(child1, (1, 1)), (child2, (2, 1)), 
                      (child3, (1, 2)), (child4, (2, 2))]:
      child.gridItem = newGridItem()
      child.gridItem.column = pos[0]
      child.gridItem.row = pos[1]
    
    #   child1.gridItem = newGridItem()
    #   child1.gridItem.column = 1
    #   child1.gridItem.row = 1
      
    computeLayout(parent)
    
    printLayout(parent, cmTerminal)
    # # Check all children stretch to their cell size
    # for child in [child1, child2, child3, child4]:
    #   check child.box.w == 200  # Should stretch to column width
    #   check child.box.h == 200  # Should stretch to row height

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
    let child1 = newTestNode("start-child1", 0, 0, 100, 100)
    let child2 = newTestNode("start-child2", 0, 0, 100, 100)
    let child3 = newTestNode("start-child3", 0, 0, 100, 100)
    let child4 = newTestNode("start-child4", 0, 0, 100, 100)
    
    parent.addChild(child1)
    parent.addChild(child2)
    parent.addChild(child3)
    parent.addChild(child4)
    
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
      child.cxSize[dcol] = csFixed(100)
      child.cxSize[drow] = csFixed(100)
    
    computeLayout(parent, 0)
    
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
    let child1 = newTestNode("end-child1", 0, 0, 100, 100)
    let child2 = newTestNode("end-child2", 0, 0, 100, 100)
    let child3 = newTestNode("end-child3", 0, 0, 100, 100)
    let child4 = newTestNode("end-child4", 0, 0, 100, 100)
    
    parent.addChild(child1)
    parent.addChild(child2)
    parent.addChild(child3)
    parent.addChild(child4)
    
    parent.cxSize[dcol] = csFixed(400)
    parent.cxSize[drow] = csFixed(400)
    
    parent.gridTemplate = newGridTemplate()
    parent.gridTemplate.lines[dcol] = @[
      initGridLine(csFixed(200)),
      initGridLine(csFixed(200))
    ]
    parent.gridTemplate.lines[drow] = @[
      initGridLine(csFixed(200)),
      initGridLine(csFixed(200))
    ]
    
    # Place children with end alignment
    for (child, pos) in [(child1, (1, 1)), (child2, (2, 1)), 
                      (child3, (1, 2)), (child4, (2, 2))]:
      child.gridItem = newGridItem()
      child.gridItem.column = pos[0]
      child.gridItem.row = pos[1]
      child.gridItem.justify = some(CxEnd)
      child.gridItem.align = some(CxEnd)
      child.cxSize[dcol] = csFixed(100)
      child.cxSize[drow] = csFixed(100)
    
    computeLayout(parent, 0)
    
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
    let child1 = newTestNode("center-child1", 0, 0, 100, 100)
    let child2 = newTestNode("center-child2", 0, 0, 100, 100)
    let child3 = newTestNode("center-child3", 0, 0, 100, 100)
    let child4 = newTestNode("center-child4", 0, 0, 100, 100)
    
    parent.addChild(child1)
    parent.addChild(child2)
    parent.addChild(child3)
    parent.addChild(child4)
    
    parent.cxSize[dcol] = csFixed(400)
    parent.cxSize[drow] = csFixed(400)
    
    parent.gridTemplate = newGridTemplate()
    parent.gridTemplate.lines[dcol] = @[
      initGridLine(csFixed(200)),
      initGridLine(csFixed(200))
    ]
    parent.gridTemplate.lines[drow] = @[
      initGridLine(csFixed(200)),
      initGridLine(csFixed(200))
    ]
    
    # Place children with center alignment
    for (child, pos) in [(child1, (1, 1)), (child2, (2, 1)), 
                      (child3, (1, 2)), (child4, (2, 2))]:
      child.gridItem = newGridItem()
      child.gridItem.column = pos[0]
      child.gridItem.row = pos[1]
      child.gridItem.justify = some(CxCenter)
      child.gridItem.align = some(CxCenter)
      child.cxSize[dcol] = csFixed(100)
      child.cxSize[drow] = csFixed(100)
    
    computeLayout(parent, 0)
    
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
    let child1 = newTestNode("mixed-child1", 0, 0, 100, 100)
    let child2 = newTestNode("mixed-child2", 0, 0, 100, 100)
    let child3 = newTestNode("mixed-child3", 0, 0, 100, 100)
    let child4 = newTestNode("mixed-child4", 0, 0, 100, 100)
    
    parent.addChild(child1)
    parent.addChild(child2)
    parent.addChild(child3)
    parent.addChild(child4)
    
    parent.cxSize[dcol] = csFixed(400)
    parent.cxSize[drow] = csFixed(400)
    
    parent.gridTemplate = newGridTemplate()
    parent.gridTemplate.lines[dcol] = @[
      initGridLine(csFixed(200)),
      initGridLine(csFixed(200))
    ]
    parent.gridTemplate.lines[drow] = @[
      initGridLine(csFixed(200)),
      initGridLine(csFixed(200))
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
      child.cxSize[dcol] = csFixed(100)
      child.cxSize[drow] = csFixed(100)
    
    computeLayout(parent, 0)
    
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
