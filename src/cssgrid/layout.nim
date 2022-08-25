import std/rationals
import patty

import basic, gridtypes, parser

export rationals, gridtypes


let defaultLine = GridLine(track: mkFrac(1))

proc newGridTemplate*(
  columns = @[defaultLine],
  rows = @[defaultLine],
): GridTemplate =
  new(result)
  result.columns = columns
  result.rows = rows
  result.autoColumns = mkFixed(0)
  result.autoRows = mkFixed(0)

proc newGridItem*(): GridItem =
  new(result)

proc computeLineLayout*(
    lines: var seq[GridLine],
    length: UiScalar,
    spacing: UiScalar,
) =
  var
    fixed = 0'ui
    totalFracs = 0.0'ui
    totalAutos = 0
  
  # compute total fixed sizes and fracs
  for grdLn in lines:
    match grdLn.track:
      grFixed(coord): fixed += coord
      grFrac(frac): totalFracs += frac.UiScalar
      grAuto(): totalAutos += 1
      grPerc(): discard
      grEnd(): discard
  fixed += spacing * UiScalar(lines.len() - 1)

  var
    freeSpace = length - fixed
    remSpace = max(freeSpace, 0.0'ui)
  
  # frac's
  for grdLn in lines.mitems():
    if grdLn.track.kind == grFrac:
      grdLn.width =
        freeSpace * grdLn.track.frac.UiScalar/totalFracs
      remSpace -= max(grdLn.width, 0.0'ui)
    elif grdLn.track.kind == grFixed:
      grdLn.width = grdLn.track.coord
    elif grdLn.track.kind == grPerc:
      grdLn.width = length * UiScalar(grdLn.track.perc / 100.0)
      remSpace -= max(grdLn.width, 0.0'ui)
  
  # auto's
  for grdLn in lines.mitems():
    if grdLn.track.kind == grAuto:
      grdLn.width = remSpace / totalAutos.UiScalar

  var cursor = 0.0'ui
  for grdLn in lines.mitems():
    grdLn.start = cursor
    cursor += grdLn.width + spacing

proc computeLayout*(grid: GridTemplate, box: Box) =
  ## computing grid layout
  if grid.columns[^1].track.kind != grEnd:
    grid.columns.add initGridLine(mkEndTrack())
  if grid.rows[^1].track.kind != grEnd:
    grid.rows.add initGridLine(mkEndTrack())
  # The free space is calculated after any non-flexible items. In 
  let
    colLen = box.w
    rowLen = box.h
  grid.columns.computeLineLayout(length=colLen, spacing=grid.columnGap)
  grid.rows.computeLineLayout(length=rowLen, spacing=grid.rowGap)

proc reComputeLayout(grid: GridTemplate) =
  var w, h: float32
  for col in grid.columns:
    if col.track.kind == grEnd:
      w = col.start.float32
      break
  for row in grid.rows:
    if row.track.kind == grEnd:
      h = row.start.float32
      break
  # echo "reCompute"
  grid.computeLayout(initBox(0, 0, w, h))

template parseGridTemplateColumns*(gridTmpl, args: untyped) =
  gridTemplateImpl(gridTmpl, args, columns)

template parseGridTemplateRows*(gridTmpl, args: untyped) =
  gridTemplateImpl(gridTmpl, args, rows)

proc findLine(index: GridIndex, lines: seq[GridLine]): int16 =
  for i, line in lines:
    if index.line in line.aliases:
      return int16(i+1)
  raise newException(KeyError, "couldn't find index: " & repr index)

proc getGrid(lines: seq[GridLine], idx: int): UiScalar =
  # if idx == -2: lines[idx-1].start else: lines[^1].start
  lines[idx-1].start

proc setGridSpans(
    item: GridItem,
    grid: GridTemplate,
    contentSize: Position
) =
  ## computing grid layout
  template gridAutoInsert(target, index, lines, idx, cz: untyped) =
    assert idx <= 1000, "max grids exceeded"
    if idx >= grid.`lines`.len():
      while idx >= grid.`lines`.len():
        let offset = grid.`lines`.len() - 1
        var ln = initGridLine(track = grid.`auto lines`)
        if offset+1 == idx and ln.track.kind == grFixed:
          # echo "insert: ", offset+1, "@", idx, "/", grid.`lines`.len()
          ln.track.coord = max(ln.track.coord, cz)
        grid.`lines`.insert(ln, offset)
      grid.reComputeLayout()
  
  template setSpan(index, lines, cz: untyped): int16 =
    ## todo: clean this up? maybe use static bools for col vs row
    if not item.`index`.isName:
      let idx = item.`index`.line.int - 1
      gridAutoInsert(target, index, lines, idx, cz)
      item.`index`.line.int16
    else:
      findLine(item.`index`, grid.`lines`)
  assert not item.isNil

  if item.span[dcol].a == 0:
    item.span[dcol].a = setSpan(columnStart, columns, 0)
  if item.span[dcol].b == 0:
    item.span[dcol].b = setSpan(columnEnd, columns, contentSize.x)

  if item.span[drow].a == 0:
    item.span[drow].a = setSpan(rowStart, rows, 0)
  if item.span[drow].b == 0:
    item.span[drow].b = setSpan(rowEnd, rows, contentSize.x)

proc computePosition*(
    item: GridItem,
    grid: GridTemplate,
    contentSize: Position
): Box =
  ## computing grid layout
  assert not item.isNil
  item.setGridSpans(grid, contentSize)

  # set columns
  result.x = grid.columns.getGrid(item.span[dcol].a)
  let rxw = grid.columns.getGrid(item.span[dcol].b)
  let rww = (rxw - result.x) - grid.columnGap
  case grid.justifyItems:
  of gcStretch:
    result.w = rww
  of gcCenter:
    result.x = result.x + (rww - contentSize.x)/2.0
    result.w = contentSize.x
  of gcStart:
    result.w = contentSize.x
  of gcEnd:
    result.x = rxw - contentSize.x
    result.w = contentSize.x

  # set rows
  result.y = grid.rows.getGrid(item.span[drow].a)
  let ryh = grid.rows.getGrid(item.span[drow].b)
  let rhh = (ryh - result.y) - grid.rowGap
  case grid.alignItems:
  of gcStretch:
    result.h = rhh
  of gcCenter:
    result.y = result.y + (rhh - contentSize.y)/2.0
    result.h = contentSize.y
  of gcStart:
    result.h = contentSize.y
  of gcEnd:
    result.y = ryh - contentSize.y
    result.h = contentSize.y

proc fixedCount*(gridItem: GridItem): range[0..4] =
  if gridItem.columnStart.line.int != 0: result.inc
  if gridItem.columnEnd.line.int != 0: result.inc
  if gridItem.rowStart.line.int != 0: result.inc
  if gridItem.rowEnd.line.int != 0: result.inc

proc isAutoPositioned*(gridItem: GridItem): bool =
  gridItem.fixedCount() == 0

proc `in`(cur: (LinePos, LinePos), col: HashSet[GridSpan]): bool =
  for span in col:
    if cur[0] in span[dcol] and cur[1] in span[drow]:
      return true

proc computeAutoFlow[N](
    gridTemplate: GridTemplate,
    node: N,
    allNodes: seq[N],
) =
  let mx = dcol
  let my = drow
  template mjLines(x: untyped): untyped = x.columns
  template mnLines(x: untyped): untyped = x.rows

  # setup caches
  var autos = newSeqOfCap[N](allNodes.len())
  var fixedCache = newTable[LinePos, HashSet[GridSpan]]()
  for i in 1..gridTemplate.mjLines.len():
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

  # setup cursor for current grid position
  var cursor = (1.LinePos, 1.LinePos)
  var i = 0

  template incrCursor(amt, blk, outer: untyped) =
    ## increment major index
    cursor[0].inc
    ## increment minor when at end of major
    if cursor[0] >= gridTemplate.mjLines.len():
      cursor = (1.LinePos, cursor[1] + 1)
      if cursor[1] >= gridTemplate.mnLines.len():
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

proc computeGridLayout*[N](
    gridTemplate: GridTemplate,
    node: N,
    children: seq[N],
) =
  ## implement full(ish) CSS grid algorithm here
  ## currently assumes that `N`, the ref object, has
  ## both `box: Box` and `gridItem: GridItem` fields. 
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
      # compute positions for fixed children
      child.box = child.gridItem.computePosition(gridTemplate, child.box.wh)
    else:
      hasAutos = true
    
  # compute positions for partially fixed children
  for child in children:
    if fixedCount(child.gridItem) in 1..3:
      # child.box = child.gridItem.computePosition(gridTemplate, child.box.wh)
      assert false, "todo: implement me!"

  # compute positions for auto flow items
  if hasAutos:
    computeAutoFlow(gridTemplate, node, children)

  for child in children:
    if fixedCount(child.gridItem) == 0:
      if 0 notin child.gridItem.span[dcol] and
          0 notin child.gridItem.span[drow]:
        child.box = child.gridItem.computePosition(gridTemplate, child.box.wh)
