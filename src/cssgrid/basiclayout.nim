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

proc calcBasicConstraintImpl(node: GridNode, dir: GridDir, isXY: bool, f: var UiScalar, pf: UiScalar, f0 = 0.UiScalar) =
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
        UiAuto():
          if not isXY:
            res = pf - f0
        UiFixed(coord):
          res = coord.UiScalar
        UiFrac(frac):
          res = frac.UiScalar * pf
        UiPerc(perc):
          let ppval =
              pf
          res = perc.UiScalar / 100.0.UiScalar * ppval
        UiContentMin():
          return # run as post
        UiContentMax():
          return # run as post
      res

  # debugPrint "CONTENT csValue: ", "node = ", node.name, " d = ", repr(dir), " w = ", node.box.w, " h = ", node.box.h
  let csValue =
    if isXY:
      node.cxOffset[dir]
    else:
      node.cxSize[dir]
  debugPrint "csValue: ", csValue, "f: ", astToStr(f)
  match csValue:
    UiNone:
      discard
    UiAdd(ls, rs):
      let lv = ls.calcBasic()
      let rv = rs.calcBasic()
      f = lv + rv
    UiSub(ls, rs):
      let lv = ls.calcBasic()
      let rv = rs.calcBasic()
      f = lv - rv
    UiMin(ls, rs):
      let lv = ls.calcBasic()
      let rv = rs.calcBasic()
      f = min(lv, rv)
    UiMax(ls, rs):
      let lv = ls.calcBasic()
      let rv = rs.calcBasic()
      f = max(lv, rv)
    UiValue(value):
      f = calcBasic(value)
    UiMinMax(ls, rs):
      return
    UiEnd:
      return
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

proc calcBasicConstraintPostImpl(node: GridNode, dir: GridDir, isXY: bool, f: var UiScalar) =
  ## computes basic constraints for box'es when set
  ## this let's the use do things like set 90'pp (90 percent)
  ## of the box width post css grid or auto constraints layout
  debugPrint "calcBasicConstraintPostImpl: ", "name =", node.name, "boxH=", node.box.h
  let parentBox = node.getParentBoxOrWindows()
  template calcBasic(val: untyped): untyped =
    block:
      var res: UiScalar
      match val:
        UiContentMin():
          res = node.calculateMinOrMaxes(astToStr(f), doMax=false)
        UiContentMax():
          res = node.calculateMinOrMaxes(astToStr(f), doMax=true)
          debugPrint "CONTENT MAX: ", "node =", node.name, "res =", res, "d =", repr(dir), "children =", node.children.mapIt((it.name, it.box.w, it.box.h))
        _:
          res = f
      res

  let csValue =
    if isXY:
      node.cxOffset[dir]
    else:
      node.cxSize[dir]
  
  debugPrint "CONTENT csValue: ", "node =", node.name, "d =", repr(dir), "w =", node.box.w, "h =", node.box.h
  match csValue:
    UiNone:
      discard
    UiAdd(ls, rs):
      if ls.isBasicContentSized() or rs.isBasicContentSized():
        let lv = ls.calcBasic()
        let rv = rs.calcBasic()
        f = lv + rv
    UiSub(ls, rs):
      if ls.isBasicContentSized() or rs.isBasicContentSized():
        let lv = ls.calcBasic()
        let rv = rs.calcBasic()
        f = lv - rv
    UiMin(ls, rs):
      if ls.isBasicContentSized() or rs.isBasicContentSized():
        let lv = ls.calcBasic()
        let rv = rs.calcBasic()
        f = min(lv, rv)
    UiMax(ls, rs):
      if ls.isBasicContentSized() or rs.isBasicContentSized():
        let lv = ls.calcBasic()
        let rv = rs.calcBasic()
        f = max(lv, rv)
    UiMinMax(ls, rs):
      return # doesn't make sense here
    UiValue(value):
      return # doesn't make sense here
    UiEnd:
      discard

  debugPrint "calcBasicConstraintPostImpl:done: ", " name = ", node.name, " boxH = ", node.box.h


proc calcBasicConstraint*(node: GridNode, dir: static GridDir, isXY: static bool) =
  ## calcuate sizes of basic constraints per field x/y/w/h for each node
  let parentBox = node.getParentBoxOrWindows()
  when isXY == true and dir == dcol:
    calcBasicConstraintImpl(node, dir, isXY, node.box.x, parentBox.w)
  elif isXY == true and dir == drow:
    calcBasicConstraintImpl(node, dir, isXY, node.box.y, parentBox.h)
  # w & h need to run after x & y
  elif isXY == false and dir == dcol:
    calcBasicConstraintImpl(node, dir, isXY, node.box.w, parentBox.w, node.box.x)
  elif isXY == false and dir == drow:
    calcBasicConstraintImpl(node, dir, isXY, node.box.h, parentBox.h, node.box.y)

proc calcBasicConstraintPost*(node: GridNode, dir: static GridDir, isXY: static bool) =
  ## calcuate sizes of basic constraints per field x/y/w/h for each node
  when isXY == true and dir == dcol:
    calcBasicConstraintPostImpl(node, dir, isXY, node.box.w)
  elif isXY == true and dir == drow:
    calcBasicConstraintPostImpl(node, dir, isXY, node.box.h)
  # w & h need to run after x & y
  elif isXY == false and dir == dcol:
    calcBasicConstraintPostImpl(node, dir, isXY, node.box.w)
  elif isXY == false and dir == drow:
    calcBasicConstraintPostImpl(node, dir, isXY, node.box.h)
