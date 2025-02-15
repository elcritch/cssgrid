import patty
import std/terminal
import std/tables

import numberTypes, constraints, gridtypes, parser
import basiclayout

export constraints, gridtypes

import prettyprints

type
  ComputedTrackSize* = object of ComputedSize

proc computeLineOverflow*(
    lines: var seq[GridLine],
    computedSizes: Table[int, ComputedTrackSize]
): UiScalar =
  for i, grdLn in lines:
    if grdLn.isAuto:
      match grdLn.track:
        UiValue(value):
          match value:
            UiFixed(coord):
              result += coord
            UiPerc(): discard
            UiContentMax():
              if i in computedSizes:
                result += computedSizes[i].maxContent
            UiContentMin():
              if i in computedSizes:
                result += computedSizes[i].minContent
            UiFrac(): 
              if i in computedSizes:
                result += computedSizes[i].fracMinSize
            UiAuto():
              if i in computedSizes:
                result += computedSizes[i].autoSize
        _: discard

  debugPrint "computeLineOverflow:post: ", result

proc computeLineLayout*(
    lines: var seq[GridLine],
    computedSizes: Table[int, ComputedTrackSize],  # New parameter for computed sizes
    length: UiScalar,
    spacing: UiScalar,
) =
  var
    fixed = 0.UiScalar
    totalFracs = 0.0.UiScalar
    autoTrackIndices: seq[int] = @[]  # Store indices instead of sizes
    fracTrackIndices: seq[int] = @[]  # Store indices instead of sizes

  # First pass: calculate fixed sizes and identify auto/frac tracks
  for i, grdLn in lines:
    match grdLn.track:
      UiNone():
        discard
      UiValue(value):
        match value:
          UiFixed(coord):
            fixed += coord
          UiPerc(perc):
            fixed += length * perc / 100
          UiContentMin():
            if i in computedSizes:
              fixed += computedSizes[i].minContent
          UiContentMax():
            if i in computedSizes:
              fixed += computedSizes[i].maxContent
          UiFrac(frac):
            totalFracs += frac
            fracTrackIndices.add(i)
          UiAuto():
            autoTrackIndices.add(i)
      UiEnd():
        discard
      _: discard  # Handle other cases

  # Account for spacing between tracks
  fixed += spacing * UiScalar(lines.len() - 1)

  # Calculate minimum space needed for auto and frac tracks
  var
    totalAutoMin: UiScalar
    totalFracMin: UiScalar

  for trk in autoTrackIndices:
    if trk in computedSizes:
        totalAutoMin += computedSizes[trk].autoSize

  for trk in fracTrackIndices:
    if trk in computedSizes:
        totalFracMin += computedSizes[trk].fracMinSize

  # Calculate available free space
  let
    freeSpace = max(length - fixed - totalAutoMin - totalFracMin, 0.0.UiScalar)
  var
    remSpace = freeSpace

  if fracTrackIndices.len() > 0:
    remSpace = 0.0.UiScalar

  debugPrint "computeLineLayout:metrics",
    "length=", length,
    "fixed=", fixed,
    "freeSpace=", freeSpace,
    "remSpace=", remSpace,
    "totalFracMin=", totalFracMin,
    "totalAutoMin=", totalAutoMin

  # Second pass: distribute space and set track widths
  for i, grdLn in lines.mpairs():
    if grdLn.track.kind == UiValue:
      let grdVal = grdLn.track.value
      case grdVal.kind
      of UiFixed:
        grdLn.width = grdVal.coord
      of UiPerc:
        grdLn.width = length * grdVal.perc / 100
      of UiContentMax:
        if i in computedSizes:
          grdLn.width = computedSizes[i].maxContent
      of UiContentMin:
        if i in computedSizes:
          grdLn.width = computedSizes[i].minContent
      of UiFrac:
        if totalFracs > 0:
          let minSize = if i in computedSizes: computedSizes[i].fracMinSize else: 0.UiScalar
          grdLn.width = freeSpace * grdVal.frac/totalFracs + minSize
          remSpace -= grdLn.width
      of UiAuto:
        let minSize =
          if i in computedSizes: computedSizes[i].autoSize
          else: 0.UiScalar

        let autoShare = 
          if autoTrackIndices.len > 0:
            remSpace / autoTrackIndices.len.UiScalar
          else:
            0.UiScalar
        debugPrint "computeLineLayout:auto: ", "autoshare=", autoShare, "minsize=", minsize
        grdLn.width = minSize + autoShare

  # Final pass: calculate positions
  var cursor = 0.0.UiScalar
  for grdLn in lines.mitems():
    grdLn.start = cursor
    cursor += grdLn.width + spacing

proc createEndTracks*(grid: GridTemplate) =
  ## computing grid layout
  if grid.lines[dcol].len() == 0 or
      grid.lines[dcol][^1].track.kind != UiEnd:
    grid.lines[dcol].add initGridLine(csEnd())
  if grid.lines[drow].len() == 0 or
      grid.lines[drow][^1].track.kind != UiEnd:
    grid.lines[drow].add initGridLine(csEnd())

proc computeTracks*(
    grid: GridTemplate,
    contentSize: UiBox,
    computedSizes: array[GridDir, Table[int, ComputedTrackSize]],
) =
  # The free space is calculated after any non-flexible items. In 
  prettyGridTemplate(grid)
  grid.overflowSizes[dcol] = computeLineOverflow(grid.lines[dcol], computedSizes[dcol])
  grid.overflowSizes[drow] = computeLineOverflow(grid.lines[drow], computedSizes[drow])

  var
    colLen = contentSize.w
    rowLen = contentSize.h

  colLen += grid.overflowSizes[dcol]
  rowLen += grid.overflowSizes[drow]

  # Pass computed sizes to layout
  grid.lines[dcol].computeLineLayout(
    computedSizes[dcol],
    length=colLen,
    spacing=grid.gaps[dcol]
  )
  grid.lines[drow].computeLineLayout(
    computedSizes[drow],
    length=rowLen,
    spacing=grid.gaps[drow]
  )

  prettyGridTemplate(grid)

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
  while idx >= grid.lines[dir].len():
    let offset = grid.lines[dir].len() - 1
    let track = grid.autos[dir]
    var ln = initGridLine(track = track, isAuto = true)
    grid.lines[dir].insert(ln, max(offset, 0))

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
  template calcBoxFor(f, v, dir, axis) =
    result.`f` = grid.lines[`dir`].getGrid(node.gridItem.span[`dir`].a)
    let rfw = grid.lines[`dir`].getGrid(node.gridItem.span[`dir`].b)
    let rvw = (rfw - result.`f`) - grid.gaps[`dir`]
    let cvw = min(contentSize.`v`, rvw)
    debugPrint "calcBoxFor: ", "rfw=", rfw, "rvw=", rvw, "cvw=", cvw
    case `axis`:
    of CxStretch:
      result.`v` = rvw
    of CxCenter:
      result.`f` = (rvw/2 - cvw/2) + result.`f`
      result.`v` = cvw
    of CxStart:
      result.`v` = cvw
    of CxEnd:
      result.`f` = rfw - cvw
      result.`v` = cvw

  let justify = node.gridItem.justify.get(grid.justifyItems)
  let align = node.gridItem.align.get(grid.alignItems)
  calcBoxFor(x, w, dcol, justify)
  calcBoxFor(y, h, drow, align)

proc fixedCount*(gridItem: GridItem): range[0..4] =
  if gridItem.index[dcol].a.line.ints != 0: result.inc
  if gridItem.index[dcol].b.line.ints != 0: result.inc
  if gridItem.index[drow].a.line.ints != 0: result.inc
  if gridItem.index[drow].b.line.ints != 0: result.inc

proc isAutoUiSizeed*(gridItem: GridItem): bool =
  gridItem.fixedCount() == 0

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

  template incrCursor(amt, blk, outer: untyped) =
    ## increment major index
    cursor[mx].inc
    ## increment minor when at end of major
    if cursor[mx] >= gridTemplate.lines[mx].len():
      cursor[mx] = 1.LinePos
      cursor[my] = cursor[my] + 1
      if cursor[my] >= gridTemplate.lines[my].len():
        foundOverflow = true
      break blk
  
  ## computing auto flows
  block autoflow:
    ## this format is complicated but is used to try and keep
    ## the algorithm as O(N) as possible by iterating directly
    ## through the indexes
    while i < len(autos):
      block childBlock:
        ## increment cursor and index until one breaks the mold
        while cursor[my] in fixedCache and cursor in fixedCache[cursor[my]]:
          incrCursor(1, childBlock, autoFlow)
        while cursor[my] notin fixedCache or not (cursor in fixedCache[cursor[my]]):
          # set the index for each auto rather than the span directly
          # so that auto-flow works properly
          autos[i].gridItem.index[mx] = cursor[mx] // (cursor[mx] + 1)
          autos[i].gridItem.index[my] = cursor[my] // (cursor[my] + 1)
          i.inc
          if i >= autos.len():
            break autoflow
          incrCursor(1, childBlock, autoFlow)

  if foundOverflow:
    for child in autos:
      child.gridItem.setGridSpans(gridTemplate, child.box.wh.UiSize)

proc calculateContentSize*(node: GridNode, dir: GridDir): UiScalar =
  ## Recursively calculates the content size for a node by examining its children
  
  debugPrint "calculateContentSize: ", "node=", node.name, "cxsize=", node.cxsize[dir], "cxmin=", node.cxmin[dir]
  # First check the node's own size constraints
  match node.cxSize[dir]:
    UiValue(value):
      match value:
        UiFixed(coord):
          debugPrint "FIXED!", "coord=", coord
          return coord
        _: discard
    _: discard

  match node.cxSize[dir]:
    UiValue(value):
      match value:
        UiFixed(coord):
          debugPrint "FIXED!", "coord=", coord
          result = coord
        UiContentMin():
          discard # TODO
        UiContentMax():
          discard # TODO
        _: discard
    _: discard

  # TODO: is this just LLM nonsense?
  # # Then recursively check all children
  # for child in node.children:
  #   let childSize = calculateContentSize(child, dir)
  #   maxSize = max(maxSize, childSize)
  #   # Add any additional space needed for grid gaps if parent has grid
  #   if not node.gridTemplate.isNil and node.children.len > 1:
  #     maxSize += node.gridTemplate.gaps[dir]

proc computeContentSizes*(
    grid: GridTemplate,
    children: seq[GridNode]
): array[GridDir, Table[int, ComputedTrackSize]] =
  ## Returns computed sizes for each track that needs content sizing

  # Find which tracks need content sizing
  var contentSized: array[GridDir, HashSet[int]]
  for dir in [dcol, drow]:
    for i in 0 ..< grid.lines[dir].len():
      let track = grid.lines[dir][i].track
      if isContentSized(track):
        contentSized[dir].incl(i)

  # Process each child and track
  for child in children:
    debugPrint "computeContentSizes: ", "child=", child.name
    let cspan = child.gridItem.span
    for dir in [dcol, drow]:
      if cspan[dir].len()-1 == 1 and (cspan[dir].a-1) in contentSized[dir]:
        let trackIndex = cspan[dir].a-1
        let track = grid.lines[dir][trackIndex].track
        
        # Calculate size recursively including nested children
        let contentSize = calculateContentSize(child, dir)
        
        # Update track's computed size based on its type
        var computed = result[dir].getOrDefault(trackIndex)
        debugPrint "computeContentSizes: ", "track=", track.value.kind, "contentSize=", contentSize, "computed=", computed
        case track.value.kind:
        of UiAuto:
          computed.autoSize = contentSize
        of UiFrac:
          computed.fracMinSize = contentSize
        of UiContentMin:
          computed.minContent = contentSize
        of UiContentMax:
          computed.maxContent = contentSize
        else: discard
        
        result[dir][trackIndex] = computed

proc computeNodeLayout*(
    gridTemplate: GridTemplate,
    node: GridNode,
): auto =

  let box = node.box

  gridTemplate.createEndTracks()
  ## implement full(ish) CSS grid algorithm here
  ## currently assumes that `N`, the ref object, has
  ## both `UiBox: UiBox` and `gridItem: GridItem` fields. 
  ## 
  ## this algorithm tries to follow the specification at:
  ##   https://www.w3.org/TR/css3-grid-layout/#grid-item-placement-algorithm
  ## 
  var hasAutos = true
  for child in node.children:
    if child.gridItem == nil:
      # ensure all grid children have a GridItem
      child.gridItem = GridItem()
    child.gridItem.setGridSpans(gridTemplate, child.box.wh.UiSize)
    
  # compute UiSizes for partially fixed children
  for child in node.children:
    if fixedCount(child.gridItem) in 1..3:
      # child.UiBox = child.gridItem.computeUiSize(gridTemplate, child.UiBox.wh)
      assert false, "todo: implement me!"

  # compute UiSizes for auto flow items
  if hasAutos:
    debugPrint "computeAutoFlow: "
    computeAutoFlow(gridTemplate, box, node.children)


  debugPrint "COMPUTE node layout: "
  prettyLayout(node)

  let computedSizes = gridTemplate.computeContentSizes(node.children)

  debugPrint "GRID:CS: ", "box=", $box
  printGrid(gridTemplate)
  gridTemplate.computeTracks(box, computedSizes)
  debugPrint "GRID:ComputedTracks: "
  printGrid(gridTemplate)

  debugPrint "COMPUTE Parent: "
  prettyLayout(node)
  debugPrint "COMPUTE BOXES: "
  for child in node.children:
    if fixedCount(child.gridItem) in 1..3:
      continue
    # debugPrint "COMPUTE BOXES:CHILD: "
    # prettyLayout(child)
    let cbox = child.computeBox(gridTemplate)
    child.box = typeof(child.box)(cbox)
    # prettyLayout(child)
  debugPrint "COMPUTE POST: "
  prettyLayout(node)
  
  let w = gridTemplate.overflowSizes[dcol]
  let h = gridTemplate.overflowSizes[drow]
  return typeof(box)(uiBox(
                box.x.float,
                box.y.float,
                max(box.w.float, gridTemplate.lines[dcol][^1].start.float),
                max(box.h.float, gridTemplate.lines[drow][^1].start.float),
              ))

proc computeLayout*(node: GridNode, depth: int) =
  ## Computes constraints and auto-layout.
  debugPrint "computeLayout", " name = ", node.name, " box = ", node.box.wh.repr

  # # simple constraints
  calcBasicConstraint(node)

  # css grid impl
  if not node.gridTemplate.isNil:
    debugPrint "computeLayout:gridTemplate", " name = ", node.name, " box = ", node.box.repr
    # compute children first, then lay them out in grid
    for n in node.children:
      computeLayout(n, depth + 1)

    var box = node.box
    # adjust box to not include offset in wh
    # box.w = box.w - box.x
    # box.h = box.h - box.y
    let res = node.gridTemplate.computeNodeLayout(node).UiBox
    node.box = res

    # for n in node.children:
    #   for c in n.children:
    #     calcBasicConstraint(c, dcol, isXY = false)
    #     calcBasicConstraint(c, drow, isXY = false)
    debugPrint "computeLayout:gridTemplate:post", " name = ", node.name, " box = ", node.box.wh.repr
  else:
    for n in node.children:
      computeLayout(n, depth + 1)

    # update childrens
    for n in node.children:
      calcBasicConstraintPost(n)
      debugPrint "calcBasicConstraintPost: ", " n = ", n.name, " w = ", n.box.w, " h = ", n.box.h

  # debugPrint "computeLayout:post: ",
  #   name = node.name, box = node.box.repr, prevSize = node.prevSize.repr, children = node.children.mapIt((it.name, it.box.repr))
  calcBasicConstraintPost(node)

proc computeLayout*(node: GridNode) =
  computeLayout(node, 0)

proc printLayoutShort*(node: GridNode, depth = 0) =
  stdout.styledWriteLine(
    " ".repeat(depth),
    {styleDim},
    fgWhite,
    "node: ",
    resetStyle,
    fgWhite,
    $node.name,
    " [xy: ",
    fgGreen,
    $node.box.x.float.round(2),
    "x",
    $node.box.y.float.round(2),
    fgWhite,
    "; wh:",
    fgYellow,
    $node.box.w.float.round(2),
    "x",
    $node.box.h.float.round(2),
    fgWhite,
    "]",
  )
  for c in node.children:
    printLayoutShort(c, depth + 2)

  debugPrint "computeLayout:post: ",
    " name = ", node.name, " wh = ", node.box.wh