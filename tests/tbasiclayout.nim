import unittest
import typetraits
import sequtils

import unittest
import cssgrid/numberTypes
import cssgrid/gridtypes
import cssgrid/basiclayout
import cssgrid/basiccalcs
import cssgrid/parser
import cssgrid/prettyprints

import cssgrid/layout

import pretty

import commontestutils

suite "Basic CSS Layout Tests":
  setup:
    prettyPrintWriteMode = cmNone
    clearPrettyPrintWriteMode()

  test "Fixed size constraints":
    let node = newTestNode("test")
    node.cxSize[dcol] = 200'ux
    node.cxSize[drow] = 150'ux
    
    computeLayout(node)
    check node.box.w == 200
    check node.box.h == 150

  test "Percentage constraints":
    let parent = newTestNode("parent")
    parent.cxSize = [400'ux, 300'ux]
    let child = newTestNode("child", parent)
    
    child.cxSize = [50'pp, 25'pp]
    
    # setPrettyPrintMode(cmTerminal)
    # defer: prettyPrintWriteMode = cmNone
    computeLayout(parent)
    check child.box.w == 200 # 50% of 400
    check child.box.h == 75  # 25% of 300

  test "Auto constraints":
    let parent = newTestNode("parent")
    parent.cxSize = [400'ux, 300'ux]
    let child = newTestNode("child", parent)
    
    child.cxSize = [cx"auto", cx"auto"]
    
    # setPrettyPrintMode(cmTerminal)
    # addPrettyPrintFilter("dir", "drow")
    computeLayout(parent)
    # Auto should fill available space (parent size - offset)
    check child.box.w == 400 # 400 - 10
    check child.box.h == 300 # 300 - 10

    child.cxSize[drow] = cx"none"
    child.cxMin[drow] = 100'ux
    computeLayout(parent)
    # Auto should fill available space (parent size - offset)
    check child.box.w == 400 # 400 - 10
    check child.box.h == 100 # 300 - 10

  test "Min/Max constraints":
    let node = newTestNode("test")
    # Test min constraint
    node.cxSize[dcol] = min(150'ux, 200'ux)
    computeLayout(node)
    check node.box.w == 150
    # Test max constraint
    node.cxSize[drow] = max(150'ux, 200'ux)
    computeLayout(node)
    check node.box.h == 200

  test "Padding":
    let parent = newTestNode("parent")
    parent.cxSize = [400'ux, 300'ux]
    let child1 = newTestNode("child1", parent)

    # setPrettyPrintMode(cmTerminal)
    # addPrettyPrintFilter("dir", "drow")

    parent.cxPadOffset = [10'ux, 10'ux]
    parent.cxPadSize = [10'ux, 10'ux]
    child1.cxSize = [cx"auto", cx"auto"]
    computeLayout(parent)

    prettyPrintWriteMode = cmNone

    check parent.bpad == uiBox(10, 10, 10, 10)
    check child1.box.x == 10
    check child1.box.y == 10
    check child1.box.w == 380
    check child1.box.h == 280

    child1.cxSize = [100'pp, 100'pp]
    computeLayout(parent)

    check parent.bpad == uiBox(10, 10, 10, 10)
    check child1.box.x == 10
    check child1.box.y == 10
    check child1.box.w == 400
    check child1.box.h == 300

    child1.cxSize = [1'fr, 1'fr]
    computeLayout(parent)

    check parent.bpad == uiBox(10, 10, 10, 10)
    check child1.box.x == 10
    check child1.box.y == 10
    check child1.box.w == 380
    check child1.box.h == 280

    child1.cxSize = [cx"min-content", cx"min-content"]
    computeLayout(parent)

    check parent.bpad == uiBox(10, 10, 10, 10)
    check child1.box.x == 10
    check child1.box.y == 10
    check child1.box.w == 0
    check child1.box.h == 0

  test "Padding mixed":
    let parent = newTestNode("parent")
    parent.cxSize = [400'ux, 300'ux]
    let child1 = newTestNode("child1", parent)

    parent.cxPadOffset = [0'ux, 10'ux]
    parent.cxPadSize = [0'ux, 10'ux]
    child1.cxSize = [cx"auto", cx"none"]
    # setPrettyPrintMode(cmTerminal)
    computeLayout(parent)
    # prettyPrintWriteMode = cmNone

    check parent.bpad == uiBox(0, 10, 0, 10)
    check child1.box.x == 0
    check child1.box.y == 10
    check child1.box.w == 400
    check child1.box.h == 0

    child1.cxSize = [100'pp, 100'pp]

    computeLayout(parent)

    check parent.bpad == uiBox(0, 10, 0, 10)
    check child1.box.x == 0
    check child1.box.y == 10
    check child1.box.w == 400
    check child1.box.h == 300

  test "Complex nested constraints":
    let parent = newTestNode("parent")
    parent.cxSize = [400'ux, 300'ux]
    let child1 = newTestNode("child1", parent)
    let child2 = newTestNode("child2", parent)
    
    # Child1: 50% of parent width, min 100px
    child1.cxSize[dcol] = max(50'pp, 100'ux) # same as csMax(csPerc(50), csFixed(100))
    
    # Child2: 25% of parent width + 50px
    child2.cxSize[dcol] = 25'pp + 50'ux # same as csAdd(csPerc(25), csFixed(50))
    
    computeLayout(parent)
    check child1.box.w == 200 # max(50% of 400, 100)
    check child2.box.w == 150 # (25% of 400) + 50

  test "Content based constraints":
    # setPrettyPrintMode(cmTerminal)
    # defer: prettyPrintWriteMode = cmNone
    let parent = newTestNode("parent")
    parent.cxSize = [400'ux, 300'ux]
    let child = newTestNode("child", parent)
    let grandchild = newTestNode("grandchild", child)
    
    grandchild.cxMin = [111'ux, 44'ux]
    grandchild.cxMax = [200'ux, 200'ux]
    
    # Set child width to fit content
    child.cxSize[dcol] = csContentMin()
    child.cxSize[drow] = csContentMin()
    child.cxMax[drow] = csContentMax()
    # calcBasicConstraint(child, dcol, isXY = false)
    # setPrettyPrintMode(cmTerminal)
    computeLayout(parent)
    
    check grandchild.bmin == uiSize(111, 44)
    check child.box.w == grandchild.bmin.w # 
    check child.box.h == grandchild.bmin.h # 
    # check child.bmin == uiSize(100, 40)
    check child.bmax == uiSize(UiScalar.low, 200)

  test "Content based constraints":
    # setPrettyPrintMode(cmTerminal)
    # defer: prettyPrintWriteMode = cmNone
    let parent = newTestNode("parent")
    let child = newTestNode("child", parent)
    let grandchild = newTestNode("grandchild", child)
    
    grandchild.cxMin = [100'ux, 40'ux]
    grandchild.cxSize = [150'ux, 80'ux]
    grandchild.cxMax = [200'ux, 200'ux]
    
    # Set child width to fit content
    child.cxSize[dcol] = csContentFit()
    child.cxSize[drow] = csContentFit()
    # calcBasicConstraint(child, dcol, isXY = false)
    computeLayout(parent)
    
    check grandchild.bmin == uiSize(100, 40)
    check child.box.w == 150
    check child.box.h == 80
    # check child.bmin == uiSize(100, 40)
    # check child.bmax == uiSize(UiScalar.low, 200)

  test "Position constraints":
    # setPrettyPrintMode(cmTerminal)
    # defer: prettyPrintWriteMode = cmNone
    let parent = newTestNode("parent")
    parent.cxSize = [400'ux, 300'ux]
    let child = newTestNode("child", parent)
    
    parent.children.add(child)
    child.parent = parent
    
    # Position 20px from left, 10% from top
    child.cxOffset[dcol] = 20'ux
    child.cxOffset[drow] = 10'pp
    
    calcBasicConstraint(parent, nil)
    calcBasicConstraintPost(parent, nil)

    calcBasicConstraint(child, nil)
    calcBasicConstraintPost(child, nil)
    
    # printLayout(parent, cmTerminal)

    check child.box.x == 20
    check child.box.y == 30 # 10% of 300

  test "Post-process auto sizing with grid":
    let parent = newTestNode("parent")
    let child = newTestNode("child", parent)
    
    parent.cxOffset = [csFixed(400), csFixed(300)]

    # Setup grid
    child.cxSize = [csAuto(), csNone()]
    
    computeLayout(parent)
    printLayout(parent, cmTerminal)

    check child.box.x == 0
    check child.box.y == 0
    check child.box.w == 400
    check child.box.h == 0

    child.cxMin = [100'ux, 100'ux]
    computeLayout(parent)
    check child.box.w == 400
    check child.box.h == 100

  test "Post-process auto sizing with grid":
    let parent = newTestNode("parent")
    parent.cxSize = [400'ux, 300'ux]
    let child = newTestNode("child", parent)
    child.cxOffset = [50'ux, 50'ux]
    
    parent.cxSize = [csFixed(400), csFixed(300)]
    child.cxSize = [csAuto(), csAuto()]

    computeLayout(parent)

    check child.box.x == 50
    check child.box.y == 50
    check child.box.w == 400
    check child.box.h == 300

    child.cxSize[drow] = cx"none"
    child.cxMin = [100'ux, 100'ux]
    computeLayout(parent)
    check child.box.w == 400
    check child.box.h == 100

  test "grand child":
      # setPrettyPrintMode(cmTerminal)
      # defer: prettyPrintWriteMode = cmNone
      
      # Create the entire hierarchy in a single statement
      let parent = newTestTree("mixed-grid") 
      let fixedChild = newTestNode("fixed-child", parent)
      let fracChild = newTestNode("frac-child", parent)
      let fracGrandChild = newTestNode("frac-grandchild", fracChild)
      let autoChild = newTestNode("auto-child", parent)
      let autoGrandChild = newTestNode("auto-grandchild", autoChild)

      parent.cxSize[dcol] = 400'ux
      parent.cxSize[drow] = 300'ux

      fixedChild.cxSize = [100'ux, 100'ux]
      fracChild.cxSize = [100'ux, 100'ux]
      autoChild.cxSize = [100'ux, 100'ux]

      fracGrandChild.cxSize = [50'ux, 50'ux]
      autoGrandChild.cxSize = [50'ux, 50'ux]
      
      # Set fixed size constraints for parent
      
      # # Set minimum content size for auto child
      autoChild.cxMin[dcol] = 100'ux # This should be respected as minimum width

      computeLayout(parent)
      # printLayout(parent, cmTerminal)

      check parent.cxSize[dcol] == 400'ux
      check parent.bmin.w == 400.UiScalar
      check parent.bmax.w == 400.UiScalar
      check fracChild.cxSize[dcol] == 100'ux
      check fracChild.bmin.w == 100.UiScalar
      check fracChild.bmax.w == 100.UiScalar
      check autoChild.bmin.w == 100.UiScalar
      check autoChild.cxSize[dcol] == 50'ux
      check autoGrandChild.bmin.w == 50.UiScalar
      check autoGrandChild.bmax.w == 50.UiScalar

  test "grand child min propogates":
      # setPrettyPrintMode(cmTerminal)
      # defer: prettyPrintWriteMode = cmNone

      # Create the entire hierarchy in a single statement
      let parent = newTestNode("mixed-grid") 
      let child1 = newTestNode("fixed-child", parent)
      let child11 = newTestNode("fixed-grandchild", child1)
      let child2 = newTestNode("auto-child", parent)
      let child21 = newTestNode("auto-grandchild", child2)

      parent.cxSize = [400'ux, 100'ux]
      child1.cxSize = [400'ux, 50'ux]
      child11.cxMin = [100'ux, 60'ux]
      child21.cxMin = [100'ux, 70'ux]
      # child2.cxSize = [cx"auto", cx"none"]
      # child21.cxSize = [cx"auto", cx"none"]

      computeLayout(parent)
      # printLayout(parent, cmTerminal)

      check child1.box == uiBox(0, 0, 400, 50)
      check child11.box == uiBox(0, 0, 400, 60) # larger than fixed parent

      # check child2.box.y == 50
      check child2.box.h == 70
      check child21.box.h == 70

  test "grand child min propogates with padding":
      # setPrettyPrintMode(cmTerminal)
      # defer: prettyPrintWriteMode = cmNone

      # Create the entire hierarchy in a single statement
      let mixedGrid = newTestNode("mixed-grid") 
      let fixedChild = newTestNode("fixed-child", mixedGrid)
      let fixedGrandchild = newTestNode("fixed-grandchild", fixedChild)
      let autoChild = newTestNode("auto-child", mixedGrid)
      let autoGrandchild = newTestNode("auto-grandchild", autoChild)

      mixedGrid.cxSize = [400'ux, 100'ux]
      fixedChild.cxSize = [400'ux, 50'ux]
      fixedGrandchild.cxMin = [100'ux, 60'ux]
      autoGrandchild.cxMin = [100'ux, 70'ux]
      autoChild.cxPadSize[drow] = 10'ux
      autoChild.cxPadOffset[drow] = 10'ux
      autoChild.cxSize = [cx"auto", cx"auto"]
      autoGrandchild.cxSize = [cx"auto", cx"auto"]
      # child21.cxSize = [cx"auto", cx"none"]

      computeLayout(mixedGrid)
      # printLayout(mixedGrid, cmTerminal)

      check fixedChild.box == uiBox(0, 0, 400, 50)
      check fixedGrandchild.box == uiBox(0, 0, 400, 60) # larger than fixed parent

      # check child2.box.y == 50
      check autoChild.box.h == 100
      check autoGrandchild.box.h == 80
