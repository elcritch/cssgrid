import numberTypes, constraints, gridtypes

import prettyprints

type
  CalcKind* {.pure.} = enum
    PADXY, PADWH, XY, WH, MINSZ, MAXSZ

type
  ComputedTrackSize* = object of ComputedSize
    minContribution*: UiScalar
    maxContribution*: UiScalar

{.push stackTrace: off.}

proc getPadding*(node: GridNode): UiBox =
  if node.isNil:
    uiBox(0,0,0,0)
  else:
    node.bpad

proc parentBox*(node: GridNode): UiBox =
  let parent = node.getParent()
  if parent.isNil:
    node.getFrame()
  else:
    parent.box

proc getParentBoxOrWindows*(node: GridNode): tuple[box, padding: UiBox] =
  mixin getFrame, getFrameBox
  let parent = node.getParent()
  if parent.isNil:
    result = (box: node.getFrameBox(), padding: uiBox(0,0,0,0))
  else:
    result = (box: parent.box, padding: parent.bpad)

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


# Helper function to get base size for constraint size
proc getBaseSize*(
    grid: GridTemplate, 
    cssVars: CssVariables,
    idx: int, 
    dir: GridDir,
    trackSizes: Table[int, ComputedTrackSize],
    cs: ConstraintSize,
    containerSize: UiScalar = 0.UiScalar,
    frameSize: UiScalar = 0.UiScalar
): UiScalar =
  # Handle different constraint size types
  case cs.kind
  of UiFixed:
    return cs.coord
  of UiPerc:
    # For percentage, we'd need container size
    # Just return the percentage as pixels for now
    return cs.perc * containerSize / 100.0.UiScalar
  of UiViewPort:
    # For viewport units, similar to percentage but based on viewport
    return cs.view * frameSize / 100.0.UiScalar
  of UiFrac:
    # For fractional, use min content if available
    if idx in trackSizes:
      return trackSizes[idx].minContribution
  of UiAuto, UiContentMin:
    # For auto and min-content tracks, use min-content contribution
    if idx in trackSizes:
      return trackSizes[idx].minContribution
  of UiContentMax, UiContentFit:
    # For max-content and fit-content tracks, use max of min and max contributions
    if idx in trackSizes:
      return max(trackSizes[idx].minContribution, trackSizes[idx].maxContribution)
  of UiVariable:
    var resolvedSize: ConstraintSize
    if cssVars.lookupVariable(cs.varIdx, resolvedSize):
      return getBaseSize(grid, cssVars, idx, dir, trackSizes, resolvedSize)

proc getTrackBaseSize*(
    grid: GridTemplate, 
    cssVars: CssVariables,
    idx: int, 
    dir: GridDir,
    trackSizes: Table[int, ComputedTrackSize],
    frameSize: UiScalar
): UiScalar =
  ## Get the base size for a track based on its constraint type and content contributions
  ## According to CSS Grid spec section 12.4
  
  # Return zero for out of range indices
  if idx < 0 or idx >= grid.lines[dir].len:
    return 0.UiScalar
  
  let trackConstraint = grid.lines[dir][idx].track
  
  # Handle different constraint types
  case trackConstraint.kind
  of UiValue:
    case trackConstraint.value.kind
    of UiFixed:
      # For fixed-sized tracks, use the fixed size
      return trackConstraint.value.coord
    of UiPerc:
      # For percentage tracks, we'd need container size
      # This should be properly handled in a full implementation
      # For now, return a default size or existing base size
      if grid.lines[dir][idx].baseSize > 0:
        return grid.lines[dir][idx].baseSize
      return trackConstraint.value.perc.UiScalar  # Return percentage as pixels for now
    of UiViewPort:
      # For viewport-relative tracks, we'd need viewport size
      # This should be properly handled in a full implementation
      # For now, return a default size or existing base size
      # if grid.lines[dir][idx].baseSize > 0:
      #   return grid.lines[dir][idx].baseSize
      # return trackConstraint.value.view.UiScalar  # Return view percentage as pixels for now
      return trackConstraint.value.view * frameSize / 100.0.UiScalar
    of UiFrac:
      # For fractional tracks, use content contributions
      # to determine base size before distribution
      if idx in trackSizes:
        # Use the max of min-content and any existing base size
        return max(trackSizes[idx].minContribution, grid.lines[dir][idx].baseSize)
    of UiAuto:
      # For auto tracks, use content contributions
      if idx in trackSizes:
        let baseSize = trackSizes[idx].minContribution
        # Consider existing base size too
        if grid.lines[dir][idx].baseSize > 0:
          return max(baseSize, grid.lines[dir][idx].baseSize)
        return baseSize
    of UiContentMin:
      # For min-content, just use min contribution
      if idx in trackSizes:
        return trackSizes[idx].minContribution
    of UiContentMax:
      # For max-content, use max contribution
      if idx in trackSizes:
        return max(trackSizes[idx].minContribution, trackSizes[idx].maxContribution)
    of UiContentFit:
      # For content-fit, use max contribution (same as max-content)
      if idx in trackSizes:
        return max(trackSizes[idx].minContribution, trackSizes[idx].maxContribution)
    of UiVariable:
      var resolvedSize: ConstraintSize
      if cssVars.lookupVariable(trackConstraint.value.varIdx, resolvedSize):
        return getBaseSize(grid, cssVars, idx, dir, trackSizes, resolvedSize)
  of UiMin:
    # For min(), take the minimum of the two sizes
    let lhsSize = getBaseSize(grid, cssVars, idx, dir, trackSizes, trackConstraint.lmin)
    let rhsSize = getBaseSize(grid, cssVars, idx, dir, trackSizes, trackConstraint.rmin)
    return min(lhsSize, rhsSize)
  of UiMax:
    # For max(), take the maximum of the two sizes
    let lhsSize = getBaseSize(grid, cssVars, idx, dir, trackSizes, trackConstraint.lmax)
    let rhsSize = getBaseSize(grid, cssVars, idx, dir, trackSizes, trackConstraint.rmax)
    return max(lhsSize, rhsSize)
  of UiMinMax:
    # For minmax(), use the minimum as a floor and maximum as a ceiling
    let minSize = getBaseSize(grid, cssVars, idx, dir, trackSizes, trackConstraint.lmm)
    let maxSize = getBaseSize(grid, cssVars, idx, dir, trackSizes, trackConstraint.rmm)
    
    # Get content contribution if available
    var contentSize = 0.UiScalar
    if idx in trackSizes:
      contentSize = trackSizes[idx].minContribution
    
    # Return content size clamped between min and max
    return min(maxSize, max(minSize, contentSize))
  of UiAdd:
    # For addition, add the two sizes
    let lhsSize = getBaseSize(grid, cssVars, idx, dir, trackSizes, trackConstraint.ladd)
    let rhsSize = getBaseSize(grid, cssVars, idx, dir, trackSizes, trackConstraint.radd)
    return lhsSize + rhsSize
  of UiSub:
    # For subtraction, subtract but ensure result is not negative
    let lhsSize = getBaseSize(grid, cssVars, idx, dir, trackSizes, trackConstraint.lsub)
    let rhsSize = getBaseSize(grid, cssVars, idx, dir, trackSizes, trackConstraint.rsub)
    return max(0.UiScalar, lhsSize - rhsSize)
  of UiNone, UiEnd:
    # For none or end, return 0
    return 0.UiScalar
