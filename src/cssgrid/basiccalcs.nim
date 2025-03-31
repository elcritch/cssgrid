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
    # debugPrint "calcBasicPost:min-content: ", "name=", child.name, "res=", result, "childScreenSize=", childScreenSize, "childScreenMin=", childScreenMin
  # debugPrint "calcBasicPost:min-content:done: ", "name=", node.name, "res=", result
  if result == UiScalar.high():
    result = 0.0.UiScalar

proc propogateCalcs*(node: GridNode, dir: GridDir, calc: CalcKind, f: var UiScalar) =
  if calc == WH and node.bmin[dir] != UiScalar.high:
    # debugPrint "calcBasicCx:propogateCalcs", "name=", node.name, "dir=", dir, "calc=", calc, "val=", f, "bmin=", node.bmin[dir]
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

proc isIndefiniteGridDimension*(grid: GridTemplate, node: GridNode, dir: GridDir): bool =
  ## Determines if a grid dimension is "indefinite" according to the CSS Grid spec.
  ## An indefinite dimension means the sizing algorithm should handle fractional units
  ## differently - they don't expand to fill available space, but rather are sized
  ## based on their content.
  ##
  ## A dimension is indefinite when:
  ## - The grid container has 'auto' size in that dimension
  ## - The grid container has content-based sizing (min-content, max-content)
  ## - The grid container uses fr units for its own sizing and isn't sized by its parent
  
  # Check node's constraint size in this direction
  let constraint = node.cxSize[dir]
  
  # Auto, content-based sizing, or fr units make a dimension indefinite
  match constraint:
    UiValue(value):
      if value.kind in {UiAuto, UiContentMin, UiContentMax, UiContentFit, UiFrac}:
        return true
    _: discard

  # If parent container doesn't provide a definite constraint, the dimension is indefinite
  # Root node without explicit size is indefinite
  if dir == drow and node.cxSize[drow].kind == UiNone:
      # Most UIs have indefinite height by default - this is represented by UiNone in this library
      return true

  # If parent has indefinite size in this direction, this direction is also indefinite
  # if not node.parent.isNil:
  #   let parentConstraint = node.getParent().cxSize[dir]
  #   match parentConstraint:
  #     UiValue(value):
  #       if value.kind in {UiAuto, UiContentMin, UiContentMax, UiContentFit}:
  #         return true
  #     _: discard

  # Check if the grid's auto template is using fr units in this direction
  # This indicates a content-sized track which should be treated as indefinite
  if grid.autos[dir].kind == UiValue and grid.autos[dir].value.kind == UiFrac:
    return true
    
  return false
