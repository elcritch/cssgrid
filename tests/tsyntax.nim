import typetraits
import sequtils

import unittest
import cssgrid/numberTypes
import cssgrid/gridtypes
import cssgrid/layout
import cssgrid/parser

import pretty
import macros

suite "syntaxes":

  setup:
    echo "setup"

    var gt: GridTemplate

    # grid-template-columns: [first] 40px [line2] 50px [line3] auto [col4-start] 50px [five] 40px [end];
    parseGridTemplateColumns gt, ["first"] 40'ux ["second", "line2"] 50'ux ["line3"] auto ["col4-start"] 50'ux ["five"] 40'ux ["end"]
    parseGridTemplateRows gt, ["row1-start"] 25'pp ["row1-end"] 100'ux ["third-line"] auto ["last-line"]
    gt.computeTracks(uiBox(0, 0, 1000, 1000))
    # echo "grid template: ", repr gridTemplate

  template checkSpans(gridTemplate: GridTemplate, gridItem: GridItem) =
    # print gridItem
    let contentSize = uiSize(0, 0)
    gridItem.setGridSpans(gt, contentSize)

    check gridItem.index[dcol].a.line == 2.toLineName
    check gridItem.index[dcol].b == ln"five"

    check gridItem.span[dcol].a == 2
    check gridItem.span[dcol].b == 5
    check gridItem.span[drow].a == 1
    check gridItem.span[drow].b == 2

  test "getLine":
    ## mixed
    let first = gt.getLine(dcol, ln"first")
    check first.track == csFixed(40.0)

    let second = gt.getLine(dcol, ln"second")
    check second.track == csFixed(50.0)

    let line3 = gt.getLine(dcol, 3.mkIndex)
    check line3.track == csAuto()

    let five1 = gt.getLine(dcol, ln"five")
    check five1.track == csFixed(40.0)
    gt.getLine(dcol, ln"five").track = csFixed(30.0)
    let five2 = gt.getLine(dcol, ln"five")
    check five2.track == csFixed(30.0)


  test "auto span":
    ## mixed
    
    var gridItem1 = newGridItem()
    gridItem1.column = 2 // ln"five"
    gridItem1.row = "row1-start"
    checkSpans(gt, gridItem1)

  test "manual span":
    ## span
    var gridItem2 = newGridItem()
    gridItem2.column = 2 // ln"five"
    gridItem2.row = "row1-start" // span "row1-start"
    checkSpans(gt, gridItem2)