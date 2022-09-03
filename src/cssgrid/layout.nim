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
      UiFixed(coord): fixed += coord
      UiFrac(frac): totalFracs += frac
      UiAuto(): totalAutos += 1
      UiPerc(): discard
      UiEnd(): discard
  fixed += spacing * UiScalar(lines.len() - 1)

  var
    freeSpace = length - fixed
    remSpace = max(freeSpace, 0.UiScalar)
  
  # frac's
  for grdLn in lines.mitems():
    if grdLn.track.kind == UiFrac:
      grdLn.width =
        freeSpace * grdLn.track.frac/totalFracs
      remSpace -= max(grdLn.width, 0.UiScalar)
    elif grdLn.track.kind == UiFixed:
      grdLn.width = grdLn.track.coord
    elif grdLn.track.kind == UiPerc:
      grdLn.width = length * grdLn.track.perc / 100
      remSpace -= max(grdLn.width, 0.UiScalar)
  
  # auto's
  for grdLn in lines.mitems():
    if grdLn.track.kind == UiAuto:
      grdLn.width = remSpace / totalAutos.UiScalar

  var cursor = 0.0.UiScalar
  for grdLn in lines.mitems():
    grdLn.start = cursor
    cursor += grdLn.width + spacing

proc computeLayout*(grid: GridTemplate, UiBox: UiBox) =
  ## computing grid layout
  if grid.lines[dcol].len() == 0 or grid.lines[dcol][^1].track.kind != UiEnd:
    grid.lines[dcol].add initGridLine(csEnd())
  if grid.lines[drow].len() == 0 or grid.lines[drow][^1].track.kind != UiEnd:
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
  grid.computeLayout(uiBox(0, 0, w, h))

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
      if offset+1 == idx and ln.track.kind == UiFixed:
        # echo "insert: ", offset+1, "@", idx, "/", grid.`lines`.len()
        ln.track.coord = max(ln.track.coord, cz)
      grid.lines[`dir`].insert(ln, offset)
    grid.reComputeLayout()
  
proc setSpan(grid: GridTemplate, index: GridIndex, dir: GridDir, cz: UiScalar): int16 =
  ## todo: clean this up? maybe use static bools for col vs row
  if not index.isName:
    let idx = index.line.int - 1
    grid.gridAutoInsert(dir, idx, cz)
    index.line.int16
  else:
    findLine(index, grid.lines[`dir`])

proc setGridSpans(
    item: GridItem,
    grid: GridTemplate,
    contentSize: UiSize
) =
  ## computing grid layout
  assert not item.isNil

  if item.span[dcol].a == 0:
    item.span[dcol].a = grid.setSpan(item.columns.a, dcol, 0)
  if item.span[dcol].b == 0:
    item.span[dcol].b = grid.setSpan(item.columns.b, dcol, contentSize.x)

  if item.span[drow].a == 0:
    item.span[drow].a = grid.setSpan(item.rows.a, drow, 0)
  if item.span[drow].b == 0:
    item.span[drow].b = grid.setSpan(item.rows.b, drow, contentSize.x)

proc computePosition*(
    item: GridItem,
    grid: GridTemplate,
    contentSize: UiSize
): UiBox =
  ## computing grid layout
  assert not item.isNil
  item.setGridSpans(grid, contentSize)

  # set columns
  result.x = grid.lines[dcol].getGrid(item.span[dcol].a)
  let rxw = grid.lines[dcol].getGrid(item.span[dcol].b)
  let rww = (rxw - result.x) - grid.gaps[dcol]
  case grid.justifyItems:
  of CxStretch:
    result.w = rww
  of CxCenter:
    result.x = result.x + (rww - contentSize.x)/2.0
    result.w = contentSize.x
  of CxStart:
    result.w = contentSize.x
  of CxEnd:
    result.x = rxw - contentSize.x
    result.w = contentSize.x

  # set rows
  result.y = grid.lines[drow].getGrid(item.span[drow].a)
  let ryh = grid.lines[drow].getGrid(item.span[drow].b)
  let rhh = (ryh - result.y) - grid.gaps[drow]
  case grid.alignItems:
  of CxStretch:
    result.h = rhh
  of CxCenter:
    result.y = result.y + (rhh - contentSize.y)/2.0
    result.h = contentSize.y
  of CxStart:
    result.h = contentSize.y
  of CxEnd:
    result.y = ryh - contentSize.y
    result.h = contentSize.y

proc fixedCount*(gridItem: GridItem): range[0..4] =
  if gridItem.columns.a.line.int != 0: result.inc
  if gridItem.columns.b.line.int != 0: result.inc
  if gridItem.rows.a.line.int != 0: result.inc
  if gridItem.rows.b.line.int != 0: result.inc

proc isAutoUiSizeed*(gridItem: GridItem): bool =
  gridItem.fixedCount() == 0

proc `in`(cur: (LinePos, LinePos), col: HashSet[GridSpan]): bool =
  for span in col:
    if cur[0] in span[dcol] and cur[1] in span[drow]:
      return true

proc computeAutoFlow(
    gridTemplate: GridTemplate,
    node: GridNodes,
    allNodes: seq[GridNodes],
) =
  let mx = dcol
  let my = drow

  # setup caches
  var autos = newSeqOfCap[GridNodes](allNodes.len())
  var fixedCache = newTable[LinePos, HashSet[GridSpan]]()
  for i in 1..gridTemplate.lines[mx].len():
    fixedCache[i.LinePos] = initHashSet[GridSpan]()

  # populate caches
  for child in allNodes:
    if child.gridItem == nil:
      child.gridItem = GridItem()
  for child in allNodes:
    if fixedCount(child.gridItem) == 4:
      var span = child.gridItem.span
      span[mx].b.dec
      for j in child.gridItem.span[mx]:
        fixedCache[j].incl span
    else:
      autos.add child

  # setup cursor for current grid UiSize
  var cursor = (1.LinePos, 1.LinePos)
  var i = 0

  template incrCursor(amt, blk, outer: untyped) =
    ## increment major index
    cursor[0].inc
    ## increment minor when at end of major
    if cursor[0] >= gridTemplate.lines[mx].len():
      cursor = (1.LinePos, cursor[1] + 1)
      if cursor[1] >= gridTemplate.lines[my].len():
        break outer
      break blk
  block autoflow:
    while i < len(autos):
      block childBlock:
        ## increment cursor and index until one breaks the mold
        while cursor in fixedCache[cursor[0]]:
          incrCursor(1, childBlock, autoFlow)
        while not (cursor in fixedCache[cursor[0]]):
          autos[i].gridItem.span[mx] = cursor[0] .. cursor[0] + 1
          autos[i].gridItem.span[my] = cursor[1] .. cursor[1] + 1
          i.inc
          if i >= autos.len():
            break autoflow
          incrCursor(1, childBlock, autoFlow)

proc computeGridLayout*(
    gridTemplate: GridTemplate,
    node: GridNodes,
    children: seq[GridNodes],
) =
  ## implement full(ish) CSS grid algorithm here
  ## currently assumes that `N`, the ref object, has
  ## both `UiBox: UiBox` and `gridItem: GridItem` fields. 
  ## 
  ## this algorithm tries to follow the specification at:
  ##   https://www.w3.org/TR/css3-grid-layout/#grid-item-placement-algorithm
  ## 
  
  gridTemplate.computeLayout(node.box)
  # echo "gridTemplate: ", gridTemplate.repr

  var hasAutos = false
  for child in children:
    if child.gridItem == nil:
      # ensure all grid children have a GridItem
      child.gridItem = GridItem()
      hasAutos = true
    elif fixedCount(child.gridItem) == 4:
      # compute UiSizes for fixed children
      child.box = child.gridItem.computePosition(gridTemplate, child.box.wh)
    else:
      hasAutos = true
    
  # compute UiSizes for partially fixed children
  for child in children:
    if fixedCount(child.gridItem) in 1..3:
      # child.UiBox = child.gridItem.computeUiSize(gridTemplate, child.UiBox.wh)
      assert false, "todo: implement me!"

  # compute UiSizes for auto flow items
  if hasAutos:
    computeAutoFlow(gridTemplate, node, children)

  for child in children:
    if fixedCount(child.gridItem) == 0:
      if 0 notin child.gridItem.span[dcol] and
          0 notin child.gridItem.span[drow]:
        child.box = child.gridItem.computePosition(gridTemplate, child.box.wh)
