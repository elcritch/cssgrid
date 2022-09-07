import typetraits
import sequtils

import unittest
import cssgrid/parser
import cssgrid/gridtypes

import macros

suite "grids":

  test "initial macros":
    var gt1: GridTemplate
    var gt2: GridTemplate
    var gt3: GridTemplate

    expandMacros:
      parseGridTemplateColumns gt1, ["first"] 40'ui ["second", "line2"] 50'pp ["line3"] auto ["col4-start"] 50'ui ["five"] 40'ui ["end"]
    # gridTemplate.computeTracks(uiBox(0, 0, 100, 100))
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
    
    for (c1, c2) in zip(gt1.lines[dcol], gt2.lines[dcol]):
      check c1 == c2
    for (c1, c3) in zip(gt1.lines[dcol], gt3.lines[dcol]):
      check c1 == c3
    
    expandMacros:
      let nm = findLineName("first")
      echo "NM: ", $nm

  test "simple macros":
    let ns = !["a", "b"]
    echo "ns: ", $ns
    var gt1 = newGridTemplate()
    gridTemplate gt1, dcol, {!["first"]: 40'ui, !["second", "line2"]: 50'pp, !["line3"]:
      csAuto(), !["col4-start"]: 50'ui, !["five"]: 40'ui,
      !["end"]: csEnd()}
    
    echo "gt1: ", $gt1
    
  test "initial macros":
    proc checkColumns(gt: GridTemplate, dir: GridDir) =
      check gt.lines[dir][0].track.kind == UiFixed
      check gt.lines[dir][0].track.coord == 40.0.UiScalar
      check gt.lines[dir][0].aliases == toLineNames("first")
      check gt.lines[dir][1].track.kind == UiPerc
      check gt.lines[dir][1].track.perc == 50.0.UiScalar
      check gt.lines[dir][1].aliases == toLineNames("second", "line2")
      check gt.lines[dir][2].track.kind == UiAuto
      check gt.lines[dir][2].aliases == toLineNames("line3")
      check gt.lines[dir][3].track.kind == UiFixed
      check gt.lines[dir][3].track.coord == 50.0.UiScalar
      check gt.lines[dir][3].aliases == toLineNames("col4-start")
      check gt.lines[dir][4].track.kind == UiFixed
      check gt.lines[dir][4].track.coord == 40.0.UiScalar
      check gt.lines[dir][4].aliases == toLineNames("five")
      check gt.lines[dir][5].track.kind == UiEnd
      check gt.lines[dir][5].aliases == toLineNames("end")
    
    # checks
    var gt1: GridTemplate
    parseGridTemplateColumns gt1, ["first"] 40'ui ["second", "line2"] 50'pp ["line3"] auto ["col4-start"] 50'ui ["five"] 40'ui ["end"]
    gt1.checkColumns(dcol)
    # checks
    var gt2 = newGridTemplate()
    parseGridTemplateRows gt2, ["first"] 40'ui ["second", "line2"] 50'pp ["line3"] auto ["col4-start"] 50'ui ["five"] 40'ui ["end"]
    gt2.checkColumns(drow)

  test "columns ":
    let ns = !["a", "b"]
    echo "ns: ", $ns
    var gt1 = newGridTemplate()
    gridTemplate gt1, dcol, {!["first"]: 40'ui, !["second", "line2"]: 50'pp, !["line3"]:
      csAuto(), !["col4-start"]: 50'ui, !["five"]: 40'ui,
      !["end"]: csEnd()}
    
    echo "gt1: ", $gt1

    # ==== item e ====
    var iteme = newGridItem()
    iteme.column = 5 // 6
    iteme.row = 1 // 3
    check iteme.column.a.line.int == 5
    check iteme.column.b.line.int == 6
    check iteme.column.b.isSpan == false

    iteme.column = 1 // span 4
    iteme.row = 1 // span 3
    check iteme.column.a.line.int == 1
    check iteme.column.b.line.int == 4
    check iteme.column.b.isSpan == true

    iteme.column = 2 // span "first"
    iteme.row = 1 // "second"
    check iteme.column.a.line.int == 2
    check iteme.column.b.line.int == 2851137560
    check iteme.column.b.isSpan == true
    check iteme.row.a.line.int == 1
    check iteme.row.b.line.int == 436751995
    check iteme.row.b.isSpan == false
