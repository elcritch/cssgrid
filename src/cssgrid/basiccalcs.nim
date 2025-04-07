import numberTypes, constraints, gridtypes
import variables
import prettyprints

# {.push stackTrace: off.}

type
  CalcKind* {.pure.} = enum
    PADXY, PADWH, XY, WH, MINSZ, MAXSZ

type
  ComputedTrackSize* = object of ComputedSize
    minContribution*: UiScalar
    maxContribution*: UiScalar


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
    if cssVars.resolveVariable(cs.varIdx, cs.funcIdx, resolvedSize):
      return getBaseSize(grid, cssVars, idx, dir, trackSizes, resolvedSize)

proc getTrackBaseSize*(
    grid: GridTemplate, 
    cssVars: CssVariables,
    idx: int, 
    dir: GridDir,
    trackSizes: Table[int, ComputedTrackSize],
    containerSize: UiScalar = 0.UiScalar,
    frameSize: UiScalar = 0.UiScalar
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
    # Use getBaseSize to handle all value types consistently
    return getBaseSize(grid, cssVars, idx, dir, trackSizes, trackConstraint.value, containerSize, frameSize)
  of UiMin:
    # For min(), take the minimum of the two sizes
    let lhsSize = getBaseSize(grid, cssVars, idx, dir, trackSizes, trackConstraint.lmin, containerSize, frameSize)
    let rhsSize = getBaseSize(grid, cssVars, idx, dir, trackSizes, trackConstraint.rmin, containerSize, frameSize)
    return min(lhsSize, rhsSize)
  of UiMax:
    # For max(), take the maximum of the two sizes
    # Make sure to pass containerSize to both sides
    let lhsSize = getBaseSize(grid, cssVars, idx, dir, trackSizes, trackConstraint.lmax, containerSize, frameSize)
    let rhsSize = getBaseSize(grid, cssVars, idx, dir, trackSizes, trackConstraint.rmax, containerSize, frameSize)
    return max(lhsSize, rhsSize)
  of UiMinMax:
    # For minmax(), use the minimum as a floor and maximum as a ceiling
    # According to CSS Grid spec:
    # 1) If min is a fr value and max is a fixed value, treat fr as 0
    # 2) If max < min, max is ignored (i.e., treat as min only)
    
    # Get the min value, treating fr as 0 if max is fixed
    let minVal = trackConstraint.lmm
    let maxVal = trackConstraint.rmm
    
    var minSize: UiScalar
    if minVal.kind == UiFrac:
      # If min is fr and max is not content-sized, min is treated as 0
      minSize = 0.UiScalar
    else:
      minSize = getBaseSize(grid, cssVars, idx, dir, trackSizes, minVal, containerSize, frameSize)
    
    let maxSize = getBaseSize(grid, cssVars, idx, dir, trackSizes, maxVal, containerSize, frameSize)
    
    # If max < min, max is ignored
    if maxSize < minSize:
      return minSize
    
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

proc getMinSize*(cs: ConstraintSize, contentSize: UiScalar = 0.UiScalar): UiScalar =
  ## Extract the minimum size from a ConstraintSize
  ## For intrinsic sizing, uses contentSize if provided
  case cs.kind
  of UiFixed:
    # Fixed sizes are their own minimum
    result = cs.coord
  of UiPerc:
    # Percentages are their own minimum
    result = cs.perc
  of UiViewPort:
    # Viewport sizes are their own minimum
    result = cs.view
  of UiFrac:
    # Flex units have a default minimum of 0
    result = 0.UiScalar
  of UiContentMin, UiAuto:
    # For min-content and auto, use provided content size
    result = contentSize
  of UiContentMax, UiContentFit:
    # For max-content and fit-content, also use content size
    result = contentSize
  of UiVariable:
    # Variables are resolved during lookup - use 0 as default min
    result = 0.UiScalar

proc getMinSize*(cs: Constraint, contentSize: UiScalar): UiScalar =
  ## Extract the minimum size from a Constraint
  ## If constraint is a compound expression like minmax(), returns appropriate minimum
  case cs.kind
  of UiNone, UiEnd:
    result = 0.UiScalar
  of UiValue:
    result = getMinSize(cs.value, contentSize)
  of UiMin:
    # For min(), take the smaller of the two minimums as the result could be the smaller
    let lmin = getMinSize(cs.lmin, contentSize)
    let rmin = getMinSize(cs.rmin, contentSize)
    result = min(lmin, rmin)
  of UiMax:
    # For max(), the minimum is the larger of the two minimums
    # since the result will always be at least the larger minimum
    let lmin = getMinSize(cs.lmax, contentSize)
    let rmin = getMinSize(cs.rmax, contentSize)
    result = max(lmin, rmin)
  of UiMinMax:
    # For minmax(), the minimum is simply the first argument
    result = getMinSize(cs.lmm, contentSize)
  of UiAdd:
    # For addition, the minimum is the sum of minimums
    result = getMinSize(cs.ladd, contentSize) + getMinSize(cs.radd, contentSize)
  of UiSub:
    # For subtraction, the minimum is the difference of minimums
    # with a floor of 0 to prevent negative sizes
    result = max(0.UiScalar, getMinSize(cs.lsub, contentSize) - getMinSize(cs.rsub, contentSize))