import patty

import numberTypes, constraints, gridtypes, parser

export constraints, gridtypes

let defaultLine = GridLine(track: csFrac(1))

proc computeLineOverflow*(
    lines: var seq[GridLine],
): UiScalar =
  for grdLn in lines:
    # echo "grdLn: ", grdLn.isAuto
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
    totalAutos = 0
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
          UiPerc(): discard
          UiContentMin(cmin):
            if cmin.float32 != float32.high():
              fixed += cmin
          UiContentMax(cmax):
            fixed += cmax
          UiAuto():
            totalAutos += 1
      UiEnd():
        discard
      UiMin(lmin, rmin):
        if lmin.kind == UiFrac:
          isUndefined = true
        # calc(value)
        discard
      UiMax(lmax, rmax):
        if lmax.kind == UiFrac:
          isUndefined = true
        # calc(value)
        discard
      UiSum(lsum, rsum):
        if lsum.kind == UiFrac:
          isUndefined = true
        # calc(value)
        discard
      UiMinMax(lmm, rmm):
        if lmm.kind == UiFrac:
          isUndefined = true
        # calc(value)
        discard
  fixed += spacing * UiScalar(lines.len() - 1)

  var
    freeSpace = max(length - fixed, 0.0.UiScalar)
    remSpace = max(freeSpace, 0.UiScalar)
  
  # frac's
  # 1'fr 1'fr min(1'fr, 10em)
  for grdLn in lines.mitems():
    if grdLn.track.kind == UiValue:
      let grdVal = grdLn.track.value
      if grdVal.kind == UiFrac:
        grdLn.width = freeSpace * grdVal.frac/totalFracs
        remSpace -= max(grdLn.width, 0.UiScalar)
      elif grdVal.kind == UiFixed:
        grdLn.width = grdVal.coord
      elif grdVal.kind == UiPerc:
        grdLn.width = length * grdVal.perc / 100
        remSpace -= max(grdLn.width, 0.UiScalar)
      elif grdVal.kind == UiContentMax:
        grdLn.width = grdVal.cmax
      elif grdVal.kind == UiContentMin:
        if grdVal.cmin.float32 != float32.high():
          grdLn.width = grdVal.cmin
      elif grdVal.kind == UiAuto:
        if grdVal.amin.float32 != float32.high():
          grdLn.width = grdVal.amin
  
  # auto's
  for grdLn in lines.mitems():
    if grdLn.track.isAuto:
      grdLn.width = remSpace / totalAutos.UiScalar

  var cursor = 0.0.UiScalar
  for grdLn in lines.mitems():
    grdLn.start = cursor
    cursor += grdLn.width + spacing

proc computeTracks*(grid: GridTemplate, contentSize: UiBox, extendOnOverflow = false) =
  ## computing grid layout
  if grid.lines[dcol].len() == 0 or
      grid.lines[dcol][^1].track.kind != UiEnd:
    grid.lines[dcol].add initGridLine(csEnd())
  if grid.lines[drow].len() == 0 or
      grid.lines[drow][^1].track.kind != UiEnd:
    grid.lines[drow].add initGridLine(csEnd())
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
  if idx >= grid.lines[dir].len():
    # echo "gridAutoInsert: ", idx
    while idx >= grid.lines[dir].len():
      let offset = grid.lines[dir].len() - 1
      let track = grid.autos[dir]
      var ln = initGridLine(track = track, isAuto = true)
      grid.lines[dir].insert(ln, max(offset, 0))

proc setSpan(grid: GridTemplate, index: GridIndex, dir: GridDir, cz: UiScalar): int16 =
  ## todo: clean this up? maybe use static bools for col vs row
  if not index.isName:
    let idx = index.line.ints - 1 + index.spanCnt()
    # echo "setSpan: ", idx, " index: ", index, " dir: ", dir, " cz: ", cz
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
  # echo "setGridSpans: ", item

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

import pretty

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
    case `axis`:
    of CxStretch:
      result.`v` = rvw
    of CxCenter:
      result.`f` = (rvw/2 - contentSize.`f`/2) + result.`f`
      result.`v` = contentSize.`f`
    of CxStart:
      result.`v` = contentSize.`f`
    of CxEnd:
      result.`f` = rfw - contentSize.`f`
      result.`v` = contentSize.`f`

  calcBoxFor(x, w, dcol, grid.justifyItems)
  calcBoxFor(y, h, drow, grid.alignItems)

  # set rows
  # result.y = grid.lines[drow].getGrid(node.gridItem.span[drow].a)
  # let ryh = grid.lines[drow].getGrid(node.gridItem.span[drow].b)
  # let rhh = (ryh - result.y) - grid.gaps[drow]
  # case grid.alignItems:
  # of CxStretch:
  #   result.h = rhh
  # of CxCenter:
  #   result.y = result.y + (rhh - contentSize.y)/2.0
  #   result.h = contentSize.y
  # of CxStart:
  #   result.h = contentSize.y
  # of CxEnd:
  #   result.y = ryh - contentSize.y
  #   result.h = contentSize.y

proc fixedCount*(gridItem: GridItem): range[0..4] =
  if gridItem.index[dcol].a.line.ints != 0: result.inc
  if gridItem.index[dcol].b.line.ints != 0: result.inc
  if gridItem.index[drow].a.line.ints != 0: result.inc
  if gridItem.index[drow].b.line.ints != 0: result.inc

proc isAutoUiSizeed*(gridItem: GridItem): bool =
  gridItem.fixedCount() == 0

import pretty

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
      # echo "in: cur: ", cur[mx]
      if cur[mx] in span[mx] and cur[my] in span[my]:
        return true

  # echo "computeAutoFlow:gridTemplate.lines"
  # print gridTemplate.lines[mx].len()
  # print gridTemplate

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
      # print rng
      for j in rng.a ..< rng.b:
        fixedCache.mgetOrPut(j, initHashSet[GridSpan]()).incl span
    else:
      autos.add child

  # echo "computeAutoFlow:"
  # print fixedCache

  # setup cursor for current grid UiSize
  # for i in 1..fixedCache.len():
  #   for gspan in fixedCache[i.LinePos]:
  #     echo "\ti: ", i, " => ", gspan[my], " // ", gspan[mx]

  # var cursor = (1.LinePos, 1.LinePos)
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
      # if cursor[my] >= gridTemplate.lines[my].len():
      #   echo "autoFlow:BREAK:outer:i: ", i,  " mx: ", cursor[mx], " my: ", cursor[my]
      break blk
  
  ## computing auto flows
  block autoflow:
    ## this format is complicated but is used to try and keep
    ## the algorithm as O(N) as possible by iterating directly
    ## through the indexes
    while i < len(autos):
      block childBlock:
        ## increment cursor and index until one breaks the mold
        # print "autoflow:", i
        while cursor[my] in fixedCache and cursor in fixedCache[cursor[my]]:
          # print "skipping fixedCache:", cursor
          incrCursor(1, childBlock, autoFlow)
        while cursor[my] notin fixedCache or not (cursor in fixedCache[cursor[my]]):
          # set the index for each auto rather than the span directly
          # so that auto-flow works properly
          # print "set gridItem:index: ", i, " ", cursor[mx], " ", cursor[my]
          autos[i].gridItem.index[mx] = cursor[mx] // (cursor[mx] + 1)
          autos[i].gridItem.index[my] = cursor[my] // (cursor[my] + 1)
          i.inc
          if i >= autos.len():
            break autoflow
          incrCursor(1, childBlock, autoFlow)

  if foundOverflow:
    for child in autos:
      child.gridItem.setGridSpans(gridTemplate, child.box.wh.UiSize)

  # echo "autos:post:"
  # print autos.mapIt(it.box)
  # print autos.mapIt(it.gridItem.span)

proc computeNodeLayout*(
    gridTemplate: GridTemplate,
    parent: GridBox | GridNode,
    children: seq[GridNode],
    extendOnOverflow = true, # not sure what the spec says for this
): auto =

  let box = 
    when parent is GridNode: UiBox(parent.box)
    elif parent is GridBox: UiBox(parent)

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
      # hasAutos = true
    # elif child.gridItem.span == [0'i16..0'i16, 0'i16..0'i16]:
    #   hasAutos = true
    # hasAutos = false
    child.gridItem.setGridSpans(gridTemplate, child.box.wh.UiSize)
    
  # compute UiSizes for partially fixed children
  for child in children:
    if fixedCount(child.gridItem) in 1..3:
      # child.UiBox = child.gridItem.computeUiSize(gridTemplate, child.UiBox.wh)
      assert false, "todo: implement me!"

  # compute UiSizes for auto flow items
  if hasAutos:
    # echo "hasAutos"
    computeAutoFlow(gridTemplate, box, children)

  # echo "gridTemplate: ", gridTemplate.repr
  # for i in 0 ..< children.len():
  #   # echo "child:cols: ", " :: ", children[i].gridItem.span[dcol].repr, " x ", children[i].gridItem.span[drow].repr
  #   echo "child:id: ", children[i].id
  #   echo "child:cols: ", children[i].gridItem.span.repr
  #   echo "child:box: ", " => ", children[i].box

  # for i in 0 ..< gridTemplate.lines[dcol].len():
  #   echo "line:dcol: ", i

  gridTemplate.computeContentSizes(children)
  gridTemplate.computeTracks(box, extendOnOverflow)

  for child in children:
    # echo "CHILD fixed 1..3: "
    if fixedCount(child.gridItem) in 1..3:
      continue
    let cbox = child.computeBox(gridTemplate)
    child.box = typeof(child.box)(cbox)
  
  # if extendOnOverflow:
  let w = gridTemplate.overflowSizes[dcol]
  let h = gridTemplate.overflowSizes[drow]
  return typeof(box)(uiBox(
                box.x.float,
                box.y.float,
                max(box.w.float, gridTemplate.lines[dcol][^1].start.float),
                max(box.h.float, gridTemplate.lines[drow][^1].start.float),
              ))
  # echo "computeNodeLayout:done: "
  # print children
