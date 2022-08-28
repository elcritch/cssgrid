import typetraits
import sequtils

import unittest
import cssgrid/parser
import cssgrid/gridtypes

import print

suite "grids":

  test "initial macros":
    var gt1: GridTemplate
    var gt2: GridTemplate
    var gt3: GridTemplate

    parseGridTemplateColumns gt1, ["first"] 40'ui ["second", "line2"] 50'pp ["line3"] auto ["col4-start"] 50'ui ["five"] 40'ui ["end"]

    # gridTemplate.computeLayout(uiBox(0, 0, 100, 100))
    parseGridTemplateColumns gt2:
      ["first"] 40'ui
      ["second", "line2"] 50'pp
      ["line3"] auto
      ["col4-start"] 50'ui
      ["five"] 40'ui
      ["end"]
  
    parseGridTemplateColumns gt3, ["first"] 40'ui ["second", "line2"] 50'pp ["line3"] \
      auto ["col4-start"] 50'ui ["five"] 40'ui \
      ["end"]
    
    for (c1, c2) in zip(gt1.columns, gt2.columns):
      check c1 == c2
    for (c1, c3) in zip(gt1.columns, gt3.columns):
      check c1 == c3

  test "simple macros":
    static:
      doPrints = true

    let ns = !["a", "b"]
    echo "ns: ", $ns
    var gt1 = newGridTemplate()
    gridTemplate gt1, dcol, {!["first"]: 40'ui, !["second", "line2"]: 50'pp, !["line3"]:
      csAuto(), !["col4-start"]: 50'ui, !["five"]: 40'ui,
      !["end"]: csEnd()}
    
    echo "gt1: ", $gt1
    
  # test "initial macros":
  #   var gridTemplate: GridTemplate

  #   # grid-template-columns: [first] 40px [line2] 50px [line3] auto [col4-start] 50px [five] 40px [end];
  #   parseGridTemplateColumns gridTemplate, ["first"] 40'ui ["second", "line2"] 50'pp ["line3"] auto ["col4-start"] 50'ui ["five"] 40'ui ["end"]

  #   # gridTemplate.computeLayout(uiBox(0, 0, 100, 100))
  #   let gt = gridTemplate

  #   check gt.columns[0].track.kind == UiFixed
  #   check gt.columns[0].track.coord == 40.0.UiScalar
  #   echo repr gt.columns[0].aliases.toSeq.mapIt(it.int), repr toLineNames("first").toSeq.mapIt(it.int)
  #   check gt.columns[0].aliases == toLineNames("first")
  #   check gt.columns[1].track.kind == UiPerc
  #   check gt.columns[1].track.perc == 50.0.UiScalar
  #   check gt.columns[1].aliases == toLineNames("second", "line2")
  #   check gt.columns[2].track.kind == UiAuto
  #   check gt.columns[2].aliases == toLineNames("line3")
  #   check gt.columns[3].track.kind == UiFixed
  #   check gt.columns[3].track.coord == 50.0.UiScalar
  #   check gt.columns[3].aliases == toLineNames("col4-start")
  #   check gt.columns[4].track.kind == UiFixed
  #   check gt.columns[4].track.coord == 40.0.UiScalar
  #   check gt.columns[4].aliases == toLineNames("five")
  #   check gt.columns[5].track.kind == UiEnd
  #   check toLineNames("end") == gt.columns[5].aliases

  #   # print "grid template: ", gridTemplate
  #   # echo "grid template: ", repr gridTemplate
