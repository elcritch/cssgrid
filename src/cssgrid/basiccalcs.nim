import numberTypes, constraints, gridtypes

import prettyprints

type
  CalcKind* {.pure.} = enum
    PADXY, PADWH, XY, WH, MINSZ, MAXSZ

{.push stackTrace: off.}

proc childBMins*(node: GridNode, dir: GridDir): UiScalar =
  result = UiScalar.low()
  for child in node.children:
    result = max(result, child.bmin[dir])
  if result == UiScalar.low():
    result = 0.0.UiScalar

proc childBMaxs*(node: GridNode, dir: GridDir): UiScalar =
  result = UiScalar.low()
  for child in node.children:
    result = max(result, child.bmax[dir])
  if result == UiScalar.low():
    result = 0.0.UiScalar

proc childBMinsPost*(node: GridNode, dir: GridDir, addXY = true): UiScalar =
  # I'm not sure about this, it's sorta hacky
  # but implement min/max content for non-grid nodes...
  result = UiScalar.low()
  for child in node.children:
    let childXY = if addXY: child.box.xy[dir] else: 0.0.UiScalar
    let childScreenSize = child.box.wh[dir] + childXY
    let childScreenMin = child.bmin[dir] + childXY
    result = max(result, min(childScreenSize, childScreenMin))
    debugPrint "calcBasicPost:min-content: ", "name=", child.name, "res=", result, "childScreenSize=", childScreenSize, "childScreenMin=", childScreenMin
  debugPrint "calcBasicPost:min-content:done: ", "name=", node.name, "res=", result
  if result == UiScalar.high():
    result = 0.0.UiScalar

proc propogateCalcs*(node: GridNode, dir: GridDir, calc: CalcKind, f: var UiScalar) =
  if calc == WH and node.bmin[dir] != UiScalar.high:
    debugPrint "calcBasicCx:propogateCalcs", "name=", node.name, "dir=", dir, "calc=", calc, "val=", f, "bmin=", node.bmin[dir]
    f = max(f, node.bmin[dir])

  if calc == MINSZ and f == UiScalar.high:
    match node.cxSize[dir]:
      UiValue(value):
        match value:
          UiFixed(coord):
            f = coord
          _: discard
      _: discard
  if calc == MAXSZ and f == UiScalar.low:
    match node.cxSize[dir]:
      UiValue(value):
        match value:
          UiFixed(coord):
            f = coord
          _: discard
      _: discard
