
import typetraits
import sequtils

import unittest
import cssgrid/numberTypes
import cssgrid/gridtypes
import cssgrid/layout
import cssgrid/parser

import pretty
import pixie


type
  GridNode* = ref object
    id: string
    box: UiBox
    gridItem: GridItem

proc `box=`*[T](v: T, box: UiBox) = 
  v.box = box

proc makeGrid1(gridTemplate: var GridTemplate, cnt: int = 6): (seq[GridNode], UiBox) =
  # grid-template-columns: [first] 40px [line2] 50px [line3] auto [col4-start] 50px [five] 40px [end];
  parseGridTemplateColumns gridTemplate, 60'ux 60'ux 60'ux 60'ux 60'ux
  parseGridTemplateRows gridTemplate, 33'ux 33'ux
  gridTemplate.justifyItems = CxStretch


  var nodes = newSeq[GridNode](cnt)

  var parent = GridNode()
  parent.box = uiBox(0, 0,
                  60*(gridTemplate.columns().len().float-1),
                  33*(gridTemplate.rows().len().float-1))

  # item a
  var itema = newGridItem()
  itema.column = 1
  itema.row = 1 // 3
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
  result = (nodes, parent.box)

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
    ctx.fillRoundedRect(nodes[i].box.Rect, 12.0)

  image.writeFile(fmt"tests/tlayout-{prefix}{gridTemplate.autoFlow}.png")

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

  test "compute autos":
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
    let (n1, b1) = makeGrid1(gt1)
    saveImage(gt1, b1, n1)

    var gt2 = newGridTemplate()
    gt2.autoFlow = grColumn
    let (n2, b2) = makeGrid1(gt2)
    saveImage(gt2, b2, n2, "extra-")



