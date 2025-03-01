
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

import commontestutils

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

proc saveImage(gridTemplate: GridTemplate, box: UiBox, nodes: seq[TestNode], prefix = "") =
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

proc makeGrid1(gridTemplate: var GridTemplate, cnt: int = 6): (seq[TestNode], UiBox) =
  # grid-template-columns: [first] 40px [line2] 50px [line3] auto [col4-start] 50px [five] 40px [end];
  # parseGridTemplateColumns gridTemplate, 60'ux 60'ux 60'ux 60'ux 60'ux
  parseGridTemplateColumns gridTemplate, 1'fr 1'fr 1'fr 1'fr 1'fr 
  parseGridTemplateRows gridTemplate, 33'ux 33'ux
  gridTemplate.justifyItems = CxStretch

  var nodes = newSeq[TestNode](cnt)

  var parent = TestNode(name: "parent")
  parent.frame = Frame(windowSize: uiBox(0, 0, 400, 100))
  assert parent is TestNode
  # parent.box = uiBox(0, 0,
  parent.cxOffset = [
                  csFixed(0),
                  csFixed(0)
  ]
  parent.cxSize = [
                  csFixed(60*(gridTemplate.columns().len().float-1)),
                  csFixed(33*(gridTemplate.rows().len().float-1))
  ]

  # item a
  var itema = newGridItem()
  itema.column = 1 // 2
  itema.row = 1 // 3
  nodes[0] = TestNode(name: "a", gridItem: itema, frame: parent.frame)

  # ==== item e ====
  var iteme = newGridItem()
  iteme.column = 5 // 6
  iteme.row = 1 // 3
  nodes[1] = TestNode(name: "e", gridItem: iteme, frame: parent.frame)

  # ==== item b's ====
  for i in 2 ..< nodes.len():
    nodes[i] = TestNode(name: "b" & $(i-2), frame: parent.frame)
    nodes[i].parent = parent

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

  test "compute autos extra":
    var gt1 = newGridTemplate()
    gt1.autoFlow = grRow
    let (n1, b1) = makeGrid1(gt1, cnt=10)
    saveImage(gt1, b1, n1, "extra-")

    var gt2 = newGridTemplate()
    gt2.autoFlow = grColumn
    let (n2, b2) = makeGrid1(gt2, cnt=10)
    saveImage(gt2, b2, n2, "extra-")

  test "grid alignment and justification":
    # grid-template-columns: [first] 40px [line2] 50px [line3] auto [col4-start] 50px [five] 40px [end];
    # parseGridTemplateColumns gridTemplate, 60'ux 60'ux 60'ux 60'ux 60'ux
    let cnt = 8
    var gridTemplate = newGridTemplate()
    gridTemplate.autoFlow = grRow

    parseGridTemplateColumns gridTemplate, 1'fr 1'fr 1'fr 1'fr 1'fr 
    parseGridTemplateRows gridTemplate, 50'ux 50'ux
    gridTemplate.justifyItems = CxStretch

    var nodes = newSeq[TestNode](cnt)

    var parent = TestNode(gridTemplate: gridTemplate)
    assert parent is TestNode
    parent.cxSize = [300'ux, 100'ux]
    parent.frame = Frame(windowSize: uiBox(0, 0, 400, 100))

    # item a
    var itema = newGridItem()
    itema.column = 1 // 2
    itema.row = 1 // 3
    nodes[0] = TestNode(name: "a", gridItem: itema, frame: parent.frame)

    # ==== item e ====
    var iteme = newGridItem()
    iteme.column = 5 // 6
    iteme.row = 1 // 3
    nodes[1] = TestNode(name: "e", gridItem: iteme, frame: parent.frame)

    # ==== item b's ====
    for i in 2 ..< nodes.len():
      let gi = newGridItem()
      nodes[i] = TestNode(name: "b" & $(i-2), gridItem: gi, frame: parent.frame)
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

    # printGrid(gridTemplate, cmTerminal)
    # printLayout(parent, cmTerminal)
    saveImage(gridTemplate, parent.box, nodes, "grid-align-and-justify")

  writeHtmlSummary()
