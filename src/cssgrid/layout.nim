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
  grid.trackSizingAlgorithm(dcol, contentSizes[dcol], container.w, node)
  
  # 2. Resolve sizes of grid rows
  debugPrint "GridSizingAlgorithm:resolveRows", "container=", container
  # Collect new contributions that might depend on column sizes
  contentSizes = collectTrackSizeContributions(grid, node.bpad, node.children)
  grid.trackSizingAlgorithm(drow, contentSizes[drow], container.h, node)
  
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
    grid.trackSizingAlgorithm(dcol, contentSizes[dcol], container.w, node)
  
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
    grid.trackSizingAlgorithm(drow, contentSizes[drow], container.h, node)
  
  # 5. Align tracks according to align-content and justify-content
  # This functionality would be implemented in the track positioning logic

proc initializeTrackSizes*(
    grid: GridTemplate, 
    dir: GridDir,
    trackSizes: Table[int, ComputedTrackSize],
    availableSpace: UiScalar
) =
  ## Initialize each track's base size and growth limit (Step 12.4 in spec)
  ## This sets initial values before the rest of the algorithm runs
  for i, gridLine in grid.lines[dir].mpairs:
    # Get the track sizing constraint
    let track = gridLine.track
    var 
      baseSize = 0.UiScalar
      growthLimit = UiScalar.high()  # Infinity initially
    
    # 1. Set initial base size based on track type
    match track:
      UiValue(value):
        case value.kind
        of UiFixed:
          # Fixed tracks start at their specified size
          baseSize = value.coord
        of UiPerc:
          # Percentage tracks are based on container size
          baseSize = value.perc / 100.0.UiScalar * availableSpace
        of UiContentMin, UiAuto:
          # For intrinsic min sizing, use min-content contribution if available
          if i in trackSizes:
            baseSize = trackSizes[i].minContribution
          else:
            baseSize = 0.UiScalar
        of UiContentMax, UiContentFit:
          # For max-content sizing, also use min-content initially
          if i in trackSizes:
            baseSize = trackSizes[i].minContribution
          else:
            baseSize = 0.UiScalar
        of UiFrac:
          # Flexible tracks start at 0
          baseSize = 0.UiScalar
      UiMin(lmin, rmin):
        # For minmax(), use min value for base size
        case lmin.kind
        of UiFixed:
          baseSize = lmin.coord
        of UiPerc:
          baseSize = lmin.perc / 100.0.UiScalar * availableSpace
        of UiContentMin, UiAuto:
          # Intrinsic min sizing with content
          if i in trackSizes:
            baseSize = trackSizes[i].minContribution
          else:
            baseSize = 0.UiScalar
        of UiContentMax, UiContentFit:
          # Max content as min value
          if i in trackSizes:
            baseSize = trackSizes[i].maxContribution
          else:
            baseSize = 0.UiScalar
        of UiFrac:
          # Min with fr is treated as 0
          baseSize = 0.UiScalar
      _:
        baseSize = 0.UiScalar
    
    # 2. Set initial growth limit based on track type
    match track:
      UiValue(value):
        case value.kind
        of UiFixed:
          # Fixed tracks have fixed growth limit
          growthLimit = value.coord
        of UiPerc:
          # Percentage tracks limited by container * percentage
          growthLimit = value.perc / 100.0.UiScalar * availableSpace
        of UiContentMin:
          # min-content has min-content as growth limit
          if i in trackSizes:
            growthLimit = trackSizes[i].minContribution
          else:
            growthLimit = UiScalar.high()
        of UiContentMax, UiContentFit:
          # max-content has max-content as growth limit
          if i in trackSizes:
            growthLimit = trackSizes[i].maxContribution
          else:
            growthLimit = UiScalar.high()
        of UiAuto, UiFrac:
          # Auto and fr have infinity initially
          growthLimit = UiScalar.high()
      UiMin(lmin, rmin):
        # For minmax(), use max value for growth limit
        case rmin.kind
        of UiFixed:
          growthLimit = rmin.coord
        of UiPerc:
          growthLimit = rmin.perc / 100.0.UiScalar * availableSpace
        of UiContentMin:
          if i in trackSizes:
            growthLimit = trackSizes[i].minContribution
          else:
            growthLimit = UiScalar.high()
        of UiContentMax, UiContentFit:
          if i in trackSizes:
            growthLimit = trackSizes[i].maxContribution
          else:
            growthLimit = UiScalar.high()
        of UiAuto, UiFrac:
          # Auto and fr max values are infinity
          growthLimit = UiScalar.high()
      _:
        growthLimit = baseSize
    
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
  usedSpace += grid.gaps[dir] * max(0, grid.lines[dir].len() - 2).UiScalar
  
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

proc expandFlexibleTracks*(
    grid: GridTemplate, 
    dir: GridDir,
    availableSpace: UiScalar,
    node: GridNode = nil  # Add optional node parameter
) =
  ## Expand flexible tracks using fr units (Step 12.7 in spec)
  
  # 1. Identify all tracks with fr units and calculate their total flex factor
  var 
    flexTracks: seq[tuple[index: int, factor: UiScalar]]
    totalFlex = 0.0.UiScalar
    nonFlexSpace = 0.0.UiScalar
    largestMinTrackSize = 0.0.UiScalar
  
  # First collect all tracks with fr units and find the largest minimum size
  for i, gridLine in grid.lines[dir]:
    var isFrTrack = false
    var flexFactor = 0.0.UiScalar
    
    match gridLine.track:
      UiValue(value):
        if value.kind == UiFrac:
          isFrTrack = true
          flexFactor = value.frac
      UiMin(lmin, rmin):
        if rmin.kind == UiFrac:
          isFrTrack = true
          flexFactor = rmin.frac
      _: discard
    
    if isFrTrack:
      flexTracks.add((index: i, factor: flexFactor))
      totalFlex += flexFactor
      
      # For indefinite contexts, consider both baseSize and the minimum content contribution
      # This is the crucial change - we need to look at both baseSize and minContribution
      largestMinTrackSize = max(largestMinTrackSize, gridLine.baseSize)
    else:
      nonFlexSpace += gridLine.baseSize
  
  # If no flexible tracks, nothing to do
  if flexTracks.len() == 0:
    return

  # 2. If totalFlex is less than 1.0, set it to 1.0
  totalFlex = max(1.0.UiScalar, totalFlex)
  
  # 2. Calculate gap space
  if grid.lines[dir].len() > 1:
    nonFlexSpace += grid.gaps[dir] * (grid.lines[dir].len() - 1).UiScalar
  
  # 3. Check if dimension is indefinite using our helper
  var isIndefiniteContainer = isIndefiniteGridDimension(grid, node, dir) 
  
  var frUnitValue: UiScalar
  
  debugPrint "expandFlexibleTracks:isIndefiniteContainer", "dir=", dir, "isIndefiniteContainer=", isIndefiniteContainer
  isIndefiniteContainer = false

  if isIndefiniteContainer:
    # For auto-sized containers with fr tracks, calculate fr unit value based on 
    # the largest minimum size of any track with the same fr factor
    
    # Group tracks by their fr factor to ensure equal distribution
    var tracksByFactor = initTable[UiScalar, seq[int]]()
    var maxMinByFactor = initTable[UiScalar, UiScalar]()
    
    # For indefinite containers, we need to properly account for content sizes
    # This is where we need to look at the content contributions from grid items
    for (trackIdx, factor) in flexTracks:
      if factor notin tracksByFactor:
        tracksByFactor[factor] = @[]
        maxMinByFactor[factor] = 0.UiScalar
      
      tracksByFactor[factor].add(trackIdx)
      
      # NEW: Account for both base size and content-based minimums
      # This is critical - we need to use the minimum content contribution
      var minSize = grid.lines[dir][trackIdx].baseSize
      
      # Get the minimum content contribution for this track from grid items
      if node != nil:
        for child in node.children:
          if not child.gridItem.isNil:
            let span = child.gridItem.span[dir]
            # If this item is in this track, consider its minimum contribution
            if trackIdx >= (span.a-1) and trackIdx < (span.b-1):
              # For single-track spans, use the full contribution
              if span.b - span.a == 1:
                minSize = max(minSize, child.bmin[dir])
              else:
                # For multi-track spans, divide by the span length
                let contributionPerTrack = child.bmin[dir] / (span.b - span.a).UiScalar
                minSize = max(minSize, contributionPerTrack)
      
      # Update the max min size for this factor
      maxMinByFactor[factor] = max(maxMinByFactor[factor], minSize)
      
      # Also update the global largest min track size
      largestMinTrackSize = max(largestMinTrackSize, minSize)
    
    # Apply the sizes - all tracks with the same fr factor get the same size
    for factor, tracks in tracksByFactor:
      let minSizeForFactor = maxMinByFactor[factor]
      
      # Ensure minimum size is at least the largest contribution
      # Or proportional to the fr factor if we have a single track definition
      let sizePerTrack = if totalFlex == factor:
                           # Single track case - use the direct minimum
                           max(minSizeForFactor, largestMinTrackSize)
                         else:
                           # Multiple tracks with different fr values - distribute proportionally
                           max(minSizeForFactor, largestMinTrackSize * factor / totalFlex)
      
      for trackIdx in tracks:
        grid.lines[dir][trackIdx].baseSize = sizePerTrack
        grid.lines[dir][trackIdx].width = sizePerTrack
        
      debugPrint "expandFlexibleTracks:equalDistribution", "dir=", dir, 
                "factor=", factor, "minSize=", minSizeForFactor, 
                "sizePerTrack=", sizePerTrack, "tracks=", tracks.len
  
  else:
    # For definite container sizes, distribute space proportionally
    let leftoverSpace = max(0.UiScalar, availableSpace - nonFlexSpace)
    let effectiveTotalFlex = max(totalFlex, 1.0.UiScalar)
    frUnitValue = leftoverSpace / effectiveTotalFlex
    
    # Apply calculated sizes to all flexible tracks
    for (trackIdx, factor) in flexTracks:
      let flexSize = max(grid.lines[dir][trackIdx].baseSize, frUnitValue * factor)
      grid.lines[dir][trackIdx].baseSize = flexSize
      grid.lines[dir][trackIdx].width = flexSize
  
  debugPrint "expandFlexibleTracks", "dir=", dir, "availableSpace=", availableSpace, 
           "nonFlexSpace=", nonFlexSpace, "totalFlex=", totalFlex,
           "largestMinTrackSize=", largestMinTrackSize, 
           "isIndefiniteContainer=", isIndefiniteContainer

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
    grid.lines[dir][^1].width = 0.0.UiScalar
  
  debugPrint "computeTrackPositions:done", "dir=", dir, "cursor=", cursor

proc trackSizingAlgorithm*(
    grid: GridTemplate,
    dir: GridDir, 
    trackSizes: Table[int, ComputedTrackSize],
    availableSpace: UiScalar,
    node: GridNode = nil  # Add optional node parameter
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
  expandFlexibleTracks(grid, dir, availableSpace, node)
  
  # 5. Expand Stretched Auto Tracks
  expandStretchedAutoTracks(grid, dir, availableSpace)
  
  # Now compute final positions
  computeTrackPositions(grid, dir)
  
  # Debug output of final track sizes
  for i, gridLine in grid.lines[dir]:
    debugPrint "trackSizingAlgorithm:finalTrack", "dir=", dir, "track=", i, 
               "start=", gridLine.start, "width=", gridLine.width, "baseSize=", gridLine.baseSize

  # Add to trackSizingAlgorithm after calling expandFlexibleTracks:
  debugPrint "trackSizingAlgorithm:afterExpandingFlexibleTracks", "dir=", dir
  for i, gridLine in grid.lines[dir]:
    match gridLine.track:
      UiValue(value):
        if value.kind == UiFrac:
          debugPrint "  flexTrack", "index=", i, "factor=", value.frac, 
                    "baseSize=", gridLine.baseSize, "width=", gridLine.width
      _: discard

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

proc processUiValue*(
    value: ConstraintSize,
    i: int, 
    computedSizes: Table[int, ComputedTrackSize],
    totalAuto: var UiScalar,
    totalFracs: var UiScalar,
    length = 0.0.UiScalar,
): UiScalar =
  debugPrint "processUiValue", "trackCxValue=", value, "autoSize=", computedSizes.getOrDefault(i).content
  case value.kind
  of UiFixed:
    result = value.coord
  of UiPerc:
    result = length * value.perc / 100
  of UiFrac:
    if i in computedSizes:
      result = computedSizes[i].content
    totalFracs += value.frac
  of UiAuto:
    totalAuto += 1.0.UiScalar
    if i in computedSizes:
      result = computedSizes[i].content
  of UiContentMax, UiContentMin, UiContentFit:
    if i in computedSizes:
      result = computedSizes[i].content

proc computeLineOverflow*(
    dir: GridDir,
    lines: array[GridDir, seq[GridLine]],
    computedSizes: array[GridDir, Table[int, ComputedTrackSize]]
): UiScalar =
  let lines = lines[dir]
  let computedSizes = computedSizes[dir]

  var
    totalAuto = 0.0.UiScalar
    totalFracs = 0.0.UiScalar

  for i, grdLn in lines:
      case grdLn.track.kind:
        of UiNone:
          discard
        of UiValue:
          result += processUiValue(grdLn.track.value, i, computedSizes, totalAuto, totalFracs)
        of UiAdd, UiSub, UiMin, UiMax, UiMinMax:
          let args = cssFuncArgs(grdLn.track)
          result += computeCssFuncs(grdLn.track.kind, processUiValue(args.l, i, computedSizes, totalAuto, totalFracs), processUiValue(args.r, i, computedSizes, totalAuto, totalFracs))
        of UiEnd:
          discard

  debugPrint "computeLineOverflow:post", "dir=", dir, "overflow=", result
