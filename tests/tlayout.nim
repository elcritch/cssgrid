
import typetraits
import sequtils

import unittest
import cssgrid/basic
import cssgrid/gridtypes
import cssgrid/layout
import cssgrid/parser

import print
import pixie


type
  GridNode* = ref object
    id: string
    box: UiBox
    gridItem: GridItem

proc `box=`*[T](v: T, box: UiBox) = 
  v.box = box

suite "grids":

  test "compute layout with auto flow":
    var gridTemplate: GridTemplate

    # grid-template-columns: [first] 40px [line2] 50px [line3] auto [col4-start] 50px [five] 40px [end];
    parseGridTemplateColumns gridTemplate, 60'ui 60'ui 60'ui 60'ui 60'ui 60'ui
    parseGridTemplateRows gridTemplate, 33'ui 33'ui 33'ui
    gridTemplate.justifyItems = CxStretch

    gridTemplate.autoFlow = grColumn
    # gridTemplate.autoFlow = grRow

    let box = uiBox(0, 0,
                    60*(gridTemplate.columns().len().float-1),
                    33*(gridTemplate.rows().len().float-1))
    gridTemplate.computeLayout(box)
    # echo "grid template: ", repr gridTemplate
    var parent = GridNode()

    let contentSize = uiSize(30, 30)
    var nodes = newSeq[GridNode](6)

    # item a
    var itema = newGridItem()
    itema.columns = 1 // 2
    itema.rows = 1 // 3
    # let boxa = itema.computePosition(gridTemplate, contentSize)
    nodes[0] = GridNode(id: "a", gridItem: itema)

    # ==== item e ====
    var iteme = newGridItem()
    iteme.columns = 5 // 6
    iteme.rows = 1 // 3
    nodes[1] = GridNode(id: "e", gridItem: iteme)

    # ==== item b's ====
    for i in 2 ..< nodes.len():
      nodes[i] = GridNode(id: "b" & $(i-2))

    # ==== process grid ====
    gridTemplate.computeGridLayout(parent, nodes)

    echo "grid template post: ", repr gridTemplate
    # ==== item a ====
    let image = newImage(box.scaled.w.int, box.scaled.h.int)
    image.fill(rgba(255, 255, 255, 255))

    # images
    let ctx = newContext(image)
    ctx.fillStyle = rgba(0, 255, 0, 255)

    for i in 0 ..< nodes.len():
      ctx.fillStyle = rgba(0, 55, 244, 255).asColor().spin(-15.3*i.float)
      ctx.fillRoundedRect(nodes[i].box.scaled, 10.0)
      # check abs(nodes[i].box.w.float - 60.0) < 1.0e-3
      # check abs(nodes[i].box.h.float - 33.0) < 1.0e-3

    image.writeFile(fmt"tests/tlayout-{gridTemplate.autoFlow}.png")



