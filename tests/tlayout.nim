
import typetraits
import sequtils
import os

import unittest
import cssgrid/numberTypes
import cssgrid/gridtypes
import cssgrid/layout
import cssgrid/parser
import cssgrid/prettyprints

import pretty
import pixie


type
  GridNode* = ref object
    name*: string
    box*: UiBox
    bmin*, bmax*: UiSize
    parent*: GridNode
    gridItem*: GridItem
    gridTemplate*: GridTemplate
    cxSize*: array[GridDir, Constraint]  # For width/height
    cxOffset*: array[GridDir, Constraint] # For x/y positions
    cxMin*: array[GridDir, Constraint]  # For width/height
    cxMax*: array[GridDir, Constraint] # For x/y positions
    children*: seq[GridNode]
    frame*: Frame

  Frame = ref object
    windowSize*: UiBox

template getParentBoxOrWindows*(node: GridNode): UiBox =
  if node.parent.isNil:
    node.frame.windowSize
  else:
    node.parent.box

proc `box=`*[T](v: T, box: UiBox) = 
  v.box = box

var imageFiles: seq[string]

proc writeHtmlSummary() =
  var md = ""
  md.add &"<html>\n"
  md.add &"  <head>\n"
  md.add """
  <style>
    table, th, td {
      border: 1px solid black;
      border-collapse: collapse;
    }
    th, td {
      padding: 15px;
    }
  </style>
  """
  md.add &"    </head>\n"
  md.add &"  </head>\n"
  md.add &"  <body>\n"
  for file in imageFiles:
    let exfile = file.replace(".png", "-expected.png")
    md.add &"    <h2>{file}</h2>\n"
    md.add &"    <table style='border-spacing: 10px; border: 1px solid black;'>\n"
    md.add &"      <tr>\n"
    md.add &"        <th>{file}</th>\n"
    md.add &"        <th>{exfile}</th>\n"
    md.add &"      </tr>\n"
    md.add &"      <tr>\n"
    md.add &"        <td><img src='{file}'/></td>\n"
    md.add &"        <td><img src='{exfile}'/></td>\n"
    md.add &"      </tr>\n"
    md.add &"    </table>\n"
    md.add &"    <br>\n"
    md.add &"    <br>\n"
  md.add &"  </body>\n"
  md.add &"</html>\n"
  writeFile("tests/tlayout.html", md)
  echo("open tests/tlayout.html")

proc saveImage(gridTemplate: GridTemplate, box: UiBox, nodes: seq[GridNode], prefix = "") =
  # echo "grid template post: ", repr gridTemplate
  # echo "grid template post: ", repr box
  # ==== item a ====
  let image = newImage(box.w.int, box.h.int)
  image.fill(rgba(255, 255, 255, 255))

  # images
  let ctx = newContext(image)
  ctx.fillStyle = rgba(0, 255, 0, 255)

  for i in 0 ..< nodes.len():
    ctx.fillStyle = rgba(0, 55, 244, 255).asColor().spin(-15.3*i.float)
    ctx.fillRoundedRect(nodes[i].box.toRect(), 12.0)

  let file = fmt"tlayout-{prefix}{gridTemplate.autoFlow}.png"
  imageFiles.add(file)
  image.writeFile("tests" / file)

proc makeGrid1(gridTemplate: var GridTemplate, cnt: int = 6): (seq[GridNode], UiBox) =
  # grid-template-columns: [first] 40px [line2] 50px [line3] auto [col4-start] 50px [five] 40px [end];
  # parseGridTemplateColumns gridTemplate, 60'ux 60'ux 60'ux 60'ux 60'ux
  parseGridTemplateColumns gridTemplate, 1'fr 1'fr 1'fr 1'fr 1'fr 
  parseGridTemplateRows gridTemplate, 33'ux 33'ux
  gridTemplate.justifyItems = CxStretch

  var nodes = newSeq[GridNode](cnt)

  var parent = GridNode()
  parent.frame = Frame(windowSize: uiBox(0, 0, 400, 100))
  assert parent is GridNode
  parent.box = uiBox(0, 0,
                  60*(gridTemplate.columns().len().float-1),
                  33*(gridTemplate.rows().len().float-1))

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
    nodes[i] = GridNode(name: "b" & $(i-2), frame: parent.frame)

  # ==== process grid ====
  parent.children = nodes
  parent.gridTemplate = gridTemplate
  computeLayout(parent)
  result = (nodes, parent.box)

  printGrid(gridTemplate)

suite "grids":

  test "compute layout with auto flow":
    var gt1 = newGridTemplate()
    gt1.autoFlow = grRow
    let (n1, b1) = makeGrid1(gt1)
    saveImage(gt1, b1, n1)

    var gt2 = newGridTemplate()
    gt2.autoFlow = grColumn
    let (n2, b2) = makeGrid1(gt2)
    saveImage(gt2, b2, n2)

  test "compute no-autos":
    var gt1 = newGridTemplate()
    let (n1, b1) = makeGrid1(gt1)
    saveImage(gt1, b1, n1, "noauto-")

    var gt2 = newGridTemplate()
    let (n2, b2) = makeGrid1(gt2)
    saveImage(gt2, b2, n2, "noauto-")

  test "compute autos extra":
    var gt1 = newGridTemplate()
    gt1.autoFlow = grRow
    let (n1, b1) = makeGrid1(gt1, cnt=10)
    saveImage(gt1, b1, n1, "extra-")

    var gt2 = newGridTemplate()
    gt2.autoFlow = grColumn
    let (n2, b2) = makeGrid1(gt2, cnt=10)
    saveImage(gt2, b2, n2, "extra-")

  test "grid 1fr x 1fr":
    # grid-template-columns: [first] 40px [line2] 50px [line3] auto [col4-start] 50px [five] 40px [end];
    # parseGridTemplateColumns gridTemplate, 60'ux 60'ux 60'ux 60'ux 60'ux
    let cnt = 6
    var gridTemplate = newGridTemplate()
    gridTemplate.autoFlow = grRow

    parseGridTemplateColumns gridTemplate, 1'fr 1'fr 1'fr 1'fr 1'fr 
    parseGridTemplateRows gridTemplate, 33'ux 33'ux
    gridTemplate.justifyItems = CxStretch

    var nodes = newSeq[GridNode](cnt)

    var parent = GridNode()
    assert parent is GridNode
    parent.box = uiBox(0, 0,
                    60*(gridTemplate.columns().len().float-1),
                    33*(gridTemplate.rows().len().float-1))
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
      nodes[i] = GridNode(name: "b" & $(i-2), frame: parent.frame)

    # ==== process grid ====
    parent.children = nodes
    parent.computeLayout(0)

    printGrid(gridTemplate, cmTerminal)
    printLayout(parent, cmTerminal)
    saveImage(gridTemplate, parent.box, nodes, "grid-1frx1fr")

  test "grid 2fr x 2fr end":
    # grid-template-columns: [first] 40px [line2] 50px [line3] auto [col4-start] 50px [five] 40px [end];
    # parseGridTemplateColumns gridTemplate, 60'ux 60'ux 60'ux 60'ux 60'ux
    let cnt = 6
    var gridTemplate = newGridTemplate()
    gridTemplate.autoFlow = grRow

    parseGridTemplateColumns gridTemplate, 1'fr 1'fr 1'fr 1'fr 1'fr 
    parseGridTemplateRows gridTemplate, 33'ux 33'ux
    gridTemplate.justifyItems = CxStretch

    var nodes = newSeq[GridNode](cnt)

    var parent = GridNode()
    assert parent is GridNode
    parent.box = uiBox(0, 0,
                    60*(gridTemplate.columns().len().float-1),
                    33*(gridTemplate.rows().len().float-1))
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
      nodes[i] = GridNode(name: "b" & $(i-2), frame: parent.frame)

    # ==== process grid ====
    parent.children = nodes
    parent.computeLayout(0)

    printGrid(gridTemplate, cmTerminal)
    printLayout(parent, cmTerminal)
    saveImage(gridTemplate, parent.box, nodes, "grid-1frx1fr")

  writeHtmlSummary()
