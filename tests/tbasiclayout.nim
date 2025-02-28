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

import commontestutils

suite "Basic CSS Layout Tests":
  test "Fixed size constraints":
    let node = newTestNode("test", 0, 0, 100, 100)
    node.cxSize[dcol] = 200'ux
    node.cxSize[drow] = 150'ux
    
    computeLayout(node)
    check node.box.w == 200
    check node.box.h == 150

  test "Percentage constraints":
    let parent = newTestNode("parent", 0, 0, 400, 300)
    let child = newTestNode("child", 0, 0, 100, 100)
    child.parent = parent
    parent.children.add(child)
    
    child.cxSize[dcol] = 50'pp # 50% of parent width
    child.cxSize[drow] = 25'pp # 25% of parent height
    
    computeLayout(parent)
    check child.box.w == 200 # 50% of 400
    check child.box.h == 75  # 25% of 300

  test "Auto constraints":
    let parent = newTestNode("parent", 0, 0, 400, 300)
    let child = newTestNode("child", 10, 10, 100, 100)
    child.parent = parent
    parent.children.add(child)
    
    child.cxSize[dcol] = cx"auto"
    child.cxSize[drow] = cx"auto"
    
    computeLayout(parent)
    # Auto should fill available space (parent size - offset)
    check child.box.w == 390 # 400 - 10
    check child.box.h == 290 # 300 - 10

  test "Min/Max constraints":
    let node = newTestNode("test", 0, 0, 100, 100)
    # Test min constraint
    node.cxSize[dcol] = min(150'ux, 200'ux)
    computeLayout(node)
    check node.box.w == 150
    # Test max constraint
    node.cxSize[drow] = max(150'ux, 200'ux)
    computeLayout(node)
    check node.box.h == 200

  test "Complex nested constraints":
    let parent = newTestNode("parent", 0, 0, 400, 300)
    let child1 = newTestNode("child1", 10, 10, 100, 100, parent)
    let child2 = newTestNode("child2", 10, 120, 100, 100, parent)
    
    # Child1: 50% of parent width, min 100px
    child1.cxSize[dcol] = max(50'pp, 100'ux) # same as csMax(csPerc(50), csFixed(100))
    
    # Child2: 25% of parent width + 50px
    child2.cxSize[dcol] = 25'pp + 50'ux # same as csAdd(csPerc(25), csFixed(50))
    
    computeLayout(parent)
    check child1.box.w == 200 # max(50% of 400, 100)
    check child2.box.w == 150 # (25% of 400) + 50

  test "Content based constraints":
    # prettyPrintWriteMode = cmTerminal
    # defer: prettyPrintWriteMode = cmNone
    let parent = newTestNode("parent", 0, 0, 400, 300)
    let child = newTestNode("child", 0, 0, 100, 100, parent)
    let grandchild = newTestNode("grandchild", 0, 0, 150, 80, child)
    
    grandchild.cxMin = [100'ux, 40'ux]
    grandchild.cxMax = [200'ux, 200'ux]
    
    # Set child width to fit content
    child.cxSize[dcol] = csContentMin()
    child.cxSize[drow] = csContentMin()
    child.cxMax[drow] = csContentMax()
    # calcBasicConstraint(child, dcol, isXY = false)
    computeLayout(parent)
    
    check grandchild.bmin == uiSize(100, 40)
    check child.box.w == grandchild.bmin.w # 
    check child.box.h == grandchild.bmin.h # 
    # check child.bmin == uiSize(100, 40)
    check child.bmax == uiSize(UiScalar.low, 200)

  test "Position constraints":
    # prettyPrintWriteMode = cmTerminal
    # defer: prettyPrintWriteMode = cmNone

    let parent = newTestNode("parent", 0, 0, 400, 300)
    let child = newTestNode("child")
    
    parent.children.add(child)
    child.parent = parent
    
    # Position 20px from left, 10% from top
    child.cxOffset[dcol] = 20'ux
    child.cxOffset[drow] = 10'pp
    
    calcBasicConstraint(parent)
    calcBasicConstraintPost(parent)

    calcBasicConstraint(child)
    calcBasicConstraintPost(child)
    
    printLayout(parent, cmTerminal)

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

    check child.box.x == 50
    check child.box.y == 50
    check child.box.w == 350
    check child.box.h == 250

  test "Post-process auto sizing with grid":
    let parent = newTestNode("parent", 0, 0, 400, 300)
    let child = newTestNode("child", 50, 50, 0, 0)
    parent.addChild(child)
    
    parent.cxSize = [csFixed(400), csFixed(300)]
    child.cxSize = [csAuto(), csAuto()]

    computeLayout(parent)

    check child.box.x == 50
    check child.box.y == 50
    check child.box.w == 350
    check child.box.h == 250

  test "grand child":
      # prettyPrintWriteMode = cmTerminal
      # defer: prettyPrintWriteMode = cmNone
      
      # Create the entire hierarchy in a single statement
      let parent = newTestTree("mixed-grid", 
        newTestNode("fixed-child", 0, 0, 100, 100),
        newTestTree("frac-child", 0, 0, 100, 100,
          newTestNode("frac-grandchild", 0, 0, 50, 50)
        ),
        newTestTree("auto-child", 0, 0, 100, 100,
          newTestNode("auto-grandchild", 0, 0, 50, 50)
        )
      )
      
      # Set fixed size constraints for parent
      parent.cxSize[dcol] = 400'ux
      parent.cxSize[drow] = 300'ux
      
      # Access children by index
      let child1 = parent.children[0]
      let child2 = parent.children[1]
      let child21 = child2.children[0]
      let child3 = parent.children[2]
      let child31 = child3.children[0]

      # # Set minimum content size for auto child
      child3.cxMin[dcol] = 100'ux # This should be respected as minimum width

      computeLayout(parent)

      check parent.cxSize[dcol] == 400'ux
      check parent.bmin.w == 400.UiScalar
      check parent.bmax.w == 400.UiScalar
      check child1.cxSize[dcol] == 100'ux
      check child2.bmin.w == 100.UiScalar
      check child2.bmax.w == 100.UiScalar
      check child21.cxSize[dcol] == 50'ux
      check child21.bmin.w == 50.UiScalar
      check child21.bmax.w == 50.UiScalar
      check child31.cxSize[dcol] == 50'ux
      check child31.bmin.w == 50.UiScalar
      check child31.bmax.w == 50.UiScalar
