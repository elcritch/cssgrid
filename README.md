# CSS Grid

Implementation of CSS Grid for usage in GUI's and TUI's. It currently covers the basics of the CSS grid and includes support for fractions, percents, auto-flow, and auto-insert. The intent is to be fairly (but not 100%) compatible implementation of CSS Grid. 

The code is written with minimal expectations for input and outputs so it could be used with various UI frameworks. Currently it assums float32's as the scalar basis for ease of implementation but could be expanded to support integer scalars as well. 

Contributions, issues, and PR's are welcome. 

## API Example

The API can be used directly to setup a CSS Grid. A mini-DSL macro is provided which mimics the CSS syntax. Though it's intented to be used to implement user facing API that matches the UI framework.  

Here's an example of the CSS style syntax:

```nim
  test "compute others":
    var gt: GridTemplate

    parseGridTemplateColumns gt, ["first"] 40'ui \
      ["second", "line2"] 50'ui \
      ["line3"] auto \
      ["col4-start"] 50'ui \
      ["five"] 40'ui ["end"]
    parseGridTemplateRows gt, ["row1-start"] 25'pp \
      ["row1-end"] 100'ui \
      ["third-line"] auto ["last-line"]

    gt.gaps[dcol] = 10.UiScalar
    gt.gaps[drow] = 10.UiScalar
```

## Layout Example 

See [tlayout.nim](tests/tlayout.nim) for a complete example using Pixie to layout a series of rectangles: 

![Layout Row](tests/tlayout-grColumn-expected.png)

Here's an edited form of it:

```nim
proc makeGrid1(gridTemplate: var GridTemplate): (seq[GridNode], UiBox) =
  # grid-template-columns: [first] 40px [line2] 50px [line3] auto [col4-start] 50px [five] 40px [end];
  parseGridTemplateColumns gridTemplate, 60'ui 60'ui 60'ui 60'ui 60'ui 60'ui
  parseGridTemplateRows gridTemplate, 33'ui 33'ui 33'ui
  gridTemplate.justifyItems = CxStretch

  let box = uiBox(0, 0,
                  60*(gridTemplate.columns().len().float-1),
                  33*(gridTemplate.rows().len().float-1))

  var nodes = newSeq[GridNode](6)

  gridTemplate.computeTracks(box)
  # echo "grid template: ", repr gridTemplate
  var parent = GridNode()

  # item a
  var itema = newGridItem()
  itema.column = 1
  itema.row = 1 // 3
  # let boxa = itema.computeTracks(gridTemplate, contentSize)
  nodes[0] = GridNode(id: "a", gridItem: itema)

  # ==== item e ====
  var iteme = newGridItem()
  iteme.column = 5 // 6
  iteme.row = 1 // 3
  nodes[1] = GridNode(id: "e", gridItem: iteme)

  # ==== item b's ====
  for i in 2 ..< nodes.len():
    nodes[i] = GridNode(id: "b" & $(i-2))

  # ==== process grid ====
  gridTemplate.computeNodeLayout(parent, nodes)
  result = (nodes, box)

suite "grids":

  test "compute layout with auto flow":
    var gt1 = newGridTemplate()
    gt1.autoFlow = grRow
    let (n1, b1) = makeGrid1(gt1)
    saveImage(gt1, b1, n1)

```

