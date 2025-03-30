import numberTypes, constraints, gridtypes
import basiclayout
import prettyprints


type
  ComputedTrackSize* = object of ComputedSize
    minContribution*: UiScalar
    maxContribution*: UiScalar

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
        case value.kind:
        of UiContentMin, UiAuto:
          affectedTracks.add(i)
          intrinsicMinTracks.add(i)
        of UiContentMax, UiContentFit:
          affectedTracks.add(i)
          contentMaxTracks.add(i)
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
        
        debugPrint "collectTrackSizeContributions:item", "child=", child.name, "dir=", dir, 
                  "minContribution=", minContribution, "maxContribution=", maxContribution
        
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

proc runGridSizingAlgorithm*(node: GridNode, grid: GridTemplate, container: UiBox) =
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
  debugPrint "GridSizingAlgorithm:resolveColumns", "container=", container
  contentSizes = collectTrackSizeContributions(grid, node.bpad, node.children)
  grid.trackSizingAlgorithm(dcol, contentSizes[dcol], container.w)
  
  # 2. Resolve sizes of grid rows
  debugPrint "GridSizingAlgorithm:resolveRows", "container=", container
  # Collect new contributions that might depend on column sizes
  contentSizes = collectTrackSizeContributions(grid, node.bpad, node.children)
  grid.trackSizingAlgorithm(drow, contentSizes[drow], container.h)
  
  # 3. If min-content of any item changed based on row sizes, re-resolve columns (once)
  debugPrint "GridSizingAlgorithm:reResolveColumnsIfNeeded", "container=", container
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
    grid.trackSizingAlgorithm(dcol, contentSizes[dcol], container.w)
  
  # 4. If min-content of any item changed based on column sizes, re-resolve rows (once)
  debugPrint "GridSizingAlgorithm:reResolveRowsIfNeeded", "container=", container
  prevContentSizes = contentSizes
  contentSizes = collectTrackSizeContributions(grid, node.bpad, node.children)
  
  var rowsNeedResize = false
  for i, computedSize in contentSizes[drow]:
    if i in prevContentSizes[drow] and computedSize.minContribution != prevContentSizes[drow][i].minContribution:
      rowsNeedResize = true
      break
  
  if rowsNeedResize:
    debugPrint "GridSizingAlgorithm:reResolvingRows", "reason=contributions_changed"
    grid.trackSizingAlgorithm(drow, contentSizes[drow], container.h)
  
  # 5. Align tracks according to align-content and justify-content
  # This functionality would be implemented in the track positioning logic

proc initializeTrackSizes*(
    grid: GridTemplate, 
    dir: GridDir,
    trackSizes: Table[int, ComputedTrackSize],
    availableSpace: UiScalar
) =
  ## Initialize each track's base size and growth limit (Step 12.4 in spec)
  for i, gridLine in grid.lines[dir].mpairs:
    # Get the track sizing constraint
    let track = gridLine.track
    var 
      baseSize = 0.UiScalar
      growthLimit = UiScalar.high()  # Infinity initially
    
    # Set initial base size
    match track:
      UiValue(value):
        case value.kind
        of UiFixed:
          baseSize = value.coord
        of UiPerc:
          baseSize = value.perc / 100.0.UiScalar * availableSpace
        else:
          baseSize = 0.UiScalar
      _:
        baseSize = 0.UiScalar
    
    # Initialize with content size if available - this ensures min-content contributes to base size
    if i in trackSizes:
      baseSize = max(baseSize, trackSizes[i].minContribution)
    
    # Set initial growth limit
    match track:
      UiValue(value):
        case value.kind
        of UiFixed:
          growthLimit = value.coord
        of UiPerc:
          growthLimit = value.perc / 100.0.UiScalar * availableSpace
        of UiFrac:
          growthLimit = UiScalar.high()
        else:
          growthLimit = UiScalar.high()
      _:
        growthLimit = baseSize
    
    # Ensure growth limit >= base size
    growthLimit = max(growthLimit, baseSize)
    
    # Store the initialized values
    gridLine.baseSize = baseSize
    gridLine.growthLimit = growthLimit
    
    debugPrint "initializeTrackSizes", "dir=", dir, "track=", i, 
              "baseSize=", baseSize, "growthLimit=", growthLimit

proc resolveIntrinsicTrackSizes*(
    grid: GridTemplate, 
    dir: GridDir,
    trackSizes: Table[int, ComputedTrackSize],
    availableSpace: UiScalar
) =
  ## Resolve intrinsic track sizes (Step 12.5 in spec)
  
  # First set base sizes for non-spanning items
  for i, gridLine in grid.lines[dir].mpairs:
    let track = gridLine.track
    
    if i in trackSizes:
      let computed = trackSizes[i]
      
      match track:
        UiValue(value):
          case value.kind
          of UiContentMin, UiAuto:
            # Set base size to min-content contribution
            gridLine.baseSize = max(gridLine.baseSize, computed.minContribution)
          of UiContentMax, UiContentFit:
            # Set base size to max-content contribution
            gridLine.baseSize = max(gridLine.baseSize, computed.maxContribution)
            # For fit-content, clamp by the available space
            if value.kind == UiContentFit:
              gridLine.baseSize = min(gridLine.baseSize, gridLine.growthLimit)
          else: discard
        _: discard
      
      # Also update growth limits for intrinsic maximums
      match track:
        UiValue(value):
          case value.kind
          of UiContentMin:
            gridLine.growthLimit = max(gridLine.growthLimit, computed.minContribution)
          of UiContentMax:
            gridLine.growthLimit = max(gridLine.growthLimit, computed.maxContribution)
          of UiContentFit:
            # For fit-content, set limit but also respect the available space constraint
            gridLine.growthLimit = min(
              max(gridLine.growthLimit, computed.maxContribution),
              gridLine.growthLimit
            )
          else: discard
        _: discard
      
      # Ensure growth limit >= base size
      gridLine.growthLimit = max(gridLine.growthLimit, gridLine.baseSize)
  
  # Note: In the existing code, the complex handling of spanning items
  # is already implemented in distributeSpaceToSpannedTracks, which we 
  # called during collectTrackSizeContributions

proc maximizeTracks*(
    grid: GridTemplate, 
    dir: GridDir,
    availableSpace: UiScalar
) =
  ## Maximize tracks by distributing free space (Step 12.6 in spec)
  
  # Calculate current used space
  var usedSpace = 0.UiScalar
  for gridLine in grid.lines[dir]:
    usedSpace += gridLine.baseSize
  
  # Add in gap space
  if grid.lines[dir].len() > 1:
    usedSpace += grid.gaps[dir] * (grid.lines[dir].len() - 1).UiScalar
  
  # Calculate free space
  let freeSpace = max(0.UiScalar, availableSpace - usedSpace)
  debugPrint "maximizeTracks", "dir=", dir, "usedSpace=", usedSpace, 
            "availableSpace=", availableSpace, "freeSpace=", freeSpace
  
  # Distribute free space to tracks
  if freeSpace > 0:
    # Count tracks that can still grow
    var growableTracks = 0
    for gridLine in grid.lines[dir]:
      if gridLine.baseSize < gridLine.growthLimit:
        growableTracks += 1
    
    if growableTracks > 0:
      var remainingSpace = freeSpace
      var trackCount = growableTracks
      
      # Distribute space, freezing tracks as they reach growth limits
      while remainingSpace > 0 and trackCount > 0:
        let spacePerTrack = remainingSpace / trackCount.UiScalar
        var spaceDistributed = 0.UiScalar
        trackCount = 0
        
        for gridLine in grid.lines[dir].mitems:
          if gridLine.baseSize < gridLine.growthLimit:
            let growth = min(spacePerTrack, gridLine.growthLimit - gridLine.baseSize)
            gridLine.baseSize += growth
            spaceDistributed += growth
            
            if gridLine.baseSize < gridLine.growthLimit:
              trackCount += 1
        
        remainingSpace -= spaceDistributed
        if spaceDistributed < 0.001.UiScalar:  # Break if we're not making progress
          break

proc expandFlexibleTracks*(
    grid: GridTemplate, 
    dir: GridDir,
    availableSpace: UiScalar
) =
  ## Expand flexible tracks using fr units (Step 12.7 in spec)
  
  # Identify flexible tracks and calculate minimum sizes for flex tracks
  var 
    flexTracks: seq[tuple[index: int, factor: UiScalar, baseSize: UiScalar]]
    totalFlex = 0.0.UiScalar
    nonFlexSpace = 0.UiScalar
    flexMinSpace = 0.UiScalar  # Total minimum size required by flex tracks
  
  for i, gridLine in grid.lines[dir]:
    match gridLine.track:
      UiValue(value):
        if value.kind == UiFrac:
          flexTracks.add((index: i, factor: value.frac, baseSize: gridLine.baseSize))
          totalFlex += value.frac
          flexMinSpace += gridLine.baseSize  # Add the minimum content size of flex track
        else:
          nonFlexSpace += gridLine.baseSize
      _:
        nonFlexSpace += gridLine.baseSize
  
  # Add space for gaps
  if grid.lines[dir].len() > 1:
    nonFlexSpace += grid.gaps[dir] * (grid.lines[dir].len() - 1).UiScalar
  
  # Calculate free space for flex tracks AFTER accounting for minimum sizes
  let 
    totalRequiredSpace = nonFlexSpace + flexMinSpace
    freeSpace = max(0.UiScalar, availableSpace - nonFlexSpace)
    flexibleFreeSpace = max(0.UiScalar, availableSpace - totalRequiredSpace)
  
  # Log detailed information for debugging
  debugPrint "expandFlexibleTracks:sizes", "dir=", dir, "availableSpace=", availableSpace, 
    "nonFlexSpace=", nonFlexSpace, "flexMinSpace=", flexMinSpace,
    "freeSpace=", freeSpace, "flexibleFreeSpace=", flexibleFreeSpace,
    "flexTracks=", flexTracks.len
  
  if flexTracks.len() > 0:
    # If total flex is less than 1, treat it as 1
    let adjustedTotalFlex = max(totalFlex, 1.0.UiScalar)
    
    # Calculate the size per flex unit AFTER accounting for minimum sizes
    let flexUnit = if flexibleFreeSpace > 0: flexibleFreeSpace / adjustedTotalFlex else: 0.UiScalar
    
    debugPrint "expandFlexibleTracks:fr", "flexUnit=", flexUnit, "totalFlex=", totalFlex, "adjustedTotalFlex=", adjustedTotalFlex
    
    # Assign sizes to flexible tracks
    for (i, factor, baseSize) in flexTracks:
      # Calculate flexSize by multiplying flexUnit by the flex factor
      let flexSize = flexUnit * factor
      
      # The final size is the MAX of:
      # 1. Current baseSize (min-content)
      # 2. The flex size calculated based on the flex factor
      let finalSize = max(baseSize, flexSize)
      
      debugPrint "expandFlexibleTracks:track", "index=", i, "factor=", factor, 
                 "baseSize=", baseSize, "flexSize=", flexSize, "finalSize=", finalSize
      
      # Update both baseSize and width
      grid.lines[dir][i].baseSize = finalSize
      grid.lines[dir][i].width = finalSize
      
      debugPrint "expandFlexibleTracks:track:final", "index=", i, "baseSize=", grid.lines[dir][i].baseSize

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
    
    debugPrint "computeTrackPositions:track", "dir=", dir, "i=", i, 
               "start=", gridLine.start, "width=", gridLine.width, 
               "cursor=", cursor
  
  # Update the end track position if it exists
  if grid.lines[dir].len() > 0 and grid.lines[dir][^1].track.kind == UiEnd:
    grid.lines[dir][^1].start = cursor
    grid.lines[dir][^1].width = 0.UiScalar
  
  debugPrint "computeTrackPositions:done", "dir=", dir, "cursor=", cursor

proc trackSizingAlgorithm*(
    grid: GridTemplate,
    dir: GridDir, 
    trackSizes: Table[int, ComputedTrackSize],
    availableSpace: UiScalar
) =
  ## Track sizing algorithm as defined in Section 12.3 of the spec
  
  debugPrint "trackSizingAlgorithm:start", "dir=", dir, "availableSpace=", availableSpace
  
  # 1. Initialize Track Sizes
  initializeTrackSizes(grid, dir, trackSizes, availableSpace)
  
  # 2. Resolve Intrinsic Track Sizes
  resolveIntrinsicTrackSizes(grid, dir, trackSizes, availableSpace)
  
  # 3. Maximize Tracks
  maximizeTracks(grid, dir, availableSpace)
  
  # 4. Expand Flexible Tracks
  expandFlexibleTracks(grid, dir, availableSpace)
  
  # 5. Expand Stretched Auto Tracks
  expandStretchedAutoTracks(grid, dir, availableSpace)
  
  # Now compute final positions
  computeTrackPositions(grid, dir)
  
  # Debug output of final track sizes
  for i, gridLine in grid.lines[dir]:
    debugPrint "trackSizingAlgorithm:finalTrack", "dir=", dir, "track=", i, 
               "start=", gridLine.start, "width=", gridLine.width, "baseSize=", gridLine.baseSize

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
proc computeOverflowSizes*(grid: GridTemplate) =
  # Calculate overflow sizes based on the final positions and widths of tracks
  for dir in [dcol, drow]:
    if grid.lines[dir].len() > 0:
      let lastTrackIndex = grid.lines[dir].len() - 1
      let lastTrack = grid.lines[dir][lastTrackIndex]
      grid.overflowSizes[dir] = lastTrack.start + lastTrack.width
      
    debugPrint "computeOverflowSizes", "dir=", dir, "size=", grid.overflowSizes[dir]

# Grid Layout Algorithm implementation following CSS Grid Level 2 spec
proc runGridLayoutAlgorithm*(node: GridNode) =
  ## Implementation of the grid layout algorithm as defined in css-grid-level-2.md
  ## 1. Run the Grid Item Placement Algorithm
  ## 2. Find the size of the grid container
  ## 3. Run the Grid Sizing Algorithm
  ## 4. Lay out the grid items
  
  assert not node.gridTemplate.isNil
  
  # 1. Run the Grid Item Placement Algorithm
  
  # 1a. First, handle auto flow items - this is what was missing
  # Check if there are any items that need auto flow
  var hasAutos = false
  for child in node.children:
    if child.gridItem == nil:
      child.gridItem = GridItem()
    child.gridItem.setGridSpans(node.gridTemplate, child.box.wh.UiSize)
    
    # If this item doesn't have all positions set, we need auto flow
    if fixedCount(child.gridItem) != 4:
      hasAutos = true
  
  # Run auto flow placement if needed
  if hasAutos:
    debugPrint "runGridLayoutAlgorithm:computeAutoFlow"
    computeAutoFlow(node.gridTemplate, node.box, node.children)
  
  # 1b. Now set final spans with the positions
  for child in node.children:
    child.gridItem.setGridSpans(node.gridTemplate, child.box.wh.UiSize)
  
  # 2. Find the size of the grid container (already in node.box)
  
  # 3. Run the Grid Sizing Algorithm
  runGridSizingAlgorithm(node, node.gridTemplate, node.box)
  
  # 3a. Compute overflow sizes based on final track positions and sizes
  computeOverflowSizes(node.gridTemplate)
  
  # Debug output
  prettyGridTemplate(node.gridTemplate)
  printLayout(node)

  # 4. Lay out the grid items
  for child in node.children:
    let gridBox = child.computeBox(node.gridTemplate)
    child.box = typeof(child.box)(gridBox)
    debugPrint "runGridLayoutAlgorithm:layout_item", "child=", child.name, "box=", child.box

proc computeNodeLayout*(
    gridTemplate: GridTemplate,
    node: GridNode,
): auto =
  let box = node.box

  gridTemplate.createEndTracks()
  
  # Run the full grid layout algorithm
  runGridLayoutAlgorithm(node)
  
  # Calculate final grid size - need to add the width of the last track
  var finalWidth = 0.UiScalar
  var finalHeight = 0.UiScalar
  
  # Handle empty grid case
  if gridTemplate.lines[dcol].len() > 0:
    let lastColIndex = gridTemplate.lines[dcol].len() - 1
    finalWidth = gridTemplate.lines[dcol][lastColIndex].start + gridTemplate.lines[dcol][lastColIndex].width
  
  if gridTemplate.lines[drow].len() > 0:
    let lastRowIndex = gridTemplate.lines[drow].len() - 1
    finalHeight = gridTemplate.lines[drow][lastRowIndex].start + gridTemplate.lines[drow][lastRowIndex].width
  
  # If we have explicit overflow sizes, use those
  if gridTemplate.overflowSizes[dcol] > 0:
    finalWidth = max(finalWidth, gridTemplate.overflowSizes[dcol])
  
  if gridTemplate.overflowSizes[drow] > 0:
    finalHeight = max(finalHeight, gridTemplate.overflowSizes[drow])
  
  # Make sure we're at least the requested box size
  finalWidth = max(finalWidth, box.w)
  finalHeight = max(finalHeight, box.h)
  
  debugPrint "computeNodeLayout:finalSize", "finalWidth=", finalWidth, "finalHeight=", finalHeight, 
             "originalBox=", box, "lastColStart=", 
             if gridTemplate.lines[dcol].len() > 0: gridTemplate.lines[dcol][^1].start else: 0.UiScalar,
             "lastColWidth=", 
             if gridTemplate.lines[dcol].len() > 0: gridTemplate.lines[dcol][^1].width else: 0.UiScalar
  
  return typeof(box)(uiBox(
                box.x.float,
                box.y.float,
                finalWidth.float,
                finalHeight.float,
              ))

proc computeLayout*(node: GridNode, depth: int, full = true) =
  ## Computes constraints and auto-layout.
  debugPrint "computeLayout", "name=", node.name, " box = ", node.box.wh.repr

  # # simple constraints
  let prev = node.box
  calcBasicConstraint(node)
  if not full and prev == node.box:
    return

  # css grid impl
  if not node.gridTemplate.isNil:
    debugPrint "computeLayout:gridTemplate", "name=", node.name, " box = ", node.box.repr
    # compute children first, then lay them out in grid
    for n in node.children:
      computeLayout(n, depth + 1)

    printLayout(node)
    var box = node.box
    let res = node.gridTemplate.computeNodeLayout(node).UiBox
    node.box = res

    for n in node.children:
      for c in n.children:
        computeLayout(c, depth + 1, full = false)
        # calcBasicConstraint(c)
        debugPrint "calcBasicConstraintPost: ", " n = ", c.name, " w = ", c.box.w, " h = ", c.box.h

    debugPrint "computeLayout:gridTemplate:post", "name=", node.name, " box = ", node.box.wh.repr
  else:
    for n in node.children:
      computeLayout(n, depth + 1)

    # update childrens
    # for n in node.children:
    #   calcBasicConstraintPost(n)
    #   debugPrint "calcBasicConstraintPost: ", " n = ", n.name, " w = ", n.box.w, " h = ", n.box.h

  calcBasicConstraintPost(node)

proc computeLayout*(node: GridNode) =
  computeLayout(node, 0)
  debugPrint "COMPUTELAYOUT:done"
  # printLayout(node)