import std/rationals
import patty

import basic, constraints, gridtypes, parser

export rationals, constraints, gridtypes

let defaultLine = GridLine(track: csFrac(1))

proc computeLineLayout*(
    lines: var seq[GridLine],
    length: UiScalar,
    spacing: UiScalar,
) =
  var
    fixed = 0.UiScalar
    totalFracs = 0.0.UiScalar
    totalAutos = 0
  
  # compute total fixed sizes and fracs
  for grdLn in lines:
    match grdLn.track:
      UiValue(value):
        match value:
          UiFixed(coord): fixed += coord
          UiFrac(frac): totalFracs += frac
          UiPerc(): discard
      UiEnd(): discard
      UiAuto(): totalAutos += 1
      UiMin(): totalAutos += 1
      UiMax(): totalAutos += 1
      UiMinMax(): totalAutos += 1
  fixed += spacing * UiScalar(lines.len() - 1)

  var
    freeSpace = length - fixed
    remSpace = max(freeSpace, 0.UiScalar)
  
  # frac's
  for grdLn in lines.mitems():
    if grdLn.track.kind == UiValue:
      let grdVal = grdLn.track.value
      if grdVal.kind == UiFrac:
        grdLn.width =
          freeSpace * grdVal.frac/totalFracs
        remSpace -= max(grdLn.width, 0.UiScalar)
      elif grdVal.kind == UiFixed:
        grdLn.width = grdVal.coord
      elif grdVal.kind == UiPerc:
        grdLn.width = length * grdVal.perc / 100
        remSpace -= max(grdLn.width, 0.UiScalar)
  
  # auto's
  for grdLn in lines.mitems():
    if grdLn.track.kind == UiAuto:
      grdLn.width = remSpace / totalAutos.UiScalar

  var cursor = 0.0.UiScalar
  for grdLn in lines.mitems():
    grdLn.start = cursor
    cursor += grdLn.width + spacing

proc computeTracks*(grid: GridTemplate, UiBox: UiBox) =
  ## computing grid layout
  if grid.lines[dcol].len() == 0 or
      grid.lines[dcol][^1].track.kind != UiEnd:
    grid.lines[dcol].add initGridLine(csEnd())
  if grid.lines[drow].len() == 0 or
      grid.lines[drow][^1].track.kind != UiEnd:
    grid.lines[drow].add initGridLine(csEnd())
  # The free space is calculated after any non-flexible items. In 
  let
    colLen = UiBox.w
    rowLen = UiBox.h
  grid.lines[dcol].computeLineLayout(length=colLen, spacing=grid.gaps[dcol])
  grid.lines[drow].computeLineLayout(length=rowLen, spacing=grid.gaps[drow])

proc reComputeLayout(grid: GridTemplate) =
  var w, h: float32
  for col in grid.lines[dcol]:
    if col.track.kind == UiEnd:
      w = col.start.float32
      break
  for row in grid.lines[drow]:
    if row.track.kind == UiEnd:
      h = row.start.float32
      break
  # echo "reCompute"
  grid.computeTracks(uiBox(0, 0, w, h))

proc findLine(index: GridIndex, lines: seq[GridLine]): int16 =
  for i, line in lines:
    if index.line in line.aliases:
      return int16(i+1)
  raise newException(KeyError, "couldn't find index: " & repr index)

proc getGrid(lines: seq[GridLine], idx: int): UiScalar =
  # if idx == -2: lines[idx-1].start else: lines[^1].start
  lines[idx-1].start

proc gridAutoInsert(grid: GridTemplate, dir: GridDir, idx: int, cz: UiScalar) =
  assert idx <= 1000, "max grids exceeded"
  if idx >= grid.lines[dir].len():
    while idx >= grid.lines[dir].len():
      let offset = grid.lines[dir].len() - 1
      var ln = initGridLine(track = grid.autos[dir])
      grid.lines[dir].insert(ln, offset)

proc setSpan(grid: GridTemplate, index: GridIndex, dir: GridDir, cz: UiScalar): int16 =
  ## todo: clean this up? maybe use static bools for col vs row
  if not index.isName:
    let idx = index.line.int - 1
    grid.gridAutoInsert(dir, idx, cz)
    index.line.int16
  else:
    findLine(index, grid.lines[`dir`])

proc setGridSpans*(
    item: GridItem,
    grid: GridTemplate,
    contentSize: UiSize
) =
  ## computing grid layout
  assert not item.isNil

  if item.span[dcol].a == 0:
    item.span[dcol].a = grid.setSpan(item.index[dcol].a, dcol, 0)
  if item.span[dcol].b == 0:
    item.span[dcol].b = grid.setSpan(item.index[dcol].b, dcol, contentSize.x)

  if item.span[drow].a == 0:
    item.span[drow].a = grid.setSpan(item.index[drow].a, drow, 0)
  if item.span[drow].b == 0:
    item.span[drow].b = grid.setSpan(item.index[drow].b, drow, contentSize.x)

proc computeBox*(
    item: GridItem,
    grid: GridTemplate,
    maxContentSize: UiSize
): UiBox =
  ## computing grid layout
  assert not item.isNil
  # item.setGridSpans(grid, contentSize)

  # set columns
  result.x = grid.lines[dcol].getGrid(item.span[dcol].a)
  let rxw = grid.lines[dcol].getGrid(item.span[dcol].b)
  let rww = (rxw - result.x) - grid.gaps[dcol]
  case grid.justifyItems:
  of CxStretch:
    result.w = rww
  of CxCenter:
    result.x = result.x + (rww - maxContentSize.x)/2.0
    result.w = maxContentSize.x
  of CxStart:
    result.w = maxContentSize.x
  of CxEnd:
    result.x = rxw - maxContentSize.x
    result.w = maxContentSize.x

  # set rows
  result.y = grid.lines[drow].getGrid(item.span[drow].a)
  let ryh = grid.lines[drow].getGrid(item.span[drow].b)
  let rhh = (ryh - result.y) - grid.gaps[drow]
  case grid.alignItems:
  of CxStretch:
    result.h = rhh
  of CxCenter:
    result.y = result.y + (rhh - maxContentSize.y)/2.0
    result.h = maxContentSize.y
  of CxStart:
    result.h = maxContentSize.y
  of CxEnd:
    result.y = ryh - maxContentSize.y
    result.h = maxContentSize.y

proc fixedCount*(gridItem: GridItem): range[0..4] =
  if gridItem.index[dcol].a.line.int != 0: result.inc
  if gridItem.index[dcol].b.line.int != 0: result.inc
  if gridItem.index[drow].a.line.int != 0: result.inc
  if gridItem.index[drow].b.line.int != 0: result.inc

proc isAutoUiSizeed*(gridItem: GridItem): bool =
  gridItem.fixedCount() == 0

import print

proc computeAutoFlow(
    gridTemplate: GridTemplate,
    node: GridNode,
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

  # print gridTemplate.lines[mx].len()
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
        fixedCache[j].incl span
    else:
      autos.add child

  # setup cursor for current grid UiSize
  # for i in 1..fixedCache.len():
  #   for gspan in fixedCache[i.LinePos]:
  #     echo "\ti: ", i, " => ", gspan[my], " // ", gspan[mx]
  
  # var cursor = (1.LinePos, 1.LinePos)
  var cursor: array[GridDir, LinePos] = [1.LinePos, 1.LinePos]
  var i = 0

  template incrCursor(amt, blk, outer: untyped) =
    ## increment major index
    cursor[mx].inc
    ## increment minor when at end of major
    if cursor[mx] >= gridTemplate.lines[mx].len():
      cursor[mx] = 1.LinePos
      cursor[my] = cursor[my] + 1
      if cursor[my] >= gridTemplate.lines[my].len():
        break outer
      break blk
  
  ## computing auto flows
  block autoflow:
    while i < len(autos):
      block childBlock:
        ## increment cursor and index until one breaks the mold
        while cursor in fixedCache[cursor[my]]:
          # print "skipping fixedCache:", cursor
          incrCursor(1, childBlock, autoFlow)
        while not (cursor in fixedCache[cursor[my]]):
          # echo "\nset span:"
          # print cursor
          autos[i].gridItem.span[mx] = cursor[mx] .. cursor[mx] + 1
          autos[i].gridItem.span[my] = cursor[my] .. cursor[my] + 1
          # print autos[i].gridItem.span[dcol]
          # print autos[i].gridItem.span[drow]
          i.inc
          if i >= autos.len():
            break autoflow
          incrCursor(1, childBlock, autoFlow)

proc computeNodeLayout*(
    gridTemplate: GridTemplate,
    node: GridNode,
    children: seq[GridNode],
) =
  ## implement full(ish) CSS grid algorithm here
  ## currently assumes that `N`, the ref object, has
  ## both `UiBox: UiBox` and `gridItem: GridItem` fields. 
  ## 
  ## this algorithm tries to follow the specification at:
  ##   https://www.w3.org/TR/css3-grid-layout/#grid-item-placement-algorithm
  ## 
  var hasAutos = false
  for child in children:
    if child.gridItem == nil:
      # ensure all grid children have a GridItem
      child.gridItem = GridItem()
      hasAutos = true
    else:
      hasAutos = true
    child.gridItem.setGridSpans(gridTemplate, child.box.wh)
    
  # compute UiSizes for partially fixed children
  for child in children:
    if fixedCount(child.gridItem) in 1..3:
      # child.UiBox = child.gridItem.computeUiSize(gridTemplate, child.UiBox.wh)
      assert false, "todo: implement me!"

  # compute UiSizes for auto flow items
  if hasAutos:
    computeAutoFlow(gridTemplate, node, children)

  gridTemplate.computeTracks(node.box)
  # echo "gridTemplate: ", gridTemplate.repr

  for child in children:
    if fixedCount(child.gridItem) in 1..3:
      continue
    child.box = child.gridItem.computeBox(gridTemplate, child.box.wh)
