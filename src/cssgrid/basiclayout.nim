import numberTypes, constraints, gridtypes

import prettyprints

type
  CalcKind* {.pure.} = enum
    XY, WH, MINSZ, MAXSZ

# template XY*(node: GridNode, fs: static string): UiScalar =
#   when fs == "x": node.box.x
#   elif fs == "y": node.box.y
#   else: {.error: "invalid field".}

# template WH*(node: GridNode, fs: static string): UiScalar =
#   when fs == "w": node.box.w
#   elif fs == "h": node.box.h
#   else: {.error: "invalid field".}

# template WH*(node: GridNode, dir: GridDir): UiScalar =
#   case dir
#   of dcol: WH(node, "w")
#   of drow: WH(node, "h")

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

proc calcBasicConstraintImpl(node: GridNode, dir: GridDir, calc: CalcKind, f: var UiScalar, pf: UiScalar, f0 = 0.UiScalar) =
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
        UiAuto():
          if calc == WH:
            res = max(pf - f0, 0)
        UiFixed(coord):
          res = coord.UiScalar
        UiFrac(frac):
          res = frac.UiScalar * pf
        UiPerc(perc):
          let ppval = pf
          res = perc.UiScalar / 100.0.UiScalar * ppval
        # UiContentMin():
        #   return # run as post
        # UiContentMax():
        #   return # run as post
        UiContentMin():
          res = UiScalar.high()
          for child in node.children:
            res = min(res, child.bmin[dir])
        UiContentMax():
          res = UiScalar.low()
          for child in node.children:
            res = max(res, child.bmax[dir])
      debugPrint "calcBasic: ", node.name, "calc=", calc, "val: ", val, " res: ", res
      res

  # debugPrint "CONTENT csValue: ", "node = ", node.name, " d = ", repr(dir), " w = ", node.box.w, " h = ", node.box.h
  let csValue =
    case calc
    of XY:
      node.cxOffset[dir]
    of WH:
      node.cxSize[dir]
    of MINSZ:
      node.cxMin[dir]
    of MAXSZ:
      node.cxMax[dir]

  debugPrint "csValue: ", csValue, "calc: ", calc
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

proc calculateMin(node: GridNode, calc: CalcKind): UiScalar =
  for n in node.children:
    case calc:
    of WH:
      result = max(n.box.x + n.box.w, result)
      result = min(n.box.y + n.box.h, result)
    of XY:
      result = max(n.box.x + n.box.w, result)
      result = min(n.box.y + n.box.h, result)

    #   else:
    #     result = min(n.box.x + n.box.w, result)
    # elif fs == "h":
    #   when doMax:
    #     result = max(n.box.y + n.box.h, result)
    #   else:
    #     result = min(n.box.y + n.box.h, result)

proc calcBasicConstraintPostImpl(node: GridNode, dir: GridDir, calc: CalcKind, f: var UiScalar) =
  ## computes basic constraints for box'es when set
  ## this let's the use do things like set 90'pp (90 percent)
  ## of the box width post css grid or auto constraints layout
  debugPrint "\ncalcBasicConstraintPostImpl: ", "name=", node.name, "calc=", calc, "dir=", dir, "box=", f
  let parentBox = node.getParentBoxOrWindows()
  template calcBasic(val: untyped): untyped =
    block:
      var res: UiScalar
      debugPrint "calcBasic: ", "val=", val
      match val:
        UiContentMin():
          res = UiScalar.low()
          for child in node.children:
            debugPrint "calcBasic:child: ", "xy=", child.box.xy[dir], "bmin=", child.bmin[dir]
            res = max(res, child.box.xy[dir] + child.bmin[dir])
        UiContentMax():
          res = UiScalar.low()
          for child in node.children:
            if child.bmin[dir] != UiScalar.low:
              res = max(res, child.box.xy[dir] + child.bmax[dir])
        _:
          res = f
      res

  let csValue =
    case calc
    of XY:
      node.cxOffset[dir]
    of WH:
      node.cxSize[dir]
    of MINSZ:
      node.cxMin[dir]
    of MAXSZ:
      node.cxMax[dir]
  
  debugPrint "CONTENT csValue:post", "node =", node.name, "calc=", calc, "d =", repr(dir), "w =", node.box.w, "h =", node.box.h
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
      f = calcBasic(value)
    UiEnd:
      discard

  debugPrint "calcBasicConstraintPostImpl:done: ", "name=", node.name, " box= ", f


proc calcBasicConstraint*(node: GridNode) =
  ## calcuate sizes of basic constraints per field x/y/w/h for each node
  let parentBox = node.getParentBoxOrWindows()
  node.bmin = uiSize(UiScalar.high,UiScalar.high)
  node.bmax = uiSize(UiScalar.low,UiScalar.low)
  debugPrint "calcBasicConstraint:start", "name=", node.name
  calcBasicConstraintImpl(node, dcol, XY, node.box.x, parentBox.w)
  calcBasicConstraintImpl(node, drow, XY, node.box.y, parentBox.h)
  calcBasicConstraintImpl(node, dcol, WH, node.box.w, parentBox.w, node.box.x)
  calcBasicConstraintImpl(node, drow, WH, node.box.h, parentBox.h, node.box.y)
  calcBasicConstraintImpl(node, dcol, MINSZ, node.bmin.w, parentBox.w)
  calcBasicConstraintImpl(node, drow, MINSZ, node.bmin.h, parentBox.h)
  calcBasicConstraintImpl(node, dcol, MAXSZ, node.bmax.w, parentBox.w)
  calcBasicConstraintImpl(node, drow, MAXSZ, node.bmax.h, parentBox.h)
  printLayout(node)

proc calcBasicConstraintPost*(node: GridNode) =
  ## calcuate sizes of basic constraints per field x/y/w/h for each node
  debugPrint "calcBasicConstraintPost:start", "name=", node.name
  calcBasicConstraintPostImpl(node, dcol, XY, node.box.w)
  calcBasicConstraintPostImpl(node, drow, XY, node.box.h)
  # w & h need to run after x & y
  calcBasicConstraintPostImpl(node, dcol, WH, node.box.w)
  calcBasicConstraintPostImpl(node, drow, WH, node.box.h)

  calcBasicConstraintPostImpl(node, dcol, MINSZ, node.bmin.w)
  calcBasicConstraintPostImpl(node, drow, MINSZ, node.bmin.h)
  calcBasicConstraintPostImpl(node, dcol, MAXSZ, node.bmax.w)
  calcBasicConstraintPostImpl(node, drow, MAXSZ, node.bmax.h)
  debugPrint "calcBasicConstraintPost:done", "name=", node.name, "box=", node.box, "bmin=", node.bmin
