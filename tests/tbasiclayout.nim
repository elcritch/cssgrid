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
    cxMin*: array[GridDir, Constraint] = [csContentMin(), csContentMin()] # For x/y positions
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
    box: uiBox(0, 0, 0, 0),
    cxOffset: [csFixed(x), csFixed(y)],
    cxSize: [csFixed(w), csFixed(h)],
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
    
    calcBasicConstraint(node)
    
    check node.box.w == 200
    check node.box.h == 150

  test "Percentage constraints":
    let parent = newTestNode("parent", 0, 0, 400, 300)
    let child = newTestNode("child", 0, 0, 100, 100)
    child.parent = parent
    parent.children.add(child)
    
    child.cxSize[dcol] = csPerc(50) # 50% of parent width
    child.cxSize[drow] = csPerc(25) # 25% of parent height
    
    computeLayout(parent)
    # calcBasicConstraint(child, dcol, isXY = false)
    # calcBasicConstraint(child, drow, isXY = false)
    
    # prettyLayout(parent, mode=cmTerminal)
    check child.box.w == 200 # 50% of 400
    check child.box.h == 75  # 25% of 300

  test "Auto constraints":
    let parent = newTestNode("parent", 0, 0, 400, 300)
    let child = newTestNode("child", 10, 10, 100, 100)
    child.parent = parent
    parent.children.add(child)
    
    child.cxSize[dcol] = csAuto()
    child.cxSize[drow] = csAuto()
    
    computeLayout(parent)
    
    # Auto should fill available space (parent size - offset)
    check child.box.w == 390 # 400 - 10
    check child.box.h == 290 # 300 - 10

  test "Min/Max constraints":
    let node = newTestNode("test", 0, 0, 100, 100)
    
    # Test min constraint
    node.cxSize[dcol] = csMin(csFixed(150), csFixed(200))
    calcBasicConstraint(node)
    check node.box.w == 150
    
    # Test max constraint
    node.cxSize[drow] = csMax(csFixed(150), csFixed(200))
    calcBasicConstraint(node)
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
    child2.cxSize[dcol] = csAdd(csPerc(25), csFixed(50))
    
    computeLayout(parent)
    # calcBasicConstraint(child1, dcol, isXY = false)
    # calcBasicConstraint(child2, dcol, isXY = false)
    
    check child1.box.w == 200 # max(50% of 400, 100)
    check child2.box.w == 150 # (25% of 400) + 50

  test "Content based constraints":
    let parent = newTestNode("parent", 0, 0, 400, 300)
    let child = newTestNode("child", 0, 0, 100, 100)
    let grandchild = newTestNode("grandchild", 0, 0, 150, 80)
    
    grandchild.cxMin = [100'ux, 40'ux]

    parent.children.add(child)
    child.parent = parent
    child.children.add(grandchild)
    grandchild.parent = child
    
    # Set child width to fit content
    child.cxSize[dcol] = csContentMin()
    child.cxSize[drow] = csContentMin()
    # calcBasicConstraint(child, dcol, isXY = false)
    computeLayout(parent)
    
    echo "BOX: ", parent.cxOffset.repr
    echo "BOX: ", parent.cxSize.repr
    printLayout(parent, cmTerminal)

    check grandchild.bmin == uiSize(100, 40)
    check child.box.w == grandchild.bmin.w # 
    check child.box.h == grandchild.bmin.h # 
    check child.bmin == uiSize(100, 40)

  test "Position constraints":
    let parent = newTestNode("parent", 0, 0, 400, 300)
    let child = newTestNode("child", 0, 0, 100, 100)
    
    parent.children.add(child)
    child.parent = parent
    
    # Position 20px from left, 10% from top
    child.cxOffset[dcol] = csFixed(20)
    child.cxOffset[drow] = csPerc(10)
    
    calcBasicConstraint(child)
    calcBasicConstraint(child)
    
    check child.box.x == 20
    check child.box.y == 30 # 10% of 300

  test "Post-process auto sizing with grid":
    let parent = newTestNode("parent", 0, 0, 400, 300)
    let child = newTestNode("child", 50, 50, 200, 150)
    parent.addChild(child)
    
    parent.cxOffset = [csFixed(400), csFixed(300)]

    # Setup grid
    # parent.gridTemplate = newGridTemplate()
    child.cxSize = [csAuto(), csAuto()]
    
    computeLayout(parent)
    # # Initial layout
    # calcBasicConstraint(child, dcol, isXY = false)
    # calcBasicConstraint(child, drow, isXY = false)
    
    # # Post processing should preserve grid sizes
    # calcBasicConstraintPost(child, dcol, isXY = false)
    # calcBasicConstraintPost(child, drow, isXY = false)

    check child.box.x == 50
    check child.box.y == 50
    check child.box.w == 350
    check child.box.h == 250

  test "Post-process auto sizing with grid":
    let parent = newTestNode("parent", 0, 0, 400, 300)
    let child = newTestNode("child", 50, 50, 200, 150)
    parent.addChild(child)
    
    parent.cxOffset = [csFixed(400), csFixed(300)]

    # Setup grid
    parent.gridTemplate = newGridTemplate()
    child.cxSize = [csAuto(), csAuto()]
    
    computeLayout(parent)
    # # Initial layout
    # calcBasicConstraint(child, dcol, isXY = false)
    # calcBasicConstraint(child, drow, isXY = false)
    
    # # Post processing should preserve grid sizes
    # calcBasicConstraintPost(child, dcol, isXY = false)
    # calcBasicConstraintPost(child, drow, isXY = false)

    check child.box.x == 50
    check child.box.y == 50
    check child.box.w == 350
    check child.box.h == 250