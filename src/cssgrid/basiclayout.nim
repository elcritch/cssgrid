import numberTypes, constraints, gridtypes

import prettyprints

proc calculateMinOrMaxes*(node: GridNode, fs: static string, doMax: static bool): UiScalar =
  for n in node.children:
    when fs == "w":
      when doMax:
        result = max(n.box.w + n.box.y, result)
      else:
        result = min(n.box.w + n.box.y, result)
    elif fs == "h":
      when doMax:
        result = max(n.box.h + n.box.y, result)
      else:
        result = min(n.box.h + n.box.y, result)

template getParentBoxOrWindows*(node: GridNode): UiBox =
  if node.parent.isNil:
    node.frame.windowSize
  else:
    node.parent.box

proc calculateContentSize(node: GridNode, dir: GridDir): UiScalar =
  ## Recursively calculates the content size for a node by examining its children
  var maxSize = 0.UiScalar
  
  # First check the node's own size constraints
  if dir == dcol:
    match node.cxSize[dcol]:
      UiValue(value):
        match value:
          UiFixed(coord):
            maxSize = max(maxSize, coord)
          UiContentMin(cmin):
            if cmin.float32 != float32.high():
              maxSize = max(maxSize, cmin)
          UiAuto(_):
            maxSize = max(maxSize, node.box.w)
            debugPrint "calculateContentSize:w: ", "auto=", maxSize
          UiFrac(_, _):
            maxSize = max(maxSize, node.box.w)
            debugPrint "calculateContentSize:w: ", "frac=", maxSize
          _: discard
      _: discard
  else:
    match node.cxSize[drow]:
      UiValue(value):
        match value:
          UiFixed(coord):
            maxSize = max(maxSize, coord)
          UiContentMin(cmin):
            if cmin.float32 != float32.high():
              maxSize = max(maxSize, cmin)
          UiAuto(_):
            maxSize = max(maxSize, node.box.h)
            debugPrint "calculateContentSize:h: ", "auto=", maxSize
          UiFrac(_, _):
            maxSize = max(maxSize, node.box.h)
            debugPrint "calculateContentSize:h: ", "frac=", maxSize
          _: discard
      _: discard

  # Then recursively check all children
  for child in node.children:
    let childSize = calculateContentSize(child, dir)
    maxSize = max(maxSize, childSize)
    
    # Add any additional space needed for grid gaps if parent has grid
    if not node.gridTemplate.isNil and node.children.len > 1:
      maxSize += node.gridTemplate.gaps[dir]

  return maxSize

proc computeContentSizes*(grid: GridTemplate, children: seq[GridNode]) =
  ## Computes content min/max for each grid track based on children
  ## including nested children for auto tracks
  var contentSized: array[GridDir, set[int16]]
  for dir in [dcol, drow]:
    for i in 0 ..< grid.lines[dir].len():
      if isContentSized(grid.lines[dir][i].track):
        contentSized[dir].incl(i.int16)

  # Process each child and track
  for child in children:
    let cspan = child.gridItem.span
    for dir in [dcol, drow]:
      debugPrint "calculateContentSize:", child.name
      if cspan[dir].len()-1 == 1 and (cspan[dir].a-1) in contentSized[dir]:
        template track(): auto = grid.lines[dir][cspan[dir].a-1].track
        
        # Calculate size recursively including all nested children
        let contentSize = calculateContentSize(child, dir)
        debugPrint "calculateContentSize:", child.name, "contentSize=", contentSize, "track().value=", track().value
        
        # Update track size based on content
        if track().value.kind == UiAuto:
          track().value.amin = contentSize
        elif track().value.kind == UiFrac:
          track().value.fmin = contentSize
        elif track().value.kind == UiContentMin:
          track().value.cmin = min(contentSize, track().value.cmin)
        elif track().value.kind == UiContentMax:
          track().value.cmax = max(contentSize, track().value.cmax)
        else:
          assert false, "shouldn't reach here " & $track().value.kind

template calcBasicConstraintImpl(node: GridNode, dir: static GridDir, f: untyped) =
  mixin getParentBoxOrWindows
  ## computes basic constraints for box'es when set
  ## this let's the use do things like set 90'pp (90 percent)
  ## of the box width post css grid or auto constraints layout
  # debugPrint "calcBasicConstraintImpl: ", "name= ", node.name
  let parentBox = node.getParentBoxOrWindows()
  template calcBasic(val: untyped): untyped =
    block:
      var res: UiScalar
      match val:
        UiAuto(_):
          when astToStr(f) in ["w"]:
            res = parentBox.f - node.box.x
          elif astToStr(f) in ["h"]:
            res = parentBox.f - node.box.y
        UiFixed(coord):
          res = coord.UiScalar
        UiFrac(frac):
          res = frac.UiScalar * node.parent[].box.f
        UiPerc(perc):
          let ppval =
            when astToStr(f) == "x":
              parentBox.w
            elif astToStr(f) == "y":
              parentBox.h
            else:
              parentBox.f
          res = perc.UiScalar / 100.0.UiScalar * ppval
        UiContentMin(cmins):
          res = node.calculateMinOrMaxes(astToStr(f), doMax=false)
        UiContentMax(cmaxs):
          res = node.calculateMinOrMaxes(astToStr(f), doMax=true)
      res

  # debugPrint "CONTENT csValue: ", "node = ", node.name, " d = ", repr(dir), " w = ", node.box.w, " h = ", node.box.h
  let csValue =
    when astToStr(f) in ["w", "h"]:
      node.cxSize[dir]
    else:
      node.cxOffset[dir]
  match csValue:
    UiNone:
      discard
    UiSum(ls, rs):
      let lv = ls.calcBasic()
      let rv = rs.calcBasic()
      node.box.f = lv + rv
    UiMin(ls, rs):
      let lv = ls.calcBasic()
      let rv = rs.calcBasic()
      node.box.f = min(lv, rv)
    UiMax(ls, rs):
      let lv = ls.calcBasic()
      let rv = rs.calcBasic()
      node.box.f = max(lv, rv)
    UiMinMax(ls, rs):
      discard
    UiValue(value):
      node.box.f = calcBasic(value)
    UiEnd:
      discard
  # debugPrint "calcBasicConstraintImpl:done: ", " name= ", node.name, " boxH= ", node.box.h

template calcBasicConstraintPostImpl(node: GridNode, dir: static GridDir, f: untyped) =
  ## Computes post-layout adjustments to basic constraints
  ## This runs after the main layout pass to handle any final adjustments
  ## needed for proper positioning and sizing
  debugPrint "calcBasicConstraintPostImpl: ", " name = ", node.name
  let parentBox = node.getParentBoxOrWindows()

  template calcBasicPost(val: untyped): untyped =
    block:
      var res: UiScalar
      match val:
        UiAuto(_):
          when astToStr(f) in ["w"]:
            # For width, adjust based on parent width and current x position
            if not node.parent.isNil and not node.parent.gridTemplate.isNil:
              # If parent has grid, keep current width
              res = node.box.f
            else:
              # Otherwise fill available space
              res = parentBox.f - node.box.x
          elif astToStr(f) in ["h"]:
            # Similar handling for height
            if not node.parent.isNil and not node.parent.gridTemplate.isNil:
              res = node.box.f
            else:
              res = parentBox.f - node.box.y
        UiFrac(frac):
          # Fraction of remaining space
          if not node.parent.isNil:
            when astToStr(f) in ["w"]:
              let availableSpace = parentBox.f - node.box.x
              res = frac.UiScalar * availableSpace
            elif astToStr(f) in ["h"]:
              let availableSpace = parentBox.f - node.box.y
              res = frac.UiScalar * availableSpace
        UiFixed(coord):
          # Fixed values remain unchanged
          res = coord.UiScalar
        UiPerc(perc):
          # Percentage calculations based on parent size
          let ppval =
            when astToStr(f) == "x":
              parentBox.w
            elif astToStr(f) == "y":
              parentBox.h
            else:
              parentBox.f
          res = perc.UiScalar / 100.0.UiScalar * ppval
        UiContentMin(cmins):
          # Keep existing size if it's content-based
          res = node.box.f
        UiContentMax(cmaxs):
          # Keep existing size if it's content-based
          res = node.box.f
      res

  debugPrint "POST CONTENT csValue: ", " node = ", node.name, " d = ", repr(dir), " w = ", node.box.w, " h = ", node.box.h
  let csValue =
    when astToStr(f) in ["w", "h"]:
      node.cxSize[dir]
    else:
      node.cxOffset[dir]
  
  match csValue:
    UiNone:
      discard
    UiSum(ls, rs):
      let lv = ls.calcBasicPost()
      let rv = rs.calcBasicPost()
      node.box.f = lv + rv
    UiMin(ls, rs):
      let lv = ls.calcBasicPost()
      let rv = rs.calcBasicPost()
      node.box.f = min(lv, rv)
    UiMax(ls, rs):
      let lv = ls.calcBasicPost()
      let rv = rs.calcBasicPost()
      node.box.f = max(lv, rv)
    UiMinMax(ls, rs):
      # For post-processing, use the actual computed size if within bounds,
      # otherwise clamp to the nearest bound
      let lv = ls.calcBasicPost()
      let rv = rs.calcBasicPost()
      if node.box.f < lv:
        node.box.f = lv
      elif node.box.f > rv:
        node.box.f = rv
    UiValue(value):
      node.box.f = calcBasicPost(value)
    UiEnd:
      discard

  debugPrint "calcBasicConstraintPostImpl:done: ", " name = ", node.name, " boxH = ", node.box.h


proc calcBasicConstraint*(node: GridNode, dir: static GridDir, isXY: static bool) =
  ## calcuate sizes of basic constraints per field x/y/w/h for each node
  when isXY == true and dir == dcol:
    calcBasicConstraintImpl(node, dir, x)
  elif isXY == true and dir == drow:
    calcBasicConstraintImpl(node, dir, y)
  # w & h need to run after x & y
  elif isXY == false and dir == dcol:
    calcBasicConstraintImpl(node, dir, w)
  elif isXY == false and dir == drow:
    calcBasicConstraintImpl(node, dir, h)

proc calcBasicConstraintPost*(node: GridNode, dir: static GridDir, isXY: static bool) =
  ## calcuate sizes of basic constraints per field x/y/w/h for each node
  when isXY == true and dir == dcol:
    calcBasicConstraintPostImpl(node, dir, x)
  elif isXY == true and dir == drow:
    calcBasicConstraintPostImpl(node, dir, y)
  # w & h need to run after x & y
  elif isXY == false and dir == dcol:
    calcBasicConstraintPostImpl(node, dir, w)
  elif isXY == false and dir == drow:
    calcBasicConstraintPostImpl(node, dir, h)
