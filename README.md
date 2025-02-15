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
  
  computeLayout(parent)
  
  check child1.box.w == 200  # 50% of 400
  check child1.box.h == 90   # 30% of 300
  check child2.box.w == 280  # 70% of 400
  check child2.box.h == 120  # 40% of 300
```


Here's another example using Pixie to generate an image of the grid layout. This layout also sets HTML / CSS Grid style alignment and justification.

From [tplots.nim](tests/tplots.nim):

```nim
  test "grid alignment and justification":
    # grid-template-columns: [first] 40px [line2] 50px [line3] auto [col4-start] 50px [five] 40px [end];
    # parseGridTemplateColumns gridTemplate, 60'ux 60'ux 60'ux 60'ux 60'ux
    let cnt = 8
    var gridTemplate = newGridTemplate()
    gridTemplate.autoFlow = grRow

    parseGridTemplateColumns gridTemplate, 1'fr 1'fr 1'fr 1'fr 1'fr 
    parseGridTemplateRows gridTemplate, 50'ux 50'ux
    gridTemplate.justifyItems = CxStretch

    var nodes = newSeq[GridNode](cnt)

    var parent = GridNode(gridTemplate: gridTemplate)
    assert parent is GridNode
    parent.cxSize = [300'ux, 100'ux]
    parent.frame = Frame(windowSize: uiBox(0, 0, 400, 100))

    # item a
    var itema = newGridItem()
    itema.column = 1 // 2
    itema.row = 1 // 3
    nodes[0] = GridNode(name: "a", gridItem: itema, frame: parent.frame)

    # ==== item e ====
    var iteme = newGridItem()
    iteme.column = 5 // 6
    iteme.row = 1 // 3
    nodes[1] = GridNode(name: "e", gridItem: iteme, frame: parent.frame)

    # ==== item b's ====
    for i in 2 ..< nodes.len():
      let gi = newGridItem()
      nodes[i] = GridNode(name: "b" & $(i-2), gridItem: gi, frame: parent.frame)
      nodes[i].cxSize = [33'ux, 33'ux]
      nodes[i].parent = parent
      nodes[i].gridItem.justify = some(CxCenter)
      nodes[i].gridItem.align = some(CxCenter)
      if i == 5:
        nodes[i].gridItem.justify = some(CxStart)
      if i == 6:
        nodes[i].gridItem.align = some(CxStart)
      if i == 7:
        nodes[i].gridItem.align = some(CxEnd)

    # ==== process grid ====
    parent.children = nodes
    parent.computeLayout()

    printGrid(gridTemplate, cmTerminal)
    printLayout(parent, cmTerminal)
    saveImage(gridTemplate, parent.box, nodes, "grid-align-and-justify")
```

## Basic Layouts

CSS Grid now handles basic HTML style layouts. These are also integrated with the CSS Grid so you can specify things like content-min and have the grid layout understand it!

From [tbasiclayout.nim](tests/tbasiclayout.nim):

```nim
suite "Basic CSS Layout Tests":
  test "Fixed size constraints":
    let node = newTestNode("test", 0, 0, 100, 100)
    node.cxSize[dcol] = 200'ux
    node.cxSize[drow] = 150'ux
    
    calcBasicConstraint(node)
    
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

```