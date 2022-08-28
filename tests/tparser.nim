import typetraits
import sequtils

import unittest
import cssgrid/basic
import cssgrid/gridtypes
import cssgrid/layout

import print

type
  GridNode* = ref object
    id: string
    box: UiBox
    gridItem: GridItem

proc `box=`*[T](v: T, box: UiBox) = 
  v.box = box

suite "grids":

  test "initial macros":
    var gridTemplate: GridTemplate

    parseGridTemplateColumns gridTemplate, ["first"] 40'ui ["second", "line2"] 50'pp ["line3"] auto ["col4-start"] 50'ui ["five"] 40'ui ["end"]

    # gridTemplate.computeLayout(uiBox(0, 0, 100, 100))
    let gt = gridTemplate

  test "initial macros":
    var gridTemplate: GridTemplate

    # grid-template-columns: [first] 40px [line2] 50px [line3] auto [col4-start] 50px [five] 40px [end];
    parseGridTemplateColumns gridTemplate, ["first"] 40'ui ["second", "line2"] 50'pp ["line3"] auto ["col4-start"] 50'ui ["five"] 40'ui ["end"]

    # gridTemplate.computeLayout(uiBox(0, 0, 100, 100))
    let gt = gridTemplate

    check gt.columns[0].track.kind == UiFixed
    check gt.columns[0].track.coord == 40.0.UiScalar
    echo repr gt.columns[0].aliases.toSeq.mapIt(it.int), repr toLineNames("first").toSeq.mapIt(it.int)
    check gt.columns[0].aliases == toLineNames("first")
    check gt.columns[1].track.kind == UiPerc
    check gt.columns[1].track.perc == 50.0.UiScalar
    check gt.columns[1].aliases == toLineNames("second", "line2")
    check gt.columns[2].track.kind == UiAuto
    check gt.columns[2].aliases == toLineNames("line3")
    check gt.columns[3].track.kind == UiFixed
    check gt.columns[3].track.coord == 50.0.UiScalar
    check gt.columns[3].aliases == toLineNames("col4-start")
    check gt.columns[4].track.kind == UiFixed
    check gt.columns[4].track.coord == 40.0.UiScalar
    check gt.columns[4].aliases == toLineNames("five")
    check gt.columns[5].track.kind == UiEnd
    check toLineNames("end") == gt.columns[5].aliases

    # print "grid template: ", gridTemplate
    # echo "grid template: ", repr gridTemplate
