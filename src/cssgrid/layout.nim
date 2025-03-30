import patty
import std/terminal
import std/tables

import numberTypes, constraints, gridtypes, parser
import basiclayout

export constraints, gridtypes

import prettyprints

type
  ComputedTrackSize* = object of ComputedSize

{.push stackTrace: off.}

proc processUiValue(
    value: ConstraintSize,
    i: int, computedSizes: Table[int, ComputedTrackSize],
    totalAuto: var UiScalar,
    totalFracs: var UiScalar,
    length = 0.0.UiScalar,
): UiScalar =
  debugPrint "computeLineOverflow", "trackCxValue=", value, "autoSize=", computedSizes.getOrDefault(i).content
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
      match grdLn.track:
        UiNone:
          discard
        UiValue(value):
          result += processUiValue(value, i, computedSizes, totalAuto, totalFracs)
        UiAdd(ls, rs):
          result += processUiValue(ls, i, computedSizes, totalAuto, totalFracs) + processUiValue(rs, i, computedSizes, totalAuto, totalFracs)
        UiSub(ls, rs):
          result += processUiValue(ls, i, computedSizes, totalAuto, totalFracs) - processUiValue(rs, i, computedSizes, totalAuto, totalFracs)
        UiMin(ls, rs):
          result += min(processUiValue(ls, i, computedSizes, totalAuto, totalFracs), processUiValue(rs, i, computedSizes, totalAuto, totalFracs))
        UiMax(ls, rs):
          result += max(processUiValue(ls, i, computedSizes, totalAuto, totalFracs), processUiValue(rs, i, computedSizes, totalAuto, totalFracs))
        UiMinMax(ls, rs):
          discard
        UiEnd:
          discard

  debugPrint "computeLineOverflow:post: ", "dir=", dir, "overflow=", result

proc computeLineLayout*(
    lines: var seq[GridLine];
    dir: GridDir,
    computedSizes: Table[int, ComputedTrackSize],
    length: UiScalar,
    spacing: UiScalar,
) =
  var
    fixed = 0.UiScalar
    totalFracs = 0.0.UiScalar
    totalAuto = 0.0.UiScalar

  # First pass: calculate fixed sizes and identify auto/frac tracks
  for i, grdLn in lines.mpairs():
    case grdLn.track.kind:
      of UiValue:
        let value = grdLn.track.value
        case value.kind:
          of UiFixed, UiPerc:
            grdLn.width = processUiValue(value, i, computedSizes, totalAuto, totalFracs, length)
            fixed += grdLn.width
          of UiContentMin, UiContentMax, UiContentFit:
            grdLn.width = processUiValue(value, i, computedSizes, totalAuto, totalFracs, length)
            fixed += grdLn.width
          of UiFrac:
            grdLn.width = processUiValue(value, i, computedSizes, totalAuto, totalFracs, length)
          of UiAuto:
            grdLn.width = processUiValue(value, i, computedSizes, totalAuto, totalFracs, length)
      of UiMin, UiMax, UiAdd, UiSub, UiMinMax:
        let args = cssFuncArgs(grdLn.track)
        let lv = processUiValue(args.l, i, computedSizes, totalAuto, totalFracs)
        let rv = processUiValue(args.r, i, computedSizes, totalAuto, totalFracs)
        grdLn.width = computeCssFuncs(grdLn.track.kind, lv, rv)
      else:
        debugPrint "computeLineLayout:unknown: ", "track=", grdLn.track
        discard  # Handle other cases

  # Account for spacing between tracks (minus the last [end] track)
  fixed += spacing * max(UiScalar(lines.len() - 2), 0.UiScalar)

  # Calculate available free space
  let
    freeSpace = max(length - fixed, 0.0.UiScalar)
    autoSpace = if totalFracs > 0: 0.0.UiScalar else: freeSpace
    fracUnit = freeSpace / totalFracs
    autoUnit = autoSpace / totalAuto

  var
    fixedMinSizes = 0.0.UiScalar
    totalFlexFracs = 0.0.UiScalar
    totalFlexAuto = 0.0.UiScalar

  # Second pass: distribute space for flex items and find any min flex sizes
  for i, grdLn in lines.mpairs():
    match grdLn.track:
      UiValue(value):
        match value:
          UiFrac(frac):
            if totalFracs > 0:
              let minSize = computedSizes.getOrDefault(i).content
              let frSize = fracUnit * frac
              if frSize < minSize:
                grdLn.width = minSize
                fixedMinSizes += minSize
              else:
                grdLn.width = UiScalar.low()
                totalFlexFracs += frac
          UiAuto():
            let minSize = computedSizes.getOrDefault(i).content
            if totalFracs > 0 or autoUnit < minSize:
              fixedMinSizes += minSize
              grdLn.width = minSize
            else:
              grdLn.width = UiScalar.low()
              totalFlexAuto += 1
          _: discard  # Handle other cases
      _: discard  # Handle other cases

  let freeSpaceMinusMin = freeSpace - fixedMinSizes
  let fracFlexUnit = freeSpaceMinusMin / totalFlexFracs
  let autoFlexUnit = freeSpaceMinusMin / totalFlexAuto

  debugPrint "computeLineLayout:metrics",
    "dir=", dir,
    "length=", length,
    "fixed=", fixed,
    "freeSpace=", freeSpace,
    "freeSpaceMinusMin=", freeSpaceMinusMin,
    "totalFlexFracs=", totalFlexFracs,
    "fracFlexUnit=", fracFlexUnit,
    "totalFlexAuto=", totalFlexAuto,
    "autoFlexUnit=", autoFlexUnit


  # Second pass: distribute space and set track widths
  for i, grdLn in lines.mpairs():
    match grdLn.track:
      UiValue(value):
        match value:
          UiFrac(frac):
            if grdLn.width == UiScalar.low():
              grdLn.width = freeSpaceMinusMin * frac/totalFlexFracs
              debugPrint "computeLineLayout:frac: ", "width=", grdLn.width, "frac=", frac, "freeSpaceMinusMin=", freeSpaceMinusMin, "totalFlexFracs=", totalFlexFracs, "fracFlexUnit=", fracFlexUnit
          UiAuto():
            if grdLn.width == UiScalar.low():
              grdLn.width = autoFlexUnit
          _: discard  # Handle other cases
      _: discard  # Handle other cases

  # Final pass: calculate positions
  var cursor = 0.0.UiScalar
  for grdLn in lines.mitems():
    grdLn.start = cursor
    cursor += grdLn.width + spacing
  if lines.len() > 0:
    lines[^1].start -= spacing

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
  when defined(debugCssGrid):
    prettyGridTemplate(grid)
  grid.overflowSizes[dcol] = computeLineOverflow(dcol, grid.lines, computedSizes)
  grid.overflowSizes[drow] = computeLineOverflow(drow, grid.lines, computedSizes)

  var
    colLen = contentSize.w
    rowLen = contentSize.h

  colLen = max(colLen, grid.overflowSizes[dcol])
  rowLen = max(rowLen, grid.overflowSizes[drow])

  debugPrint "computeTracks:lengths:", "contentSize=", contentSize, "grid.overflowSizes=", grid.overflowSizes

  # Pass computed sizes to layout
  grid.lines[dcol].computeLineLayout(
    dcol,
    computedSizes[dcol],
    length=colLen,
    spacing=grid.gaps[dcol]
  )
  grid.lines[drow].computeLineLayout(
    drow,
    computedSizes[drow],
    length=rowLen,
    spacing=grid.gaps[drow]
  )

  when defined(debugCssGrid):
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
    let spanEnd = grid.lines[`dir`].getGrid(node.gridItem.span[`dir`].b)
    let spanWidth = (spanEnd - result.`f`) - grid.gaps[`dir`]
    let contentSizeDir = contentSize.`v` + node.bpad.wh[`dir`]
    let contentView = min(contentSizeDir, spanWidth)
    debugPrint "calcBoxFor:", "name=", node.name, "dir=", dir, "spanEnd=", spanEnd, "spanWidth=", spanWidth, "contentView=", contentView, "contentSize=", contentSizeDir
    case `axis`:
    of CxStretch:
      result.`v` = spanWidth
    of CxCenter:
      result.`f` = (spanWidth/2 - contentView/2) + result.`f`
      result.`v` = contentView
    of CxStart:
      result.`v` = contentView
    of CxEnd:
      result.`f` = spanEnd - contentView
      result.`v` = contentView

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

proc computeContentSizes*(
    grid: GridTemplate,
    padding: UiBox,
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
    let cspan = child.gridItem.span
    for dir in [dcol, drow]:
      if cspan[dir].len()-1 == 1 and (cspan[dir].a-1) in contentSized[dir]:
        let trackIndex = cspan[dir].a-1
        let track = grid.lines[dir][trackIndex].track
        
        # Calculate size recursively including nested children
        # let contentSize = calculateContentSize(child, dir)
        var contentSize = child.bmin[dir]
        if child.box.wh[dir] != 0.UiScalar:
          contentSize = min(contentSize, child.box.wh[dir])
        # contentSize += child.bpad.wh[dir] # TODO: que?

        if contentSize == UiScalar.high: contentSize = 0.UiScalar
        if contentSize == UiScalar.low: contentSize = 0.UiScalar
        debugPrint "computeContentSizes:pre", "child=", child.name, "dir=", dir, "contentSize=", contentSize, "chBmin=", child.bmin[dir], "chBox=", child.box.wh[dir], "pad=", child.bpad.wh[dir]
        
        # Update track's computed size based on its type
        var computed = result[dir].getOrDefault(trackIndex)
        case track.value.kind:
        of UiAuto, UiFrac, UiContentMin, UiContentMax, UiContentFit:
          # For fit-content, we just need to set the maxContent value
          # The clamping to available space happens during layout
          computed.content = contentSize
        else: discard
        
        debugPrint "computeContentSizes:post", "track=", track.value.kind, "contentSize=", contentSize, "computed=", computed

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
  # when defined(debugCssGrid):
  #   prettyLayout(node)

  let computedSizes = gridTemplate.computeContentSizes(node.bpad, node.children)

  debugPrint "GRID:CS: ", "box=", $box
  debugPrint "GRID:computedContentSizes: ", computedSizes
  printGrid(gridTemplate)
  gridTemplate.computeTracks(box, computedSizes)
  debugPrint "GRID:ComputedTracks: "
  printGrid(gridTemplate)

  debugPrint "COMPUTE Parent: "
  # when defined(debugCssGrid):
  #   prettyLayout(node)
  debugPrint "COMPUTE BOXES: "
  for child in node.children:
    # if fixedCount(child.gridItem) in 1..3:
    #   continue
    let cbox = child.computeBox(gridTemplate)
    debugPrint "COMPUTE BOXES: ", "child=", child.name, "cbox=", $cbox
    child.box = typeof(child.box)(cbox)
  
  let w = gridTemplate.overflowSizes[dcol]
  let h = gridTemplate.overflowSizes[drow]
  return typeof(box)(uiBox(
                box.x.float,
                box.y.float,
                max(box.w.float, gridTemplate.lines[dcol][^1].start.float),
                max(box.h.float, gridTemplate.lines[drow][^1].start.float),
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
    "name=", node.name, " wh = ", node.box.wh