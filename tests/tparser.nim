import typetraits
import sequtils

import unittest
import cssgrid/parser
import cssgrid/gridtypes

import stack_strings

import macros

suite "grids":

  test "initial macros":
    var gt1: GridTemplate
    var gt2: GridTemplate
    var gt3: GridTemplate

    expandMacros:
      parseGridTemplateColumns gt1, ["first"] 40'ux ["second", "line2"] 50'pp ["line3"] auto ["col4-start"] 50'ux ["five"] 40'ux ["end"]
    
    parseGridTemplateColumns gt2:
      ["first"] 40'ux
      ["second", "line2"] 50'pp
      ["line3"] auto
      ["col4-start"] 50'ux
      ["five"] 40'ux
      ["end"]
  
    parseGridTemplateColumns gt3, ["first"] 40'ux ["second", "line2"] 50'pp ["line3"] \
      auto ["col4-start"] 50'ux ["five"] 40'ux \
      ["end"]
    
    for (c1, c2) in zip(gt1.lines[dcol], gt2.lines[dcol]):
      check c1 == c2
    for (c1, c3) in zip(gt1.lines[dcol], gt3.lines[dcol]):
      check c1 == c3
    
    expandMacros:
      let nm = ss"first"
      echo "NM: ", $nm

  test "simple macros":
    let ns = !@["a", "b"]
    echo "ns: ", $ns
    var gt1 = newGridTemplate()
    gridTemplate gt1, dcol, {!@["first"]: 40'ux, !@["second", "line2"]: 50'pp, !@["line3"]:
      csAuto(), !@["col4-start"]: 50'ux, !@["five"]: 40'ux,
      !@["end"]: csEnd()}
    
    echo "gt1: ", $gt1
    
  test "initial macros":
    proc checkColumns(gt: GridTemplate, dir: GridDir) =
      check gt.lines[dir][0].track.kind == UiValue
      check gt.lines[dir][0].track.value.kind == UiFixed
      check gt.lines[dir][0].track.value.coord == 40.0.UiScalar
      check gt.lines[dir][0].aliases == toLineNames("first")

      check gt.lines[dir][1].track.kind == UiValue
      check gt.lines[dir][1].track.value.kind == UiPerc
      check gt.lines[dir][1].track.value.perc == 50.0.UiScalar
      check gt.lines[dir][1].aliases == toLineNames("second", "line2")

      check gt.lines[dir][2].track.kind == UiAuto
      check gt.lines[dir][2].aliases == toLineNames("line3")

      check gt.lines[dir][3].track.kind == UiValue
      check gt.lines[dir][3].track.value.kind == UiFixed
      check gt.lines[dir][3].track.value.coord == 50.0.UiScalar
      check gt.lines[dir][3].aliases == toLineNames("col4-start")

      check gt.lines[dir][4].track.kind == UiValue
      check gt.lines[dir][4].track.value.kind == UiFixed
      check gt.lines[dir][4].track.value.coord == 40.0.UiScalar
      check gt.lines[dir][4].aliases == toLineNames("five")

      check gt.lines[dir][5].track.kind == UiEnd
      check gt.lines[dir][5].aliases == toLineNames("end")
    
    # checks
    var gt1: GridTemplate
    parseGridTemplateColumns gt1, ["first"] 40'ux ["second", "line2"] 50'pp ["line3"] auto ["col4-start"] 50'ux ["five"] 40'ux ["end"]
    gt1.checkColumns(dcol)
    # checks
    var gt2 = newGridTemplate()
    parseGridTemplateRows gt2, ["first"] 40'ux ["second", "line2"] 50'pp ["line3"] auto ["col4-start"] 50'ux ["five"] 40'ux ["end"]
    gt2.checkColumns(drow)

  test "columns ":
    let ns = !@["a", "b"]
    echo "ns: ", $ns
    var gt1 = newGridTemplate()
    gridTemplate gt1, dcol, {!@["first"]: 40'ux, !@["second", "line2"]: 50'pp, !@["line3"]:
      csAuto(), !@["col4-start"]: 50'ux, !@["five"]: 40'ux,
      !@["end"]: csEnd()}
    
    echo "gt1: ", $gt1

    # ==== item e ====
    var iteme = newGridItem()
    iteme.column = 5 // 6
    iteme.row = 1 // 3
    check iteme.column.a.line.ints == 5
    check iteme.column.b.line.ints == 6
    check iteme.column.b.isSpan == false

    iteme.column = 1 // span 4
    iteme.row = 1 // span 3
    check iteme.column.a.line.ints == 1
    check iteme.column.b.line.ints == 4
    check iteme.column.b.isSpan == true

    iteme.column = "first" // span "second"
    iteme.row = 1 // "second"
    check iteme.column.a.line.ints == 500153084262
    check iteme.column.b.line.ints == 110425477965171
    check iteme.column.b.isSpan == true
    check iteme.row.a.line.ints == 1
    check iteme.row.b.line.ints == 110425477965171
    check iteme.row.b.isSpan == false

  test "compute others":
    var gt: GridTemplate

    expandMacros:
      parseGridTemplateColumns gt, ["first"] 40'ux \
        ["second", "line2"] 50'ux \
        ["line3"] auto \
        ["col4-start"] 50'ux \
        ["five"] 40'ux ["end"]
      parseGridTemplateRows gt, repeat(6, 1'fr) auto ["end"]

    check gt.lines[dcol].len() == 6
    check gt.lines[drow].len() == 8
    for i in 0..5:
      check gt.lines[drow][i].track == csFrac(1.0)
    check gt.lines[drow][6].track == csAuto()
    check gt.lines[drow][7].track == csEnd()

    # check gt.getLine(dcol, ln"first").track
