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

Using `auto-flow: row`:

![Layout Row](tests/tlayout-grRow-expected.png)

Using `auto-flow: column`:

![Layout Row](tests/tlayout-grColumn-expected.png)

## Basic Usage

```nim
type
  GridNode* = ref object
    ## a container that fullfills the concept
    id: string
    box: UiBox
    gridItem: GridItem

proc `box=`*[T](v: T, box: UiBox) = 
  v.box = box

proc setupGrid(): (seq[GridNode], UiBox) =
  var gridTemplate: GridTemplate # holds the grid info
  # setup the grid constraints
  parseGridTemplateColumns gridTemplate, 60'ui 60'ui 60'ui 60'ui 60'ui 60'ui
  parseGridTemplateRows gridTemplate, 33'ui 33'ui 33'ui
  # set item behavior
  gridTemplate.justifyItems = CxStretch

  # nodes are a concept for containers that hold a
  # box and a gridItem.  
  var nodes = newSeq[GridNode](1)

  var parent = GridNode()
  # create bounding box -- a box are UI coordinates in [X, Y, W, H] format
  parent.box = uiBox(0, 0,
                  60*(gridTemplate.columns().len().float-1),
                  33*(gridTemplate.rows().len().float-1))

  # item a
  var itema = newGridItem()
  itema.column = 1
  itema.row = 1 // 3
  nodes[0] = GridNode(id: "a", gridItem: itema)

  # computes the grid layout, flows any non-fixed nodes and sets node box sizes
  gridTemplate.computeNodeLayout(parent, nodes)
  result = (nodes, box)

```


