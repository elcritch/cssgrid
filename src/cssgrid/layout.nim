import patty
import std/terminal

import numberTypes, constraints, gridtypes, parser
import basiclayout

export constraints, gridtypes

proc computeLineOverflow*(
    lines: var seq[GridLine],
): UiScalar =
  for grdLn in lines:
    if grdLn.isAuto:
      match grdLn.track:
        UiNone():
          discard
        UiValue(value):
          match value:
            UiFixed(coord):
              result += coord
            UiFrac(_): discard
            UiPerc(): discard
            UiContentMax(cmax):
              result += cmax
            UiContentMin(cmin):
              if cmin.float32 != float32.high():
                result += cmin
            UiAuto(amin):
              if amin.float32 != float32.high():
                result += amin
        _: discard

proc computeContentSizes*(grid: GridTemplate,
                          children: seq[GridNode]) =
  ## computes content min / max for each grid track based on children
  ## 
  ## only includes children which only span a single track
  ## for the current dimension
  ## 
  var contentSized: array[GridDir, set[int16]]
  for dir in [dcol, drow]:
    for i in 0 ..< grid.lines[dir].len():
      if isContentSized(grid.lines[dir][i].track):
        contentSized[dir].incl(i.int16)

  for child in children:
    let cspan = child.gridItem.span
    for dir in [dcol, drow]:
      if cspan[dir].len()-1 == 1 and (cspan[dir].a-1) in contentSized[dir]:
        template track(): auto = grid.lines[dir][cspan[dir].a-1].track
        let csize = if dir == dcol: UiBox(child.box).w
                    else: UiBox(child.box).h
        if track().value.kind == UiAuto:
          track().value.amin = min(csize, track().value.amin)
        elif track().value.kind == UiContentMin:
          track().value.cmin = min(csize, track().value.cmin)
        elif track().value.kind == UiContentMax:
          track().value.cmax = max(csize, track().value.cmax)
        else:
          assert false, "shouldn't reach here " & $track().value.kind

proc computeLineLayout*(
    lines: var seq[GridLine],
    length: UiScalar,
    spacing: UiScalar,
) =
  var
    fixed = 0.UiScalar
    totalFracs = 0.0.UiScalar
    autoSizes: seq[UiScalar] = @[]
    isUndefined = false

  # browser css grids:
  # works: grid-template-columns: 1fr minmax(100px,1fr) minmax(200px,1fr);
  # doesn't work: grid-template-columns: 1fr minmax(1fr,100px) minmax(1fr,200px);
  # neither work:
  # grid-template-columns: 1fr min(100px,1fr) min(100px,13%);
  # grid-template-columns: 1fr max(1fr,300px) max(1fr,100px);

  # compute total fixed sizes and fracs
  for grdLn in lines:
    match grdLn.track:
      UiNone():
        discard
      UiValue(value):
        match value:
          UiFixed(coord):
            fixed += coord
          UiFrac(frac):
            totalFracs += frac
          UiPerc(perc):
            fixed += length * perc / 100
          UiContentMin(cmin):
            if cmin.float32 != float32.high():
              fixed += cmin
          UiContentMax(cmax):
            fixed += cmax
          UiAuto(_):
            # Store the auto track's content size
            if value.amin.float32 != float32.high():
              autoSizes.add(value.amin)
            else:
              autoSizes.add(0.UiScalar)
      UiEnd():
        discard
      UiMin(lmin, rmin):
        if lmin.kind == UiFrac:
          isUndefined = true
      UiMax(lmax, rmax):
        if lmax.kind == UiFrac:
          isUndefined = true
      UiSum(lsum, rsum):
        if lsum.kind == UiFrac:
          isUndefined = true
      UiMinMax(lmm, rmm):
        if lmm.kind == UiFrac:
          isUndefined = true

  # Account for spacing between tracks
  fixed += spacing * UiScalar(lines.len() - 1)

  var
    freeSpace = max(length - fixed, 0.0.UiScalar)
    remSpace = freeSpace

  # Calculate minimum space needed for auto tracks
  let totalAutoMin = autoSizes.foldl(a + b, 0.UiScalar)
  
  # Second pass: handle fractions and auto tracks
  for i, grdLn in lines.mpairs():
    if grdLn.track.kind == UiValue:
      let grdVal = grdLn.track.value
      case grdVal.kind
      of UiFrac:
        # Allocate remaining space proportionally to fractions
        if totalFracs > 0:
          grdLn.width = freeSpace * grdVal.frac/totalFracs
          remSpace -= grdLn.width
      of UiFixed:
        grdLn.width = grdVal.coord
      of UiPerc:
        grdLn.width = length * grdVal.perc / 100
      of UiContentMax:
        grdLn.width = grdVal.cmax
      of UiContentMin:
        if grdVal.cmin.float32 != float32.high():
          grdLn.width = grdVal.cmin
      of UiAuto:
        # First ensure minimum content width
        let autoIndex = autoSizes.find(grdVal.amin)
        if autoIndex >= 0:
          let minWidth = autoSizes[autoIndex]
          # Distribute remaining space equally among auto tracks
          let autoShare = if autoSizes.len > 0: remSpace / autoSizes.len.UiScalar else: 0.UiScalar
          grdLn.width = max(minWidth, autoShare)

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

proc computeTracks*(grid: GridTemplate, contentSize: UiBox, extendOnOverflow = false) =
  # The free space is calculated after any non-flexible items. In 
  grid.overflowSizes[dcol] = grid.lines[dcol].computeLineOverflow()
  grid.overflowSizes[drow] = grid.lines[drow].computeLineOverflow()
  var
    colLen = contentSize.w
    rowLen = contentSize.h
  if extendOnOverflow:
    colLen += grid.overflowSizes[dcol]
    rowLen += grid.overflowSizes[drow]

  grid.lines[dcol].computeLineLayout(length=colLen, spacing=grid.gaps[dcol])
  grid.lines[drow].computeLineLayout(length=rowLen, spacing=grid.gaps[drow])

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
    item.span[dcol].b = grid.setSpan(item.index[dcol].b, dcol, contentSize.x)

  if item.span[drow].a == 0 or item.span[drow].a notin 0..lrow:
    item.span[drow].a = grid.setSpan(item.index[drow].a, drow, 0)
  if item.span[drow].b == 0 or item.span[drow].b notin 0..lrow:
    item.span[drow].b = grid.setSpan(item.index[drow].b, drow, contentSize.x)

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
    let cvw = min(contentSize.`f`, rvw)
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

proc computeNodeLayout*(
    gridTemplate: GridTemplate,
    parent: GridBox | GridNode,
    children: seq[GridNode],
    extendOnOverflow = true, # not sure what the spec says for this
): auto =

  let box = 
    when parent is GridNode: UiBox(parent.box)
    elif parent is GridBox: UiBox(parent)

  gridTemplate.createEndTracks()
  ## implement full(ish) CSS grid algorithm here
  ## currently assumes that `N`, the ref object, has
  ## both `UiBox: UiBox` and `gridItem: GridItem` fields. 
  ## 
  ## this algorithm tries to follow the specification at:
  ##   https://www.w3.org/TR/css3-grid-layout/#grid-item-placement-algorithm
  ## 
  var hasAutos = true
  for child in children:
    if child.gridItem == nil:
      # ensure all grid children have a GridItem
      child.gridItem = GridItem()
    child.gridItem.setGridSpans(gridTemplate, child.box.wh.UiSize)
    
  # compute UiSizes for partially fixed children
  for child in children:
    if fixedCount(child.gridItem) in 1..3:
      # child.UiBox = child.gridItem.computeUiSize(gridTemplate, child.UiBox.wh)
      assert false, "todo: implement me!"

  # compute UiSizes for auto flow items
  if hasAutos:
    computeAutoFlow(gridTemplate, box, children)

  gridTemplate.computeContentSizes(children)
  gridTemplate.computeTracks(box, extendOnOverflow)

  for child in children:
    if fixedCount(child.gridItem) in 1..3:
      continue
    let cbox = child.computeBox(gridTemplate)
    child.box = typeof(child.box)(cbox)
  
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
  echo "computeLayout", " name = ", node.name, " box = ", node.box.wh.repr

  # # simple constraints
  calcBasicConstraint(node, dcol, isXY = true)
  calcBasicConstraint(node, drow, isXY = true)
  calcBasicConstraint(node, dcol, isXY = false)
  calcBasicConstraint(node, drow, isXY = false)

  # css grid impl
  if not node.gridTemplate.isNil:
    echo "computeLayout:gridTemplate", " name = ", node.name, " box = ", node.box.repr
    # compute children first, then lay them out in grid
    for n in node.children:
      computeLayout(n, depth + 1)

    var box = node.box
    # adjust box to not include offset in wh
    # box.w = box.w - box.x
    # box.h = box.h - box.y
    let res = node.gridTemplate.computeNodeLayout(box, node.children).UiBox
    node.box = res

    for n in node.children:
      for c in n.children:
        calcBasicConstraint(c, dcol, isXY = false)
        calcBasicConstraint(c, drow, isXY = false)
    echo "computeLayout:gridTemplate:post", " name = ", node.name, " box = ", node.box.wh.repr
  else:
    for n in node.children:
      computeLayout(n, depth + 1)

    # update childrens
    for n in node.children:
      calcBasicConstraintPost(n, dcol, isXY = true)
      calcBasicConstraintPost(n, drow, isXY = true)
      calcBasicConstraintPost(n, dcol, isXY = false)
      calcBasicConstraintPost(n, drow, isXY = false)
      echo "calcBasicConstraintPost: ", " n = ", n.name, " w = ", n.box.w, " h = ", n.box.h

  # debug "computeLayout:post: ",
  #   name = node.name, box = node.box.repr, prevSize = node.prevSize.repr, children = node.children.mapIt((it.name, it.box.repr))

proc printLayout*(node: GridNode, depth = 0) =
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
    printLayout(c, depth + 2)

  echo "computeLayout:post: ",
    " name = ", node.name, " wh = ", node.box.wh