import unittest
import typetraits
import sequtils

import cssgrid/numberTypes
import cssgrid/gridtypes
import cssgrid/parser
import cssgrid/prettyprints

import cssgrid/layout
import pretty
import macros


template checkUiFloats(af, bf, ln, ls) =
  if abs(af.float-bf.float) >= 1.0e-3:
    checkpoint(`ln` & ":\n\tCheck failed: " & `ls` & "\n\tfield: " & astToStr(af) & " " & " value was: " & $af & " expected: " & $bf)
    fail()

suite "CSS Grid Content Sizing":
  test "content min sizing":
    var gt = newGridTemplate(
      columns = @[initGridLine(csContentMin())],
      rows = @[initGridLine(csContentMin())]
    )
    
    var computedSizes: array[GridDir, Table[int, ComputedTrackSize]] = [
      {0: ComputedTrackSize(content: 100.UiScalar)}.toTable,
      {0: ComputedTrackSize(content: 150.UiScalar)}.toTable
    ]

    gt.computeTracks(uiBox(0, 0, 50, 50), computedSizes)

    check gt.lines[dcol][0].width == 100.UiScalar
    check gt.lines[drow][0].width == 150.UiScalar

  test "auto sizing with content":
    var gt = newGridTemplate(
      columns = @[initGridLine(csAuto())],
      rows = @[initGridLine(csAuto())]
    )
    
    var computedSizes: array[GridDir, Table[int, ComputedTrackSize]] = [
      dcol: {
        0: ComputedTrackSize(content: 50.UiScalar),
      }.toTable,
      drow: {
        0: ComputedTrackSize(content: 75.UiScalar)
      }.toTable
    ]

    gt.computeTracks(uiBox(0, 0, 200, 200), computedSizes)

    # printGrid(gt, cmTerminal)
    check gt.lines[dcol][0].width == 200.UiScalar
    check gt.lines[drow][0].width == 200.UiScalar

  test "fr units with minimum content size":
    var gt = newGridTemplate(
      columns = @[initGridLine(csFrac(1)), initGridLine(csFrac(2))],
      rows = @[initGridLine(csFrac(1))]
    )
    
    var computedSizes: array[GridDir, Table[int, ComputedTrackSize]] = [
      dcol: {
        0: ComputedTrackSize(content: 50.UiScalar),
        1: ComputedTrackSize(content: 100.UiScalar)
      }.toTable,
      drow: {
        0: ComputedTrackSize(content: 75.UiScalar)
      }.toTable
    ]

    gt.computeTracks(uiBox(0, 0, 300, 200), computedSizes)

    check gt.lines[dcol][0].width == 100.UiScalar  # 1fr
    check gt.lines[dcol][1].width == 200.UiScalar  # 2fr
    check gt.lines[drow][0].width == 200.UiScalar  # 1fr

  test "mixed content sizing":
    var gt = newGridTemplate(
      columns = @[
        initGridLine(csContentMin()),
        initGridLine(csAuto()),
        initGridLine(csFrac(1))
      ]
    )
    
    var computedSizes: array[GridDir, Table[int, ComputedTrackSize]] = [
      dcol: {
        0: ComputedTrackSize(content: 50.UiScalar),
        1: ComputedTrackSize(content: 75.UiScalar),
        2: ComputedTrackSize(content: 100.UiScalar)
      }.toTable,
      drow: initTable[int, ComputedTrackSize]()
    ]

    gt.computeTracks(uiBox(0, 0, 500, 100), computedSizes)

    # TL; DR: when setting a grid template, such as using grid-template-columns,
    # auto is "greedy" for left over space except when it's used with fr units.
    # When auto is used with fr, the auto row(s)/column(s) takes up just
    # enough space to fit its content and any remaining space is given to the
    # row(s)/columns(s) defined with fr units.
    check gt.lines[dcol][0].width == 50.UiScalar   # min-content
    check gt.lines[dcol][1].width == 75.UiScalar   # auto
    check gt.lines[dcol][2].width == 375.UiScalar  # remaining space

  test "content sizing with gaps":
    var gt = newGridTemplate(
      columns = @[initGridLine(csContentMin()), initGridLine(csContentMin())],
      rows = @[initGridLine(csContentMin())]
    )
    gt.gaps[dcol] = 20.UiScalar
    
    var computedSizes: array[GridDir, Table[int, ComputedTrackSize]] = [
      dcol: {
        0: ComputedTrackSize(content: 100.UiScalar),
        1: ComputedTrackSize(content: 100.UiScalar)
      }.toTable,
      drow: {
        0: ComputedTrackSize(content: 100.UiScalar)
      }.toTable
    ]

    gt.computeTracks(uiBox(0, 0, 300, 200), computedSizes)

    check gt.lines[dcol][0].width == 100.UiScalar
    check gt.lines[dcol][1].width == 100.UiScalar
    check gt.lines[dcol][1].start == 100.UiScalar  # 100 + 20 gap

  test "auto flow with content sizing":

    var gt = newGridTemplate(
      columns = @[
        initGridLine(csAuto()),
        initGridLine(csAuto())
      ],
      rows = @[
        initGridLine(csAuto())
      ]
    )
    gt.autoFlow = grRow
    
    var computedSizes: array[GridDir, Table[int, ComputedTrackSize]] = [
      dcol: {
        0: ComputedTrackSize(content: 50.UiScalar),
        1: ComputedTrackSize(content: 100.UiScalar)
      }.toTable,
      drow: {
        0: ComputedTrackSize(content: 100.UiScalar)
      }.toTable
    ]

    gt.computeTracks(uiBox(0, 0, 200, 200), computedSizes)

    check gt.lines[dcol][0].width == 100.UiScalar
    check gt.lines[dcol][1].width == 100.UiScalar

    check gt.lines[drow][0].width == 200.UiScalar

  test "auto flow with no content sizing":
    var gt = newGridTemplate(
      columns = @[
        initGridLine(csAuto()),
        initGridLine(csAuto())
      ],
      rows = @[
        initGridLine(csAuto())
      ]
    )
    gt.autoFlow = grRow
    
    var computedSizes: array[GridDir, Table[int, ComputedTrackSize]]

    gt.computeTracks(uiBox(0, 0, 200, 200), computedSizes)

    check gt.lines[dcol][0].width == 100.UiScalar
    check gt.lines[dcol][1].width == 100.UiScalar

    check gt.lines[drow][0].width == 200.UiScalar

  test "frac flow with no content sizing":
    var gt = newGridTemplate(
      columns = @[
        initGridLine(csFrac(1.0)),
        initGridLine(csFrac(1.0)),
      ],
      rows = @[
        initGridLine(csFrac(1.0)),
      ]
    )
    gt.autoFlow = grRow
    
    var computedSizes: array[GridDir, Table[int, ComputedTrackSize]]

    gt.computeTracks(uiBox(0, 0, 200, 200), computedSizes)

    check gt.lines[dcol][0].width == 100.UiScalar
    check gt.lines[dcol][1].width == 100.UiScalar

    check gt.lines[drow][0].width == 200.UiScalar

  test "content sizing overflow":

    var gt = newGridTemplate(
      columns = @[
        initGridLine(csContentMin())
      ],
      rows = @[
        initGridLine(csContentMin())
      ]
    )
    
    var computedSizes: array[GridDir, Table[int, ComputedTrackSize]] = [
      dcol: {0: ComputedTrackSize(content: 300.UiScalar)}.toTable,
      drow: {0: ComputedTrackSize(content: 400.UiScalar)}.toTable
    ]

    gt.computeTracks(uiBox(0, 0, 200, 200), computedSizes)

    check gt.lines[dcol][0].width == 300.UiScalar  # Allows overflow
    check gt.lines[drow][0].width == 400.UiScalar  # Allows overflow

    # gt.computeTracks(uiBox(0, 0, 200, 200), computedSizes, extendOnOverflow = false)
    # check gt.lines[dcol][0].width == 200.UiScalar  # Constrained to container
    # check gt.lines[drow][0].width == 200.UiScalar  # Constrained to container

  test "minimum content sizing container smaller than minimum":
    var gt = newGridTemplate(
      columns = @[
        initGridLine(csMin(100.UiScalar, 1'fr)),
        initGridLine(csMin(150.UiScalar, 9'fr))
      ],
      rows = @[
        initGridLine(csMin(200.UiScalar, 1'fr))
      ]
    )
    
    var computedSizes: array[GridDir, Table[int, ComputedTrackSize]] = [
      dcol: {
        0: ComputedTrackSize(content: 100.UiScalar),
        1: ComputedTrackSize(content: 150.UiScalar)
      }.toTable,
      drow: {
        0: ComputedTrackSize(content: 200.UiScalar)
      }.toTable
    ]

    gt.computeTracks(uiBox(0, 0, 100, 100), computedSizes)


    # Check that minimum sizes are respected
    check gt.lines[dcol][0].width == 100.UiScalar  # First column minimum
    check gt.lines[dcol][1].width == 150.UiScalar  # Second column minimum
    check gt.lines[drow][0].width == 200.UiScalar  # Row minimum

  test "minimum content sizing container larger than minimum":
    # if true:
    #   break
    prettyPrintWriteMode = cmTerminal
    defer: prettyPrintWriteMode = cmNone

    var gt = newGridTemplate(
      columns = @[
        initGridLine(csMin(100.UiScalar, 1'fr)),
        initGridLine(csMin(150.UiScalar, 9'fr))
      ],
      rows = @[
        initGridLine(csMin(200.UiScalar, 1'fr))
      ]
    )
    

    var computedSizes: array[GridDir, Table[int, ComputedTrackSize]] = [
      dcol: {
        0: ComputedTrackSize(content: 50.UiScalar),
        1: ComputedTrackSize(content: 75.UiScalar)
      }.toTable,
      drow: {
        0: ComputedTrackSize(content: 200.UiScalar)
      }.toTable
    ]

    # Check that tracks can grow beyond minimum
    gt.computeTracks(uiBox(0, 0, 500, 500), computedSizes)
    check gt.lines[dcol][0].width == 175.UiScalar  # Grows proportionally
    check gt.lines[dcol][1].width == 325.UiScalar  # Grows proportionally
    check gt.lines[drow][0].width == 500.UiScalar  # Grows to fill container
