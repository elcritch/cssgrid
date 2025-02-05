import unittest
import typetraits
import sequtils

import unittest
import cssgrid/numberTypes
import cssgrid/gridtypes
import cssgrid/basiclayout
import cssgrid/layout
import cssgrid/parser
import cssgrid/layout
import cssgrid/prettyprints

import pretty

type
  TestNode = ref object
    box: UiBox
    name*: string
    parent*: TestNode
    children*: seq[TestNode]
    cxSize*: array[GridDir, Constraint] = [csAuto(), csNone()]  # For width/height
    cxOffset*: array[GridDir, Constraint] # For x/y positions
    gridItem*: GridItem
    gridTemplate*: GridTemplate
    frame*: Frame

  Frame = ref object
    windowSize*: UiBox

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

suite "Basic CSS Layout Tests":
  test "Fixed size constraints":
    let node = newTestNode("test", 0, 0, 100, 100)
    node.cxSize[dcol] = csFixed(200)
    node.cxSize[drow] = csFixed(150)
    
    calcBasicConstraint(node, dcol, isXY = false)
    calcBasicConstraint(node, drow, isXY = false)
    
    check node.box.w == 200
    check node.box.h == 150

  test "Percentage constraints":
    let parent = newTestNode("parent", 0, 0, 400, 300)
    let child = newTestNode("child", 0, 0, 100, 100)
    child.parent = parent
    parent.children.add(child)
    
    child.cxSize[dcol] = csPerc(50) # 50% of parent width
    child.cxSize[drow] = csPerc(25) # 25% of parent height
    
    calcBasicConstraint(child, dcol, isXY = false)
    calcBasicConstraint(child, drow, isXY = false)
    
    check child.box.w == 200 # 50% of 400
    check child.box.h == 75  # 25% of 300

  test "Auto constraints":
    let parent = newTestNode("parent", 0, 0, 400, 300)
    let child = newTestNode("child", 10, 10, 100, 100)
    child.parent = parent
    parent.children.add(child)
    
    child.cxSize[dcol] = csAuto()
    child.cxSize[drow] = csAuto()
    
    calcBasicConstraint(child, dcol, isXY = false)
    calcBasicConstraint(child, drow, isXY = false)
    
    # Auto should fill available space (parent size - offset)
    check child.box.w == 390 # 400 - 10
    check child.box.h == 290 # 300 - 10

  test "Min/Max constraints":
    let node = newTestNode("test", 0, 0, 100, 100)
    
    # Test min constraint
    node.cxSize[dcol] = csMin(csFixed(150), csFixed(200))
    calcBasicConstraint(node, dcol, isXY = false)
    check node.box.w == 150
    
    # Test max constraint
    node.cxSize[drow] = csMax(csFixed(150), csFixed(200))
    calcBasicConstraint(node, drow, isXY = false)
    check node.box.h == 200

  test "Complex nested constraints":
    let parent = newTestNode("parent", 0, 0, 400, 300)
    let child1 = newTestNode("child1", 10, 10, 100, 100)
    let child2 = newTestNode("child2", 10, 120, 100, 100)
    
    parent.children = @[child1, child2]
    child1.parent = parent
    child2.parent = parent
    
    # Child1: 50% of parent width, min 100px
    child1.cxSize[dcol] = csMax(csPerc(50), csFixed(100))
    
    # Child2: 25% of parent width + 50px
    child2.cxSize[dcol] = csSum(csPerc(25), csFixed(50))
    
    calcBasicConstraint(child1, dcol, isXY = false)
    calcBasicConstraint(child2, dcol, isXY = false)
    
    check child1.box.w == 200 # max(50% of 400, 100)
    check child2.box.w == 150 # (25% of 400) + 50

  test "Content based constraints":
    let parent = newTestNode("parent", 0, 0, 400, 300)
    let child = newTestNode("child", 0, 0, 100, 100)
    let grandchild = newTestNode("grandchild", 0, 0, 150, 80)
    
    parent.children.add(child)
    child.parent = parent
    child.children.add(grandchild)
    grandchild.parent = child
    
    # Set child width to fit content
    child.cxSize[dcol] = csContentMax()
    # calcBasicConstraint(child, dcol, isXY = false)
    computeLayout(parent, 0)
    
    echo "BOX: ", parent.cxOffset.repr
    echo "BOX: ", parent.cxSize.repr
    printLayout(parent, cmTerminal)

    check child.box.w >= grandchild.box.w # Should be at least as wide as content

  test "Position constraints":
    let parent = newTestNode("parent", 0, 0, 400, 300)
    let child = newTestNode("child", 0, 0, 100, 100)
    
    parent.children.add(child)
    child.parent = parent
    
    # Position 20px from left, 10% from top
    child.cxOffset[dcol] = csFixed(20)
    child.cxOffset[drow] = csPerc(10)
    
    calcBasicConstraint(child, dcol, isXY = true)
    calcBasicConstraint(child, drow, isXY = true)
    
    check child.box.x == 20
    check child.box.y == 30 # 10% of 300


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

  test "Grid alignment and justification":
    when false:
      let parent = newTestNode("aligned-grid", 0, 0, 400, 300)
      let child = newTestNode("aligned-child", 0, 0, 50, 50)
      
      parent.addChild(child)
      
      parent.gridTemplate = newGridTemplate()
      parent.gridTemplate.lines[dcol] = @[
        initGridLine(csFixed(100))  # Fixed width column
      ]
      parent.gridTemplate.lines[drow] = @[
        initGridLine(csFixed(100))  # Fixed height row
      ]
      
      child.gridItem = newGridItem()
      child.gridItem.column = 1
      child.gridItem.row = 1
      child.gridItem.justify = some(CxCenter)  # Center horizontally
      child.gridItem.align = some(CxCenter)    # Center vertically
      
      computeLayout(parent, 0)
      
      # printLayout(parent)

      # Child should be centered in its 100x100 grid cell
      check child.box.x == 25  # (100 - 50) / 2
      check child.box.y == 25  # (100 - 50) / 2

  test "Post-process auto sizing with grid":
    let parent = newTestNode("parent", 0, 0, 400, 300)
    let child = newTestNode("child", 50, 50, 200, 150)
    parent.addChild(child)
    
    parent.cxOffset = [csFixed(400), csFixed(300)]

    # Setup grid
    parent.gridTemplate = newGridTemplate()
    child.cxSize = [csAuto(), csAuto()]
    
    # Initial layout
    calcBasicConstraint(child, dcol, isXY = false)
    calcBasicConstraint(child, drow, isXY = false)
    
    # Post processing should preserve grid sizes
    calcBasicConstraintPost(child, dcol, isXY = false)
    calcBasicConstraintPost(child, drow, isXY = false)

    check child.box.x == 50
    check child.box.y == 50
    check child.box.w == 350
    check child.box.h == 250

  # test "Post-process MinMax constraints":
  #   let parent = newTestNode("parent", 0, 0, 400, 300)
  #   let child = newTestNode("child", 50, 50, 200, 150)
  #   parent.addChild(child)
  #   # Setup grid
  #   parent.gridTemplate = newGridTemplate()
  #   child.cxSize = [csAuto(), csAuto()]
  #   parent.cxOffset = [csFixed(400), csFixed(300)]
  #   # Set min/max constraints
  #   child.cxSize[dcol] = csMinMax(csFixed(100), csFixed(250))
  #   # Initial layout might set a size outside bounds
  #   child.box.w = 400  # Intentionally set larger than max
  #   # Post processing should clamp to max
  #   prettyPrintWriteMode = cmTerminal
  #   computeLayout(parent, 0)
  #   printLayout(parent, cmTerminal)
  #   check child.box.w == 250
  #   # Test min bound
  #   child.box.w = 50  # Intentionally set smaller than min
  #   calcBasicConstraintPost(child, dcol, isXY = false)
  #   check child.box.w == 100

  # test "Post-process fractional sizing":
  #   let parent = newTestNode("parent", 0, 0, 400, 300)
  #   let child = newTestNode("child", 100, 100, 200, 150)
  #   parent.addChild(child)
  #   child.cxSize[dcol] = csFrac(0.5)  # 50% of remaining space
  #   # Post processing should consider remaining space
  #   calcBasicConstraintPost(child, dcol, isXY = false)
  #   check child.box.w == 150  # (400 - 100) * 0.5

  # test "Post-process content-based sizing":
  #   let parent = newTestNode("parent", 0, 0, 400, 300)
  #   let child = newTestNode("child", 0, 0, 200, 150)
  #   parent.addChild(child)
  #   child.cxSize[dcol] = csContentMax()
  #   child.box.w = 250  # Set by previous layout pass
  #   # Post processing should preserve content-based size
  #   calcBasicConstraintPost(child, dcol, isXY = false)
  #   check child.box.w == 250

  # test "Post-process nested constraints":
  #   let parent = newTestNode("parent", 0, 0, 400, 300)
  #   let child1 = newTestNode("child1", 50, 50, 200, 150)
  #   let child2 = newTestNode("child2", 0, 0, 100, 100)
  #   parent.addChild(child1)
  #   child1.addChild(child2)
  #   # Setup complex constraints
  #   child1.cxSize[dcol] = csSum(csFixed(100), csPerc(25))
  #   child2.cxSize[dcol] = csPerc(50)  # 50% of child1
  #   # Post process parent first
  #   calcBasicConstraintPost(child1, dcol, isXY = false)
  #   check child1.box.w == 200  # 100 + (400 * 0.25)
  #   # Then post process child
  #   calcBasicConstraintPost(child2, dcol, isXY = false)
  #   check child2.box.w == 100  # 50% of child1's 200

