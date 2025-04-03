import numberTypes, constraints, gridtypes
import basiclayout
import basiccalcs
import prettyprints

proc createEndTracks*(grid: GridTemplate) =
  ## computing grid layout
  if grid.lines[dcol].len() == 0 or
      grid.lines[dcol][^1].track.kind != UiEnd:
    grid.lines[dcol].add initGridLine(csEnd())
  if grid.lines[drow].len() == 0 or
      grid.lines[drow][^1].track.kind != UiEnd:
    grid.lines[drow].add initGridLine(csEnd())

proc findLine(index: GridIndex, lines: seq[GridLine]): int16 =
  assert index.isName == true
  for i, line in lines:
    if index.line in line.aliases:
      return int16(i+1+index.spanCnt())
  raise newException(KeyError, "couldn't find index: " & repr index)

proc getGrid(lines: seq[GridLine], idx: int): UiScalar =
  # if idx == -2: lines[idx-1].start else: lines[^1].start
  lines[idx-1].start

proc gridAutoInsert(grid: GridTemplate, dir: GridDir, idx: int, cz: UiScalar) =
  assert idx <= 1000, "max grids exceeded"
  # assert idx < 8
  
  # debugPrint "gridAutoInsert", "dir=", dir, "idx=", idx, "currLen=", grid.lines[dir].len()
  
  while idx >= grid.lines[dir].len():
    let offset = grid.lines[dir].len() - 1
    let track = grid.autos[dir]
    var ln = initGridLine(track = track, isAuto = true)
    
    # Always insert before the end track (or at the beginning if empty)
    if offset < 0 or grid.lines[dir].len() == 0:
      grid.lines[dir].add(ln)
    else:
      # Insert auto track before the end track
      grid.lines[dir].insert(ln, offset)
      
    # debugPrint "gridAutoInsert:added", "dir=", dir, "idx=", idx, "at=", offset, "currLen=", grid.lines[dir].len()

proc setSpan(grid: GridTemplate, index: GridIndex, dir: GridDir, cz: UiScalar): int16 =
  ## todo: clean this up? maybe use static bools for col vs row
  if not index.isName:
    let idx = index.line.ints - 1 + index.spanCnt()
    grid.gridAutoInsert(dir, idx, cz)
    index.line.ints.int16
  else:
    findLine(index, grid.lines[`dir`])

proc getLine*(grid: GridTemplate, dir: GridDir, index: GridIndex): var GridLine =
  ## get line (track) for GridIndex
  let idx =
    if not index.isName: index.line.ints.int16
    else: findLine(index, grid.lines[dir])
  grid.lines[dir][idx-1]

proc fixedCount*(gridItem: GridItem): range[0..4] =
  if gridItem.index[dcol].a.line.ints != 0: result.inc
  if gridItem.index[dcol].b.line.ints != 0: result.inc
  if gridItem.index[drow].a.line.ints != 0: result.inc
  if gridItem.index[drow].b.line.ints != 0: result.inc


proc setGridSpans*(
    item: GridItem,
    grid: GridTemplate,
    contentSize: UiSize
) =
  ## set grid spans for items, if needed set new auto
  ## rows or columns
  assert not item.isNil

  let lrow = grid.lines[drow].len() - 1
  let lcol = grid.lines[dcol].len() - 1

  if item.span[dcol].a == 0 or item.span[dcol].a notin 0..lcol:
    item.span[dcol].a = grid.setSpan(item.index[dcol].a, dcol, 0)
  if item.span[dcol].b == 0 or item.span[dcol].b notin 0..lcol:
    item.span[dcol].b = grid.setSpan(item.index[dcol].b, dcol, contentSize.w)

  if item.span[drow].a == 0 or item.span[drow].a notin 0..lrow:
    item.span[drow].a = grid.setSpan(item.index[drow].a, drow, 0)
  if item.span[drow].b == 0 or item.span[drow].b notin 0..lrow:
    item.span[drow].b = grid.setSpan(item.index[drow].b, drow, contentSize.h)

proc computeBox*(
    node: GridNode,
    grid: GridTemplate,
): UiBox =
  ## compute child positions inside grid
  assert not node.isNil
  assert not node.gridItem.isNil
  let contentSize = node.box.wh.UiSize
  node.gridItem.setGridSpans(grid, contentSize)

  # set columns
  template calcBoxFor(position, size, direction, alignment) =
    result.`position` = grid.lines[`direction`].getGrid(node.gridItem.span[`direction`].a)
    let spanEnd = grid.lines[`direction`].getGrid(node.gridItem.span[`direction`].b)
    let spanSize = (spanEnd - result.`position`) - grid.gaps[`direction`]
    let contentSizeInDirection = contentSize.`size` + node.bpad.wh[`direction`]
    let visibleContentSize = min(contentSizeInDirection, spanSize)
    debugPrint "calcBoxFor:", "name=", node.name, "dir=", direction, "spanEnd=", spanEnd, "spanSize=", spanSize, "visibleContentSize=", visibleContentSize, "contentSize=", contentSizeInDirection
    case `alignment`:
    of CxStretch:
      result.`size` = spanSize
    of CxCenter:
      result.`position` = (spanSize/2 - visibleContentSize/2) + result.`position`
      result.`size` = visibleContentSize
    of CxStart:
      result.`size` = visibleContentSize
    of CxEnd:
      result.`position` = spanEnd - visibleContentSize
      result.`size` = visibleContentSize

  let justify = node.gridItem.justify.get(grid.justifyItems)
  let align = node.gridItem.align.get(grid.alignItems)
  calcBoxFor(x, w, dcol, justify)
  calcBoxFor(y, h, drow, align)


proc distributeSpaceToSpannedTracks(
    grid: GridTemplate, 
    dir: GridDir, 
    child: GridNode, 
    trackSizes: var Table[int, ComputedTrackSize],
    spanCount: int
) =
  ## Distributes space needed by spanning items to multiple tracks
  let cspan = child.gridItem.span
  let start = cspan[dir].a - 1
  let ends = cspan[dir].b - 1
  
  # Calculate total span size and determine which tracks can be affected
  var 
    totalBaseSize = 0.UiScalar
    affectedTracks: seq[int]
    intrinsicMinTracks: seq[int]
    contentMaxTracks: seq[int]
  
  for i in start ..< ends:
    let track = grid.lines[dir][i].track
    
    # Skip if we're missing a track
    if i >= grid.lines[dir].len():
      continue
      
    # Add base track size
    if i in trackSizes:
      totalBaseSize += trackSizes[i].content
    
    # Categorize tracks by their sizing function
    match track:
      UiValue(value):
        # Use isIntrinsicSizing to identify intrinsic sizing functions
        if isIntrinsicSizing(value):
          case value.kind
          of UiContentMin, UiAuto:
            affectedTracks.add(i)
            intrinsicMinTracks.add(i)
          of UiContentMax, UiContentFit:
            affectedTracks.add(i)
            contentMaxTracks.add(i)
          else: discard
        # Handle flexible tracks separately
        elif value.kind == UiFrac:
          # Handle flexible tracks logic
          discard
        else: discard
      _: discard
  
  # Calculate space to distribute
  let 
    minContribution = child.bmin[dir]
    maxContribution = child.bmax[dir]
    spaceToDistributeMin = max(0.UiScalar, minContribution - totalBaseSize)
    spaceToDistributeMax = max(0.UiScalar, maxContribution - totalBaseSize)
  
  debugPrint "distributeSpaceToSpannedTracks", "child=", child.name, "dir=", dir,
            "span=", spanCount, "minContribution=", minContribution,
            "maxContribution=", maxContribution, "totalBaseSize=", totalBaseSize
  
  # Distribute minimum contribution to intrinsic min tracks first
  if spaceToDistributeMin > 0 and intrinsicMinTracks.len > 0:
    let spacePerTrack = spaceToDistributeMin / intrinsicMinTracks.len.UiScalar
    for trackIdx in intrinsicMinTracks:
      var computed = trackSizes.getOrDefault(trackIdx)
      computed.minContribution = max(computed.minContribution, computed.content + spacePerTrack)
      computed.content = max(computed.content, computed.minContribution)
      trackSizes[trackIdx] = computed
  
  # Distribute max contribution to content-max tracks
  if spaceToDistributeMax > 0 and contentMaxTracks.len > 0:
    let spacePerTrack = spaceToDistributeMax / contentMaxTracks.len.UiScalar
    for trackIdx in contentMaxTracks:
      var computed = trackSizes.getOrDefault(trackIdx)
      computed.maxContribution = max(computed.maxContribution, computed.content + spacePerTrack)
      trackSizes[trackIdx] = computed
  
  # If no appropriate tracks, distribute to all affected tracks
  if (spaceToDistributeMin > 0 and intrinsicMinTracks.len == 0) or
     (spaceToDistributeMax > 0 and contentMaxTracks.len == 0):
    if affectedTracks.len > 0:
      let 
        spacePerTrackMin = spaceToDistributeMin / affectedTracks.len.UiScalar
        spacePerTrackMax = spaceToDistributeMax / affectedTracks.len.UiScalar
      
      for trackIdx in affectedTracks:
        var computed = trackSizes.getOrDefault(trackIdx)
        computed.minContribution = max(computed.minContribution, computed.content + spacePerTrackMin)
        computed.maxContribution = max(computed.maxContribution, computed.content + spacePerTrackMax)
        computed.content = max(computed.content, computed.minContribution)
        trackSizes[trackIdx] = computed

proc collectTrackSizeContributions*(
    grid: GridTemplate,
    padding: UiBox,
    children: seq[GridNode]
): array[GridDir, Table[int, ComputedTrackSize]] =
  ## Collects min-content and max-content contributions from grid items
  
  # Find which tracks need content sizing
  var contentSized: array[GridDir, HashSet[int]]
  for dir in [dcol, drow]:
    for i in 0 ..< grid.lines[dir].len():
      let track = grid.lines[dir][i].track
      if isContentSized(track):
        contentSized[dir].incl(i)
  
  # Process each child and track
  for child in children:
    let cspan = child.gridItem.span
    for dir in [dcol, drow]:
      # Handle single-span items
      if cspan[dir].len()-1 == 1 and (cspan[dir].a-1) in contentSized[dir]:
        let trackIndex = cspan[dir].a-1
        let track = grid.lines[dir][trackIndex].track
        
        var minContribution = child.bmin[dir]
        var maxContribution = child.bmax[dir]
        
        if minContribution == UiScalar.high: minContribution = 0.UiScalar
        if minContribution == UiScalar.low: minContribution = 0.UiScalar
        if maxContribution == UiScalar.high: maxContribution = 0.UiScalar
        if maxContribution == UiScalar.low: maxContribution = 0.UiScalar
        
        # debugPrint "collectTrackSizeContributions:item", "child=", child.name, "dir=", dir, 
        #           "minContribution=", minContribution, "maxContribution=", maxContribution
        
        # Update track's computed size based on its type
        var computed = result[dir].getOrDefault(trackIndex)
        computed.minContribution = max(computed.minContribution, minContribution)
        computed.maxContribution = max(computed.maxContribution, maxContribution)
        computed.content = max(computed.content, minContribution)
        
        result[dir][trackIndex] = computed
  
  # Process spanning items following the spec algorithm:
  # First handle span=2, then span=3, etc.
  for spanCount in 2 .. 10:  # Reasonable limit
    for child in children:
      let cspan = child.gridItem.span
      for dir in [dcol, drow]:
        if cspan[dir].len()-1 == spanCount:
          # Handle items spanning multiple tracks
          distributeSpaceToSpannedTracks(grid, dir, child, result[dir], spanCount)
  
  return result

proc runGridSizingAlgorithm*(node: GridNode, grid: GridTemplate, cssVars: CssVariables) =
  ## Implementation of the Grid Sizing Algorithm as defined in css-grid-level-2.md
  ## 1. Resolve sizes of grid columns
  ## 2. Resolve sizes of grid rows
  ## 3. If min-content contributions changed, re-resolve column sizes
  ## 4. If min-content contributions changed, re-resolve row sizes
  ## 5. Align tracks according to alignment properties
  
  # Ensure end tracks exist
  grid.createEndTracks()
  
  # Cache for min/max content contributions
  var 
    contentSizes: array[GridDir, Table[int, ComputedTrackSize]]
    prevContentSizes: array[GridDir, Table[int, ComputedTrackSize]]

  # 1. Resolve sizes of grid columns
  debugPrint "GridSizingAlgorithm:resolveColumns", "container=", node.cxSize[dcol]
  contentSizes = collectTrackSizeContributions(grid, node.bpad, node.children)
  grid.trackSizingAlgorithm(dcol, contentSizes[dcol], cssVars, node)
  
  # 2. Resolve sizes of grid rows
  debugPrint "GridSizingAlgorithm:resolveRows", "container=", node.cxSize[drow]
  # Collect new contributions that might depend on column sizes
  contentSizes = collectTrackSizeContributions(grid, node.bpad, node.children)
  grid.trackSizingAlgorithm(drow, contentSizes[drow], cssVars, node)
  
  # 3. If min-content of any item changed based on row sizes, re-resolve columns (once)
  debugPrint "GridSizingAlgorithm:reResolveColumnsIfNeeded", "container=", node.cxSize[dcol]
  prevContentSizes = contentSizes
  contentSizes = collectTrackSizeContributions(grid, node.bpad, node.children)
  
  # Check if min-content contributions changed
  var columnsNeedResize = false
  for i, computedSize in contentSizes[dcol]:
    if i in prevContentSizes[dcol] and computedSize.minContribution != prevContentSizes[dcol][i].minContribution:
      columnsNeedResize = true
      break
  
  if columnsNeedResize:
    debugPrint "GridSizingAlgorithm:reResolvingColumns", "reason=contributions_changed"
    grid.trackSizingAlgorithm(dcol, contentSizes[dcol], cssVars, node)
  
  # 4. If min-content of any item changed based on column sizes, re-resolve rows (once)
  debugPrint "GridSizingAlgorithm:reResolveRowsIfNeeded", "container=", node.cxSize[drow]
  prevContentSizes = contentSizes
  contentSizes = collectTrackSizeContributions(grid, node.bpad, node.children)
  
  var rowsNeedResize = false
  for i, computedSize in contentSizes[drow]:
    if i in prevContentSizes[drow] and computedSize.minContribution != prevContentSizes[drow][i].minContribution:
      rowsNeedResize = true
      break
  
  if rowsNeedResize:
    debugPrint "GridSizingAlgorithm:reResolvingRows", "reason=contributions_changed"
    grid.trackSizingAlgorithm(drow, contentSizes[drow], cssVars, node)
  
  # 5. Align tracks according to align-content and justify-content
  # This functionality would be implemented in the track positioning logic

proc initializeTrackSizes*(
    grid: GridTemplate, 
    dir: GridDir,
    trackSizes: Table[int, ComputedTrackSize],
    cssVars: CssVariables,
    availableSpace: UiScalar,
    containerSize: UiScalar,
    node: GridNode = nil
) =
  ## Initialize each track's base size and growth limit (Step 12.4 in spec)
  ## This sets initial values before the rest of the algorithm runs
  let frameBox = node.getFrameBox().wh[dir]

  for i, gridLine in grid.lines[dir].mpairs:
    # Get the track sizing constraint
    let track = gridLine.track
    var 
      baseSize = 0.UiScalar
      growthLimit = UiScalar.high()  # Infinity initially
    
    # 1. Set initial base size based on track type
    match track:
      UiValue(value):
        baseSize = getBaseSize(grid, cssVars, i, dir, trackSizes, value, containerSize, frameBox)
      UiMin(lmin, rmin):
        # For minmax(), use min value for base size
        case lmin.kind
        of UiFrac:
          # Min with fr is treated as 0
          baseSize = 0.UiScalar
        else:
          baseSize = getBaseSize(grid, cssVars, i, dir, trackSizes, lmin, containerSize, frameBox)
      UiMax:
        # For max(), take the maximum of the two sizes
        let lhsSize = getBaseSize(grid, cssVars, i, dir, trackSizes, track.lmax)
        let rhsSize = getBaseSize(grid, cssVars, i, dir, trackSizes, track.rmax)
        baseSize = max(lhsSize, rhsSize)
      UiMinMax(lmm, rmm):
        # For minmax(), special handling according to CSS Grid spec
        if lmm.kind == UiFrac and not isContentSized(rmm):
          # If min is fr and max is a fixed value, min is treated as 0
          baseSize = 0.UiScalar
        else:
          baseSize = getBaseSize(grid, cssVars, i, dir, trackSizes, lmm, containerSize, frameBox)
          let maxSize = getBaseSize(grid, cssVars, i, dir, trackSizes, rmm, containerSize, frameBox)
          if maxSize < baseSize:
            # If max < min, max is ignored
            baseSize = baseSize
      _:
        baseSize = 0.UiScalar
    
    # 2. Set initial growth limit based on track type
    growthLimit = getTrackBaseSize(grid, cssVars, i, dir, trackSizes, frameSize=frameBox)
    match track:
      UiValue(value):
        if value.kind in {UiAuto, UiFrac}:
          growthLimit = UiScalar.high()
      UiMin(lmin, rmin):
        if rmin.kind in {UiAuto, UiFrac}:
          growthLimit = UiScalar.high()
      UiMinMax(lmm, rmm):
        if rmm.kind in {UiAuto, UiFrac}:
          growthLimit = UiScalar.high()
      _: discard
    
    # 3. Ensure growth limit is at least as large as base size
    growthLimit = max(growthLimit, baseSize)
    
    # Store the initialized values
    gridLine.baseSize = baseSize
    gridLine.growthLimit = growthLimit
    
    debugPrint "initializeTrackSizes", "dir=", dir, "track=", i, 
              "baseSize=", baseSize, "growthLimit=", growthLimit, "track=", track

proc resolveIntrinsicTrackSizes*(
    grid: GridTemplate, 
    dir: GridDir,
    trackSizes: Table[int, ComputedTrackSize],
    availableSpace: UiScalar
) =
  ## Resolve intrinsic track sizes (Step 12.5 in spec)
  ## This sets base sizes and growth limits based on the content contributions
  
  # Process all tracks with content contributions
  for i, gridLine in grid.lines[dir].mpairs:
    let track = gridLine.track
    
    # Handle different track types
    match track:
      UiValue(value):
        # Process intrinsic sizing functions (excluding fr which is handled separately)
        if value.kind == UiContentMin:
          # For content-min tracks, directly set width to content size
          if i in trackSizes:
            let contentSize = trackSizes[i].content
            gridLine.baseSize = contentSize
            gridLine.width = contentSize  # This is critical - set width directly
            gridLine.growthLimit = max(gridLine.growthLimit, contentSize)
            
            debugPrint "resolveIntrinsicTrackSizes:contentMin", "dir=", dir, "track=", i,
                      "contentSize=", contentSize, "baseSize=", gridLine.baseSize, 
                      "width=", gridLine.width, "growthLimit=", gridLine.growthLimit
        
        # Handle other intrinsic sizing functions as before
        elif isIntrinsicSizing(value) and value.kind != UiFrac:
          case value.kind
          of UiAuto:
            # Set base size to min-content contribution
            if i in trackSizes:
              let contentSize = trackSizes[i].content
              gridLine.baseSize = max(gridLine.baseSize, contentSize)
          
          of UiContentMax, UiContentFit:
            # Set base size to max-content contribution
            if i in trackSizes:
              let contentSize = trackSizes[i].content
              gridLine.baseSize = max(gridLine.baseSize, contentSize)
              gridLine.growthLimit = max(gridLine.growthLimit, contentSize)
              
              # For fit-content, clamp by the available space if specified
              if value.kind == UiContentFit:
                gridLine.baseSize = min(gridLine.baseSize, gridLine.growthLimit)
          
          else: discard
      
      UiMin(lmin, rmin):
        # For minmax(), handle intrinsic sizing in both min and max parts
        
        # Process min part for base size
        if lmin.kind == UiContentMin:
          if i in trackSizes:
            let contentSize = trackSizes[i].content
            gridLine.baseSize = max(gridLine.baseSize, contentSize)
            gridLine.width = contentSize  # Set width for content-min in minmax
        
        elif lmin.kind in {UiAuto}:
          if i in trackSizes:
            gridLine.baseSize = max(gridLine.baseSize, trackSizes[i].content)
        elif lmin.kind in {UiContentMax, UiContentFit}:
          if i in trackSizes:
            gridLine.baseSize = max(gridLine.baseSize, trackSizes[i].maxContribution)
        
        # Process max part for growth limit
        if rmin.kind in {UiContentMin, UiAuto}:
          if i in trackSizes:
            gridLine.growthLimit = max(gridLine.growthLimit, trackSizes[i].minContribution)
        elif rmin.kind in {UiContentMax, UiContentFit}:
          if i in trackSizes:
            gridLine.growthLimit = max(gridLine.growthLimit, trackSizes[i].maxContribution)
      
      _: discard
      
    # Always ensure growth limit is at least as large as base size
    gridLine.growthLimit = max(gridLine.growthLimit, gridLine.baseSize)
    
    debugPrint "resolveIntrinsicTrackSizes", "dir=", dir, "track=", i,
              "baseSize=", gridLine.baseSize, "growthLimit=", gridLine.growthLimit,
              "minContribution=", if i in trackSizes: trackSizes[i].minContribution else: 0.UiScalar, 
              "maxContribution=", if i in trackSizes: trackSizes[i].maxContribution else: 0.UiScalar

proc maximizeTracks*(
    grid: GridTemplate, 
    dir: GridDir,
    availableSpace: UiScalar
) =
  ## Maximize tracks by distributing free space (Step 12.6 in spec)
  
  # Calculate current used space
  var 
    usedSpace = 0.UiScalar
    growableTracks: seq[int]  # Track indices that can grow
    frTracks: seq[int]        # Tracks with fr units
  
  # First pass: calculate used space and identify tracks
  for i, gridLine in grid.lines[dir]:
    usedSpace += gridLine.baseSize
    
    # Identify track types
    var canGrow = true
    var hasFrUnit = false
    
    match gridLine.track:
      UiValue(value):
        if value.kind == UiFrac:
          canGrow = false
          hasFrUnit = true
        elif value.kind == UiContentMin:
          # min-content tracks should not grow beyond their content size
          canGrow = false
      UiMin(lmin, rmin):
        if rmin.kind == UiFrac:
          canGrow = false
          hasFrUnit = true
      _: discard
    
    if hasFrUnit:
      frTracks.add(i)
    elif canGrow and gridLine.baseSize < gridLine.growthLimit:
      growableTracks.add(i)
  
  # Add in gap space -- IMPORTANT: don't modify this
  # usedSpace += grid.gaps[dir] * max(0, grid.lines[dir].len() - 2).UiScalar
  
  # Calculate free space
  let freeSpace = max(0.UiScalar, availableSpace - usedSpace)
  debugPrint "maximizeTracks", "dir=", dir, "usedSpace=", usedSpace, 
            "availableSpace=", availableSpace, "freeSpace=", freeSpace, 
            "growableTracks=", growableTracks.len, "frTracks=", frTracks.len
  
  # If we have fr tracks, don't distribute free space here - that happens in expandFlexibleTracks
  if frTracks.len > 0:
    debugPrint "maximizeTracks:skipping", "reason=has_fr_tracks"
    return
  
  # Distribute free space to growable tracks
  if freeSpace > 0 and growableTracks.len > 0:
    var remainingSpace = freeSpace
    var trackCount = growableTracks.len
    
    # Distribute space, freezing tracks as they reach growth limits
    while remainingSpace > 0 and trackCount > 0:
      let spacePerTrack = remainingSpace / trackCount.UiScalar
      var spaceDistributed = 0.UiScalar
      var stillGrowable = 0
      
      for i in growableTracks:
        var gridLine = addr grid.lines[dir][i]
        if gridLine.baseSize < gridLine.growthLimit:
          let growth = min(spacePerTrack, gridLine.growthLimit - gridLine.baseSize)
          gridLine.baseSize += growth
          spaceDistributed += growth
          
          if gridLine.baseSize < gridLine.growthLimit:
            stillGrowable += 1
      
      remainingSpace -= spaceDistributed
      trackCount = stillGrowable
      
      if spaceDistributed < 0.001.UiScalar:  # Break if we're not making progress
        break
      
      debugPrint "maximizeTracks:distributed", "spaceDistributed=", spaceDistributed,
                "remainingSpace=", remainingSpace, "stillGrowable=", stillGrowable

proc calculateFractionSize*(
    grid: GridTemplate,
    dir: GridDir,
    tracks: seq[tuple[index: int, factor: UiScalar]],
    spaceToFill: UiScalar,
    nonFlexSpace: UiScalar
): UiScalar =
  ## Find the size of an fr unit (implements step 12.7.1 in the CSS Grid spec)
  
  # Step 1: Calculate leftover space after non-flexible tracks
  let leftoverSpace = max(0.UiScalar, spaceToFill - nonFlexSpace)
  debugPrint "calculateFractionSize:leftoverSpace", "dir=", dir, "leftoverSpace=", leftoverSpace, "spaceToFill=", spaceToFill, "nonFlexSpace=", nonFlexSpace
  
  # Step 2: Calculate sum of flex factors
  var flexFactorSum = 0.0.UiScalar
  for (_, factor) in tracks:
    flexFactorSum += factor
  
  # Ensure flex factor sum is at least 1
  flexFactorSum = max(1.0.UiScalar, flexFactorSum)
  
  # Step 3: Calculate hypothetical fr size
  let hypotheticalFrSize = leftoverSpace / flexFactorSum
  
  # Step 4: Check if any track would get less than its base size
  var inflexibleTracks: seq[int] = @[]
  
  for (trackIdx, factor) in tracks:
    if hypotheticalFrSize * factor < grid.lines[dir][trackIdx].baseSize:
      # Track would get less than its base size
      inflexibleTracks.add(trackIdx)
  
  # If any tracks would get less than base size, restart algorithm treating them as inflexible
  if inflexibleTracks.len > 0:
    debugPrint "calculateFractionSize:restart", "dir=", dir, 
              "inflexibleTracks=", inflexibleTracks.len
    
    # Create new set of flexible tracks excluding the inflexible ones
    var 
      newTracks: seq[tuple[index: int, factor: UiScalar]] = @[]
      newNonFlexSpace = nonFlexSpace
    
    for (trackIdx, factor) in tracks:
      if trackIdx in inflexibleTracks:
        # Add this track's base size to non-flexible space
        newNonFlexSpace += grid.lines[dir][trackIdx].baseSize
      else:
        # Keep this track as flexible
        newTracks.add((index: trackIdx, factor: factor))
    
    # Restart with new tracks
    return calculateFractionSize(grid, dir, newTracks, spaceToFill, newNonFlexSpace)
  
  # Step 5: Return final fr size
  return hypotheticalFrSize

proc expandFlexibleTracks*(
    grid: GridTemplate, 
    dir: GridDir,
    availableSpace: UiScalar,
    node: GridNode = nil
) =
  ## Expand flexible tracks using fr units (implements step 12.7 in the CSS Grid spec)
  
  # Step 1: Find all flexible tracks (tracks with fr units)
  var flexibleTracks: seq[tuple[index: int, factor: UiScalar]] = @[]
  var nonFlexibleSpace = 0.0.UiScalar
  
  for i, track in grid.lines[dir].mpairs:
    if isFrac(track.track):
      flexibleTracks.add((index: i, factor: track.track.getFrac()))
    else:
      nonFlexibleSpace += track.baseSize
  
  # Add gap space
  nonFlexibleSpace += grid.gaps[dir] * (grid.lines[dir].len() - 2).UiScalar
  
  # Calculate remaining space for flexible tracks
  let freeSpace = max(0.UiScalar, availableSpace - nonFlexibleSpace)
  
  # If no flexible tracks, we're done
  if flexibleTracks.len == 0:
    return
  
  # Step 2: Calculate sum of flex factors (needed for later comparison)
  var flexFactorSum = 0.0.UiScalar
  for (_, factor) in flexibleTracks:
    flexFactorSum += factor
  
  # Ensure flex factor sum is at least 1
  flexFactorSum = max(1.0.UiScalar, flexFactorSum)
  
  # Step 3: Determine the used flex fraction (size of 1fr)
  let usedFlexFraction = calculateFractionSize(grid, dir, flexibleTracks, availableSpace, nonFlexibleSpace)
  debugPrint "expandFlexibleTracks:", "dir=", dir, "usedFlexFraction=", usedFlexFraction, "availableSpace=", availableSpace, "nonFlexibleSpace=", nonFlexibleSpace
  
  # Step 4: Check if using this flex fraction would violate container constraints
  var containerMinSize = 0.0.UiScalar
  
  if node != nil and node.cxMin[dir].kind != UiNone:
    # Get minimum size from node constraint if available - provide content size of 0
    containerMinSize = getMinSize(node.cxMin[dir], 0.0.UiScalar)
  
  if grid.lines[dir].len() > 0:
    let lastTrackIndex = grid.lines[dir].len() - 1
    let lastTrack = grid.lines[dir][lastTrackIndex]
    let gridMinSize = lastTrack.start + lastTrack.width
    containerMinSize = max(containerMinSize, gridMinSize)
  
  # Apply the sizing
  if containerMinSize > 0 and usedFlexFraction * flexFactorSum < containerMinSize:
    # Recalculate using container's min size
    let recalculatedUsedFlexFraction = calculateFractionSize(
        grid, dir, flexibleTracks, containerMinSize, nonFlexibleSpace)
    
    # Apply to tracks
    for (trackIndex, flexFactor) in flexibleTracks:
      let newSize = recalculatedUsedFlexFraction * flexFactor
      if newSize > grid.lines[dir][trackIndex].baseSize:
        grid.lines[dir][trackIndex].baseSize = newSize
  else:
    # Apply regular flexible sizing
    for (trackIndex, flexFactor) in flexibleTracks:
      let newSize = usedFlexFraction * flexFactor
      if newSize > grid.lines[dir][trackIndex].baseSize:
        grid.lines[dir][trackIndex].baseSize = newSize

proc expandStretchedAutoTracks*(
    grid: GridTemplate, 
    dir: GridDir,
    availableSpace: UiScalar
) =
  ## Expand auto tracks when align/justify-content is normal/stretch (Step 12.8 in spec)
  
  # Check if content distribution is stretch or normal
  # In this implementation we'll assume it's always one of those
  # A proper implementation would check grid's alignContent/justifyContent
  
  # Calculate current used space
  var 
    usedSpace = 0.UiScalar
    autoTracks: seq[int]
  
  for i, gridLine in grid.lines[dir]:
    usedSpace += gridLine.baseSize
    
    match gridLine.track:
      UiValue(value):
        if value.kind == UiAuto:
          autoTracks.add(i)
      _: discard
  
  # Add in gap space
  if grid.lines[dir].len() > 1:
    usedSpace += grid.gaps[dir] * (grid.lines[dir].len() - 1).UiScalar
  
  # Calculate remaining space
  let remainingSpace = max(0.UiScalar, availableSpace - usedSpace)
  
  if remainingSpace > 0 and autoTracks.len() > 0:
    let spacePerTrack = remainingSpace / autoTracks.len().UiScalar
    
    for i in autoTracks:
      grid.lines[dir][i].baseSize += spacePerTrack
      grid.lines[dir][i].width = grid.lines[dir][i].baseSize  # Update width
    
    debugPrint "expandStretchedAutoTracks", "dir=", dir, "remainingSpace=", remainingSpace, 
              "autoTracks=", autoTracks.len, "spacePerTrack=", spacePerTrack

proc computeTrackPositions*(grid: GridTemplate, dir: GridDir) =
  ## Calculate final positions of tracks
  var cursor = 0.0.UiScalar
  
  # Skip end track if it exists
  let trackCount = if grid.lines[dir].len() > 0 and grid.lines[dir][^1].track.kind == UiEnd: 
                     grid.lines[dir].len() - 1 
                   else: 
                     grid.lines[dir].len()
  
  # First pass: set positions and ensure width equals baseSize
  for i in 0 ..< trackCount:
    var gridLine = addr grid.lines[dir][i]
    gridLine.start = cursor
    gridLine.width = gridLine.baseSize  # Use final base size as width
    
    # Move cursor for next track
    cursor += gridLine.width
    
    # Add gap after all tracks except the last one
    if i < trackCount - 1:
      cursor += grid.gaps[dir]
    
    # debugPrint "computeTrackPositions:track", "dir=", dir, "i=", i, 
    #            "start=", gridLine.start, "width=", gridLine.width, 
    #            "cursor=", cursor


  # Update the end track position if it exists
  if grid.lines[dir].len() > 0 and grid.lines[dir][^1].track.kind == UiEnd:
    grid.lines[dir][^1].start = cursor
    grid.lines[dir][^1].width = 0.0.UiScalar

  debugPrint "computeTrackPositions:done", "dir=", dir, "cursor=", cursor

proc calculateContainerSize*(node: GridNode, dir: GridDir): UiScalar =
  ## Calculate the effective container size taking into account
  ## constraints (cxSize, cxMin, cxMax) according to CSS Grid spec
  
  let parentSize = node.getParentBoxOrWindows().box.wh[dir]
  let sizeConstraint = node.cxSize[dir]
  
  # Start with initial container size
  var containerSize: UiScalar = 0.UiScalar
  
  # NEW CODE: Auto-sized grid containers should fill parent width
  # This happens at the CSS box model level, before grid sizing
  if sizeConstraint.isAuto() and parentSize > 0 and dir == dcol:
    # Auto-width block containers fill their parent width
    containerSize = parentSize
    debugPrint "calculateContainerSize:auto_fills_parent", "dir=", dir, "parentSize=", parentSize
  # Then continue with existing logic...
  elif sizeConstraint.isFixed():
    containerSize = sizeConstraint.getFixedSize(parentSize, node.bmin[dir])
    debugPrint "calculateContainerSize:fixed", "dir=", dir, "containerSize=", containerSize
  elif sizeConstraint.isFrac():
    # For fractional units, use content-based size initially
    containerSize = node.gridTemplate.overflowSizes[dir]
    debugPrint "calculateContainerSize:frac", "dir=", dir, "containerSize=", containerSize, "overflowSizes=", node.gridTemplate.overflowSizes[dir]
  elif sizeConstraint.isAuto():
    # For auto, use content-based size
    containerSize = node.gridTemplate.overflowSizes[dir]
    debugPrint "calculateContainerSize:auto", "dir=", dir, "containerSize=", containerSize, "overflowSizes=", node.gridTemplate.overflowSizes[dir]
  elif sizeConstraint.kind == UiValue:
    # Handle content-based sizing
    debugPrint "calculateContainerSize:value", "dir=", dir, "containerSize=", containerSize, "overflowSizes=", node.gridTemplate.overflowSizes[dir]
    case sizeConstraint.value.kind:
    of UiContentMin:
      # For min-content, use the minimum contributions
      containerSize = min(node.bmin[dir], 0.UiScalar)
      debugPrint "calculateContainerSize:contentMin", "dir=", dir, "containerSize=", containerSize
    of UiContentMax, UiContentFit:
      # For max-content/fit-content, use content-based sizing
      containerSize = node.gridTemplate.overflowSizes[dir]
      debugPrint "calculateContainerSize:contentMax", "dir=", dir, "containerSize=", containerSize
    else:
      # Any other unhandled value types
      containerSize = node.gridTemplate.overflowSizes[dir]
      debugPrint "calculateContainerSize:contentMax", "dir=", dir, "containerSize=", containerSize
  else:
    # Default for compound constraints or other cases
    containerSize = 0.UiScalar
  debugPrint "calculateContainerSize:initial", "dir=", dir, "containerSize=", containerSize, "overflowSizes=", node.gridTemplate.overflowSizes[dir], "bmin=", node.bmin[dir], "bmax=", node.bmax[dir]
  
  # Apply min constraint if applicable (using getFixedSize)
  let minSize = node.cxMin[dir].getFixedSize(parentSize, node.bmin[dir])
  if minSize > 0:
    containerSize = max(containerSize, minSize)
  debugPrint "calculateContainerSize:before", "dir=", dir, "containerSize=", containerSize, "minSize=", minSize
  
  # Apply max constraint if applicable (using getFixedSize)
  let maxSize = node.cxMax[dir].getFixedSize(parentSize, node.bmax[dir])
  if maxSize > 0:  # Only apply non-zero max constraints
    containerSize = min(containerSize, maxSize)
  debugPrint "calculateContainerSize:before", "dir=", dir, "containerSize=", containerSize, "maxSize=", maxSize

  # Check for any fractional tracks + indefinite container size
  var hasAnyFractionalTrack = false
  for i, line in node.gridTemplate.lines[dir]:
    if line.track.kind != UiEnd and line.track.isFrac():
      hasAnyFractionalTrack = true
      break

  debugPrint "calculateContainerSize:hasAnyFractionalTrack", "dir=", dir, "hasAnyFractionalTrack=", hasAnyFractionalTrack, "containerSize=", containerSize

  if hasAnyFractionalTrack and containerSize == 0.UiScalar:
    # Find maximum content requirement across all items in fr tracks
    var maxContentRequirement = 0.UiScalar
    
    for child in node.children:
      if child.gridItem != nil:
        # Check if this child is in any fr track
        var childInFrTrack = false
        for i, line in node.gridTemplate.lines[dir]:
          if line.track.kind != UiEnd and line.track.isFrac() and
             child.gridItem.span[dir].a <= i+1 and child.gridItem.span[dir].b > i+1:
            childInFrTrack = true
            break
        
        if childInFrTrack:
          maxContentRequirement = max(maxContentRequirement, child.bmin[dir])
    
    # If any item in a fr track needs more space, use that as container size
    if maxContentRequirement > 0.UiScalar:
      containerSize = maxContentRequirement * UiScalar(node.gridTemplate.lines[dir].len - 1)
    debugPrint "calculateContainerSize:maxContentRequirement", "dir=", dir, "maxContentRequirement=", maxContentRequirement, "containerSize=", containerSize
  
  debugPrint "calculateContainerSize:done", "dir=", dir, "containerSize=", containerSize
  return containerSize

proc trackSizingAlgorithm*(
    grid: GridTemplate,
    dir: GridDir, 
    trackSizes: Table[int, ComputedTrackSize],
    cssVars: CssVariables,
    node: GridNode 
) =
  ## Track sizing algorithm as defined in Section 12.3 of the spec
  
  # Calculate available space using our container size calculation
  let frameSize = node.getFrameBox().wh[dir]
  let containerSize = calculateContainerSize(node, dir)
  var availableSpace = containerSize
  debugPrint "trackSizingAlgorithm:availableSpace", "dir=", dir, "availableSpace=", availableSpace
  
  # Subtract the space occupied by fixed tracks
  var fixedTrackSum: UiScalar = 0.UiScalar
  var hasFractionalTracks = false
  
  for i, line in grid.lines[dir]:
    if line.track.kind != UiEnd:  # Skip the end track
      let trackConstraint = line.track
      
      if trackConstraint.isFixed():
        # This is a track with a definite size
        fixedTrackSum += grid.getTrackBaseSize(cssVars, i, dir, trackSizes, frameSize=frameSize)
        debugPrint "trackSizingAlgorithm:fixedTrackSum", "dir=", dir, "i=", i, "fixedTrackSum=", fixedTrackSum
      elif trackConstraint.isFrac():
        hasFractionalTracks = true
  
  # Subtract gap space
  let gapCount = max(0, grid.lines[dir].len - 2)  # Number of gaps = tracks - 1
  let gapSpace = grid.gaps[dir] * gapCount.UiScalar
  
  availableSpace -= gapSpace
  
  debugPrint "trackSizingAlgorithm:availableSpace", "dir=", dir, "availableSpace=", availableSpace, "gapSpace=", gapSpace

  # If we have fractional tracks, adjust available space
  # Keep here?
  # if hasFractionalTracks:w
  #   # For fractional tracks, subtract space taken by non-fractional tracks
  #   availableSpace = max(0.UiScalar, availableSpace - fixedTrackSum)
  #   debugPrint "trackSizingAlgorithm:availableSpace", "dir=", dir, "availableSpace=", availableSpace

  # Step 1: Initialize track sizes with base size and growth limit
  initializeTrackSizes(grid, dir, trackSizes, cssVars, availableSpace, containerSize, node)

  # Step 2: Resolve sizes of intrinsic tracks (min-content/max-content)
  resolveIntrinsicTrackSizes(grid, dir, trackSizes, availableSpace)

  # Step 3: Maximize tracks by distributing free space to growable tracks
  maximizeTracks(grid, dir, availableSpace)

  # Step 4: Expand flexible tracks (with fr units)
  expandFlexibleTracks(grid, dir, availableSpace, node)

  # Step 5: Expand auto tracks if necessary when content alignment is stretch
  expandStretchedAutoTracks(grid, dir, availableSpace)

  # Step 6: Calculate final positions of tracks
  computeTrackPositions(grid, dir)

  # Debug output to show final track sizes
  debugPrint "trackSizingAlgorithm:final", "dir=", dir, "availableSpace=", availableSpace, "tracks=", grid.lines[dir].len


# Add computeAutoFlow function here (copied from layout.nim to make sure it's available)
proc computeAutoFlow(
    gridTemplate: GridTemplate,
    node: UiBox,
    allNodes: seq[GridNode],
) =
  let (mx, my) =
    if gridTemplate.autoFlow in [grRow, grRowDense]:
      (dcol, drow)
    elif gridTemplate.autoFlow in [grColumn, grColumnDense]:
      (drow, dcol)
    else:
      raise newException(ValueError, "unhandled case")

  proc `in`(cur: array[GridDir, LinePos], cache: HashSet[GridSpan]): bool =
    for span in cache:
      if cur[mx] in span[mx] and cur[my] in span[my]:
        return true

  # setup caches
  var autos = newSeqOfCap[GridNode](allNodes.len())
  var fixedCache = newTable[LinePos, HashSet[GridSpan]]()
  for i in 1..gridTemplate.lines[my].len()+1:
    fixedCache[i.LinePos] = initHashSet[GridSpan]()

  # populate caches
  for child in allNodes:
    if child.gridItem == nil:
      child.gridItem = GridItem()
  for child in allNodes:
    if fixedCount(child.gridItem) == 4:
      var span = child.gridItem.span
      span[mx].b.dec
      let rng = child.gridItem.span[my]
      for j in rng.a ..< rng.b:
        fixedCache.mgetOrPut(j, initHashSet[GridSpan]()).incl span
    else:
      autos.add child

  var cursor: array[GridDir, LinePos] = [1.LinePos, 1.LinePos]
  var i = 0
  var foundOverflow = false

  # Pre-insert auto tracks if needed to ensure we have enough
  proc ensureTracksExist(dir: GridDir, pos: LinePos) =
    # Make sure we have at least pos tracks in the given direction
    # This ensures we never run out of tracks during auto-placement
    let currentCount = gridTemplate.lines[dir].len() - 1
    if pos.int > currentCount:
      for _ in currentCount+1 .. pos.int:
        let autoTrack = gridTemplate.autos[dir]
        var newLine = initGridLine(track = autoTrack, isAuto = true)
        # Insert before the end track
        gridTemplate.lines[dir].insert(newLine, max(gridTemplate.lines[dir].len() - 1, 0))
        # debugPrint "ensureTracksExist:inserted", "dir=", dir, "pos=", pos, "currentCount=", currentCount

  template incrCursor(amt, blk, outer: untyped) =
    ## increment major index
    cursor[mx].inc
    ## increment minor when at end of major
    if cursor[mx] >= gridTemplate.lines[mx].len():
      cursor[mx] = 1.LinePos
      cursor[my] = cursor[my] + 1
      
      # Check if we need more tracks in the minor axis - this is the key fix
      if cursor[my] >= gridTemplate.lines[my].len():
        # Instead of just setting foundOverflow, actually create the new track
        ensureTracksExist(my, cursor[my])
        # debugPrint "computeAutoFlow:overflow:created_track", "my=", my, "cursor=", cursor
      
      break blk
  
  ## computing auto flows
  block autoflow:
    ## this format is complicated but is used to try and keep
    ## the algorithm as O(N) as possible by iterating directly
    ## through the indexes
    while i < len(autos):
      block childBlock:
        ## increment cursor and index until one breaks the mold
        
        # Ensure we have enough tracks for both directions
        ensureTracksExist(mx, cursor[mx])
        ensureTracksExist(my, cursor[my])
        
        while cursor[my] in fixedCache and cursor in fixedCache[cursor[my]]:
          incrCursor(1, childBlock, autoFlow)
        while cursor[my] notin fixedCache or not (cursor in fixedCache[cursor[my]]):
          # debugPrint "computeAutoFlow:setting", "node=", (autos[i]).name, "mx=", repr mx, "my=", repr my, "cursor=", repr cursor
          
          # Ensure tracks exist before setting the index
          ensureTracksExist(mx, cursor[mx])
          ensureTracksExist(my, cursor[my])
          
          # set the index for each auto rather than the span directly
          # so that auto-flow works properly
          autos[i].gridItem.index[mx].a = mkIndex(cursor[mx].int)
          autos[i].gridItem.index[mx].b = mkIndex((cursor[mx]+1).int)
          autos[i].gridItem.index[my].a = mkIndex(cursor[my].int)
          autos[i].gridItem.index[my].b = mkIndex((cursor[my]+1).int)
          i.inc
          if i >= autos.len():
            break autoflow
          incrCursor(1, childBlock, autoFlow)

  # Always update spans for auto items to ensure they have the correct positioning
  for child in autos:
    child.gridItem.setGridSpans(gridTemplate, child.box.wh.UiSize)

# Add a function to compute the overflow sizes correctly
proc computeOverflowSizes*(node: GridNode) =
  # Calculate overflow sizes based on the final positions and widths of tracks
  let grid = node.gridTemplate
  for dir in [dcol, drow]:
    if grid.lines[dir].len() > 0:
      let lastTrackIndex = grid.lines[dir].len() - 1
      let lastTrack = grid.lines[dir][lastTrackIndex]
      grid.overflowSizes[dir] = lastTrack.start + lastTrack.width

# Grid Layout Algorithm implementation following CSS Grid Level 2 spec
proc runGridLayoutAlgorithm*(node: GridNode, cssVars: CssVariables) =
  ## Implementation of the grid layout algorithm as defined in css-grid-level-2.md
  ## 1. Run the Grid Item Placement Algorithm
  ## 2. Find the size of the grid container
  ## 3. Run the Grid Sizing Algorithm
  ## 4. Lay out the grid items
  
  assert not node.gridTemplate.isNil
  
  let gridTemplate = node.gridTemplate
  for gridLine in gridTemplate.lines[dcol].mitems():
    gridLine.start = 0.UiScalar
    gridLine.width = 0.UiScalar
  for gridLine in gridTemplate.lines[drow].mitems():
    gridLine.start = 0.UiScalar
    gridLine.width = 0.UiScalar
  gridTemplate.overflowSizes = [0.UiScalar, 0.UiScalar]

  # 1. Run the Grid Item Placement Algorithm
  
  # 1a. First, handle auto flow items - this is what was missing
  # Check if there are any items that need auto flow
  var hasAutos = false
  for child in node.children:
    if child.gridItem == nil:
      child.gridItem = GridItem()
    child.gridItem.setGridSpans(gridTemplate, child.box.wh.UiSize)

    # If this item doesn't have all positions set, we need auto flow
    if fixedCount(child.gridItem) != 4:
      hasAutos = true
  
  # Run auto flow placement if needed
  if hasAutos:
    debugPrint "runGridLayoutAlgorithm:computeAutoFlow"
    computeAutoFlow(gridTemplate, node.box, node.children)

  # 1b. Now set final spans with the positions
  for child in node.children:
    child.gridItem.setGridSpans(gridTemplate, child.box.wh.UiSize)
  
  # 2. Find the size of the grid container (already in node.box)
  
  # 3. Run the Grid Sizing Algorithm
  runGridSizingAlgorithm(node, node.gridTemplate, cssVars)
  
  # 3a. Compute overflow sizes based on final track positions and sizes
  computeOverflowSizes(node)
  
  # Debug output
  prettyGridTemplate(gridTemplate)
  printLayout(node)

  # 4. Lay out the grid items
  for child in node.children:
    let gridBox = child.computeBox(node.gridTemplate)
    child.box = typeof(child.box)(gridBox)
    debugPrint "runGridLayoutAlgorithm:layout_item", "child=", child.name, "box=", child.box

proc computeNodeLayout*(gridTemplate: GridTemplate, node: GridNode, cssVars: CssVariables): auto =

  gridTemplate.createEndTracks()
  
  # Run the full grid layout algorithm
  runGridLayoutAlgorithm(node, cssVars)
  
  # Calculate final grid size - need to add the width of the last track
  var finalWidth = 0.UiScalar
  var finalHeight = 0.UiScalar
  
  # Handle empty grid case
  # if gridTemplate.lines[dcol].len() > 0:
  #   let lastColIndex = gridTemplate.lines[dcol].len() - 1
  #   finalWidth = gridTemplate.lines[dcol][lastColIndex].start + gridTemplate.lines[dcol][lastColIndex].width
  
  # if gridTemplate.lines[drow].len() > 0:
  #   let lastRowIndex = gridTemplate.lines[drow].len() - 1
  #   finalHeight = gridTemplate.lines[drow][lastRowIndex].start + gridTemplate.lines[drow][lastRowIndex].width
  
  # If we have explicit overflow sizes, use those
  debugPrint "computeNodeLayout:finalSize:before", " finalWidth=", finalWidth, " box=", node.box.wh, " overflowSizes=", gridTemplate.overflowSizes

  if not node.cxSize[dcol].isFixed() and gridTemplate.overflowSizes[dcol] > 0:
    finalWidth = max(finalWidth, gridTemplate.overflowSizes[dcol])
  
  if not node.cxSize[drow].isFixed() and gridTemplate.overflowSizes[drow] > 0:
    finalHeight = max(finalHeight, gridTemplate.overflowSizes[drow])
  
  # Make sure we're at least the requested box size
  debugPrint "computeNodeLayout:finalSize:after", " finalWidth=", finalWidth, " box=", node.box.wh, " overflowSizes=", gridTemplate.overflowSizes

  # finalWidth = max(finalWidth, node.box.w)
  # finalHeight = max(finalHeight, node.box.h)
  
  debugPrint "computeNodeLayout:finalSize", "finalWidth=", finalWidth, "finalHeight=", finalHeight,
             "originalBox=", node.box, "lastColStart=",
             if gridTemplate.lines[dcol].len() > 0: gridTemplate.lines[dcol][^1].start else: 0.UiScalar,
             "lastColWidth=",
             if gridTemplate.lines[dcol].len() > 0: gridTemplate.lines[dcol][^1].width else: 0.UiScalar
  
  return typeof(node.box)(uiBox(
                node.box.x.float,
                node.box.y.float,
                finalWidth.float,
                finalHeight.float,
              ))

proc computeLayout*(node: GridNode, depth: int, cssVars: CssVariables, full = true) =
  ## Computes constraints and auto-layout.
  debugPrint "computeLayout", "name=", node.name, " box = ", node.box.wh.repr

  # # simple constraints
  let prev = node.box
  calcBasicConstraint(node, cssVars)
  if not full and prev == node.box:
    return

  # css grid impl
  if not node.gridTemplate.isNil:
    debugPrint "computeLayout:gridTemplate", "name=", node.name, " box = ", node.box.repr
    # compute children first, then lay them out in grid
    for n in node.children:
      computeLayout(n, depth + 1, cssVars)

    printLayout(node)
    node.box = node.gridTemplate.computeNodeLayout(node, cssVars).UiBox

    for n in node.children:
      for c in n.children:
        computeLayout(c, depth + 1, cssVars, full = false)
        # calcBasicConstraint(c)
        debugPrint "calcBasicConstraintPost: ", " n = ", c.name, " w = ", c.box.w, " h = ", c.box.h

    debugPrint "computeLayout:gridTemplate:post", "name=", node.name, " box = ", node.box.wh.repr
  else:
    for n in node.children:
      computeLayout(n, depth + 1, cssVars)

    # update childrens
    # for n in node.children:
    #   calcBasicConstraintPost(n)
    #   debugPrint "calcBasicConstraintPost: ", " n = ", n.name, " w = ", n.box.w, " h = ", n.box.h

  calcBasicConstraintPost(node, cssVars)

proc computeLayout*(node: GridNode, cssVars: CssVariables = nil) =
  computeLayout(node, 0, cssVars)
  debugPrint "COMPUTELAYOUT:done"
  # printLayout(node)
