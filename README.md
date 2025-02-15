# CSS Grid

Implementation of CSS Grid for usage in GUI's and TUI's. It currently covers the basics of the CSS grid and includes support for fractions, percents, auto-flow, and auto-insert. The intent is to be fairly (but not 100%) compatible implementation of CSS Grid. 

The code is written with minimal expectations for input and outputs so it could be used with various UI frameworks. Currently it assums float32's as the scalar basis for ease of implementation but could be expanded to support integer scalars as well. 

Contributions, issues, and PR's are welcome. 

## API Example

The API can be used directly to setup a CSS Grid. A mini-DSL macro is provided which mimics the CSS syntax. Though it's intented to be used to implement user facing API that matches the UI framework.  

Here's an example of using the macro to parse CSS style grid syntax:

```nim
  test "compute others":
    var gt: GridTemplate

    parseGridTemplateColumns gt, ["first"] 40'ux \
      ["second", "line2"] 50'ux \
      ["line3"] auto \
      ["col4-start"] 50'ux \
      ["five"] 40'ux ["end"]
    parseGridTemplateRows gt, ["row1-start"] 25'pp \
      ["row1-end"] 100'ux \
      ["third-line"] auto ["last-line"]

    gt.gaps[dcol] = 10.UiScalar
    gt.gaps[drow] = 10.UiScalar
```

## Layout Example 

See [tlayout.nim](tests/tlayout.nim) for a complete example using Pixie to layout a series of rectangles: 

Using `auto-flow: row`:

![Layout Row](tests/tlayout-grRow-expected.png)

Using `auto-flow: column`:

![Layout Row](tests/tlayout-grColumn-expected.png)

## Basic Usage

```nim
type
  TestNode* = ref object
    ## a container that fullfills the GridNode concept
    name: string
    box: UiBox
    bmin, bmax: UiSize
    gridItem: GridItem
    cxSize: array[GridDir, Constraint]  # For width/height
    cxOffset: array[GridDir, Constraint] # For x/y positions
    cxMin: array[GridDir, Constraint]  # For width/height
    cxMax: array[GridDir, Constraint] # For x/y positions
    gridTemplate: GridTemplate
    children: seq[TestNode]
    parent*: TestNode

template getParentBoxOrWindows*(node: TestNode): UiBox =
  ## this needs to be implemented for the GridNode type
  if node.parent.isNil:
    node.frame.windowSize
  else:
    node.parent.box

proc newTestNode(name: string, x, y, w, h: float32): TestNode =
  result = TestNode(
    name: name, box: uiBox(x, y, w, h), children: @[],
    frame: Frame(windowSize: uiBox(0, 0, 800, 600))
  )

proc addChild(parent, child: TestNode) =
  parent.children.add(child)
  child.parent = parent

test "Grid with basic constrained children":
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
```


