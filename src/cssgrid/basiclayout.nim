import numberTypes, constraints, gridtypes

import prettyprints

template XY*(node: GridNode, fs: static string): UiScalar =
  when fs == "x": node.box.x
  elif fs == "y": node.box.y
  else: {.error: "invalid field".}

template WH*(node: GridNode, fs: static string): UiScalar =
  when fs == "w": node.box.w
  elif fs == "h": node.box.h
  else: {.error: "invalid field".}

template WH*(node: GridNode, dir: GridDir): UiScalar =
  case dir
  of dcol: WH(node, "w")
  of drow: WH(node, "h")

template getParentBoxOrWindows*(node: GridNode): UiBox =
  if node.parent.isNil:
    node.frame.windowSize
  else:
    node.parent.box

# The height: auto behavior for block-level elements is determined through several steps:
# First, the element calculates the heights of all its children:
# For children with fixed heights (like height: 100px), those values are used
# For children with percentage heights, they're resolved against the parent if possible
# For children with auto height, this same process recurses down
# For text content, line height and font size determine the height
# Then it applies vertical spacing:
# Margins between children (with margin collapse rules)
# Padding of the element itself
# Borders of the element itself
# Special cases are considered:
# Floated elements
# Absolutely positioned elements (these don't contribute to height)
# Elements with overflow other than visible create new block formatting contexts

proc calculateContentSize*(node: GridNode, dir: GridDir): UiScalar =
  ## Recursively calculates the content size for a node by examining its children
  var maxSize = 0.UiScalar
  
  # First check the node's own size constraints
  match node.cxSize[dir]:
    UiValue(value):
      match value:
        UiFixed(coord):
          maxSize = coord
        UiContentMin(cmin):
          if cmin.float32 != float32.high():
            maxSize = cmin
        UiAuto(_):
          maxSize = node.WH(dir)
        UiFrac(_, _):
          maxSize = node.WH(dir)
        _: discard
    _: discard
  debugPrint "calculateContentSize:w: ", "kind=", node.cxSize[dir].kind

  # Then recursively check all children
  for child in node.children:
    let childSize = calculateContentSize(child, dir)
    maxSize = max(maxSize, childSize)
    
    # Add any additional space needed for grid gaps if parent has grid
    if not node.gridTemplate.isNil and node.children.len > 1:
      maxSize += node.gridTemplate.gaps[dir]

  return maxSize

template calcBasicConstraintImpl(node: GridNode, dir: static GridDir, f: untyped) =
  mixin getParentBoxOrWindows
  ## computes basic constraints for box'es when set
  ## this let's the use do things like set 90'pp (90 percent)
  ## of the box width post css grid or auto constraints layout
  # debugPrint "calcBasicConstraintImpl: ", "name= ", node.name
  let parentBox = node.getParentBoxOrWindows()
  template calcBasic(val: untyped): untyped =
    block:
      debugPrint "calcBasic: ", val
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
          debugPrint "CMINS: ", cmins
          for n in node.children:
            when astToStr(f) == "w":
              res = min(node.box.x + node.box.w, res)
            elif astToStr(f) == "h":
              res = min(node.box.y + node.box.h, res)
        UiContentMax(cmaxs):
          debugPrint "CMAXS: ", cmaxs
          for n in node.children:
            when astToStr(f) == "w":
              res = max(node.box.x + node.box.w, res)
            elif astToStr(f) == "h":
              res = max(node.box.y + node.box.h, res)
      res

  # debugPrint "CONTENT csValue: ", "node = ", node.name, " d = ", repr(dir), " w = ", node.box.w, " h = ", node.box.h
  let csValue =
    when astToStr(f) in ["w", "h"]:
      node.cxSize[dir]
    else:
      node.cxOffset[dir]
  debugPrint "csValue: ", csValue, "f: ", astToStr(f)
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

proc calculateMinOrMaxes(node: GridNode, fs: static string, doMax: static bool): UiScalar =
  for n in node.children:
    when fs == "w":
      when doMax:
        result = max(n.box.x + n.box.w, result)
      else:
        result = min(n.box.x + n.box.w, result)
    elif fs == "h":
      when doMax:
        result = max(n.box.y + n.box.h, result)
      else:
        result = min(n.box.y + n.box.h, result)

template calcBasicConstraintPostImpl(node: GridNode, dir: static GridDir, f: untyped) =
  ## computes basic constraints for box'es when set
  ## this let's the use do things like set 90'pp (90 percent)
  ## of the box width post css grid or auto constraints layout
  debugPrint "calcBasicConstraintPostImpl: ", "name =", node.name, "boxH=", node.box.h
  let parentBox =
    if node.parent.isNil:
      node.frame[].windowSize
    else:
      node.parent[].box
  template calcBasic(val: untyped): untyped =
    block:
      var res: UiScalar
      match val:
        UiContentMin(cmins):
          res = node.calculateMinOrMaxes(astToStr(f), doMax=false)
        UiContentMax(cmaxs):
          res = node.calculateMinOrMaxes(astToStr(f), doMax=true)
          debugPrint "CONTENT MAX: ", "node =", node.name, "res =", res, "d =", repr(dir), "children =", node.children.mapIt((it.name, it.box.w, it.box.h))
        _:
          res = node.box.f
      res

  let csValue =
    when astToStr(f) in ["w", "h"]:
      node.cxSize[dir]
    else:
      node.cxOffset[dir]
  
  debugPrint "CONTENT csValue: ", "node =", node.name, "d =", repr(dir), "w =", node.box.w, "h =", node.box.h
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
