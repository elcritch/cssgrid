
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
    cxSize*: array[GridDir, Constraint]  # For width/height
    cxOffset*: array[GridDir, Constraint] # For x/y positions
    cxMin*: array[GridDir, Constraint] # For x/y positions
    cxMax*: array[GridDir, Constraint] # For x/y positions
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


suite "Nested Content Size Tests":
    test "Auto grid track with nested fixed content":
      let parent = newTestNode("parent", 0, 0, 400, 300)
      let autoChild = newTestNode("auto-child", 0, 0, 0, 0)
      let fixedGrandchild = newTestNode("fixed-grandchild", 0, 0, 0, 0)
      
      parent.addChild(autoChild)
      autoChild.addChild(fixedGrandchild)
      
      # Setup grid
      parent.gridTemplate = newGridTemplate()
      parent.gridTemplate.lines[dcol] = @[
        initGridLine(csAuto())  # Auto column
      ]
      parent.gridTemplate.lines[drow] = @[
        initGridLine(csFixed(100))
      ]
      
      # Setup fixed size for grandchild
      fixedGrandchild.cxSize[dcol] = csFixed(150)
      fixedGrandchild.cxSize[drow] = csFixed(80)
      
      # Place auto child in grid
      autoChild.gridItem = newGridItem()
      autoChild.gridItem.column = 1
      autoChild.gridItem.row = 1
      
      computeLayout(parent, 0)
      
      printLayout(parent)
      # Auto track should be at least as wide as the fixed grandchild
      check autoChild.box.w >= 150
      check autoChild.box.h >= 80

    test "Multiple nested children in auto track":
      let parent = newTestNode("parent", 0, 0, 400, 300)
      let autoChild = newTestNode("auto-child", 0, 0, 0, 0)
      let grandchild1 = newTestNode("grandchild1", 0, 0, 0, 0)
      let grandchild2 = newTestNode("grandchild2", 0, 0, 0, 0)
      
      parent.addChild(autoChild)
      autoChild.addChild(grandchild1)
      autoChild.addChild(grandchild2)
      
      # Setup grid
      parent.gridTemplate = newGridTemplate()
      parent.gridTemplate.lines[dcol] = @[
        initGridLine(csAuto())
      ]
      parent.gridTemplate.lines[drow] = @[
        initGridLine(csAuto())
      ]
      
      # Fixed sizes for grandchildren
      grandchild1.cxSize[dcol] = csFixed(100)
      grandchild1.cxSize[drow] = csFixed(50)
      grandchild2.cxSize[dcol] = csFixed(150)
      grandchild2.cxSize[drow] = csFixed(70)
      
      autoChild.gridItem = newGridItem()
      autoChild.gridItem.column = 1
      autoChild.gridItem.row = 1
      
      computeLayout(parent, 0)
      
      # Auto track should accommodate largest child
      check autoChild.box.w >= 150
      check autoChild.box.h >= 70
