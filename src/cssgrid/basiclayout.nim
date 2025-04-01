import numberTypes, constraints, gridtypes
import basiccalcs
import prettyprints

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

{.push stackTrace: off.}

proc computeCssFuncs*(calc: Constraints, lhs, rhs: UiScalar): UiScalar =
    case calc:
    of UiNone, UiValue, UiEnd:
      return 0.0.UiScalar
    of UiAdd:
      result = lhs + rhs
    of UiSub:
      result = lhs - rhs
    of UiMin:
      result = min(lhs, rhs)
    of UiMax:
      result = max(lhs, rhs)
    of UiMinMax:
      return min(max(lhs, rhs), rhs)

proc getConstraintValue*(node: GridNode, dir: GridDir, calc: CalcKind): Constraint =
  case calc
  of XY:
    node.cxOffset[dir]
  of WH:
    node.cxSize[dir]
  of MINSZ:
    node.cxMin[dir]
  of MAXSZ:
    node.cxMax[dir]
  of PADXY:
    node.cxPadOffset[dir]
  of PADWH:
    node.cxPadSize[dir]

proc calcBasicConstraintImpl(
    node: GridNode,
    dir: GridDir,
    calc: CalcKind,
    f: var UiScalar,
    pf: UiScalar,
    f0 = 0.UiScalar, # starting point for field, e.g. for WH it'll be node XY's
    ppad = 0.UiScalar, # padding
) =
  mixin getParentBoxOrWindows
  ## computes basic constraints for box'es when set
  ## this let's the use do things like set 90'pp (90 percent)
  ## of the box width post css grid or auto constraints layout
  # debugPrint "calcBasicConstraintImpl: ", "name= ", node.name
  let parentBox = node.getParentBoxOrWindows()
  let isGridChild = not node.parent.isNil and not node.parent[].gridTemplate.isNil
  proc calcBasic(val: ConstraintSize): UiScalar =
    block:
      var res: UiScalar
      match val:
        UiAuto():
          if not isGridChild and calc == WH:
            res = pf - f0
        UiFixed(coord):
          res = coord.UiScalar
        UiFrac(frac):
          if not isGridChild:
            res = frac.UiScalar * pf
        UiPerc(perc):
          if not isGridChild:
            res = perc.UiScalar / 100.0.UiScalar * pf
        UiContentMin():
          res = node.childBMins(dir)
        UiContentMax():
          res = node.childBMaxs(dir)
        UiContentFit():
          # fit-content - calculate as max-content but clamped by available space
          res = node.childBMins(dir)
          res = min(res, pf)
      debugPrint "calcBasicCx:basic", "name=", node.name, "dir=", dir, "calc=", calc,
                  "val: ", val, "pf=", pf, "f0=", f0, "ppad=", ppad, "kind=", val.kind, " res: ", res
      res

  # debugPrint "CONTENT csValue: ", "name = ", node.name, " d = ", repr(dir), " w = ", node.box.w, " h = ", node.box.h
  let csValue = getConstraintValue(node, dir, calc)

  debugPrint "calcBasicCx", "name=", node.name, "csValue:", csValue, "dir=", dir, "calc=", calc
  case csValue.kind:
  of UiNone:
    discard
  of UiAdd, UiSub, UiMin, UiMax, UiMinMax:
    let (lv, rv) = csValue.cssFuncArgs()
    f = computeCssFuncs(csValue.kind, lv.calcBasic(), rv.calcBasic())
  
  of UiValue:
    f = calcBasic(csValue.value)
  of UiEnd:
    return

  # debugPrint "calcBasicCx:done: ", "name=", node.name, " val= ", f
  node.propogateCalcs(dir, calc, f)

  if calc == XY:
    debugPrint "calcBasicCx:calcXY:pad", "name=", node.name, "val=", f, "ppad=", ppad
    f += ppad
  # elif calc == WH:
  #   debugPrint "calcBasicCx:calcWH:pad", "name=", node.name, "val=", f, "ppad=", ppad
  #   f -= node.bpad.wh[dir]

  debugPrint "calcBasicCx:done: ", "name=", node.name, "dir=", dir, "calc=", calc, " val= ", f

proc calcBasicConstraintPostImpl(node: GridNode, dir: GridDir, calc: CalcKind, f: var UiScalar) =
  ## computes basic constraints for box'es when set
  ## this let's the use do things like set 90'pp (90 percent)
  ## of the box width post css grid or auto constraints layout
  debugPrint "\ncalcBasicConstraintPostImpl: ", "name=", node.name, "calc=", calc, "dir=", dir, "box=", f
  let parentBox = node.getParentBoxOrWindows()
  proc calcBasic(val: ConstraintSize, f: UiScalar): UiScalar =
    block:
      var res: UiScalar
      debugPrint "calcBasicPost: ", "name=", node.name, "val=", val
      let isGridChild = not node.parent.isNil and not node.parent[].gridTemplate.isNil
      match val:
        # UiAuto():
        #   if isGridChild and calc == WH:
        #     res = pf - f0
        UiContentMin():
          res = node.childBMinsPost(dir)
        UiContentMax():
            # I'm not sure about this, it's sorta hacky
            # but implement min/max content for non-grid nodes...
            res = UiScalar.low()
            for child in node.children:
              debugPrint "calcBasicPost:regular:child: ", "xy=", child.box.xy[dir], "wh=", child.box.wh[dir], "bmin=", child.bmin[dir]
              let childXY =  child.box.xy[dir]
              let childScreenSize = child.box.wh[dir] + childXY 
              let childScreenMax = child.bmax[dir] + childXY 
              debugPrint "calcBasicPost:max-content: ", "childScreenSize=", childScreenSize, "childScreeMax=", childScreenMax
              res = max(res, max(childScreenSize, childScreenMax))
            if res == UiScalar.low():
              res = 0.0.UiScalar
        UiContentFit():
            # I'm not sure about this, it's sorta hacky
            # but implement min/max content for non-grid nodes...
            res = UiScalar.low()
            for child in node.children:
              debugPrint "calcBasicPost:regular:child: ", "xy=", child.box.xy[dir], "wh=", child.box.wh[dir], "bmin=", child.bmin[dir]
              let childXY =  child.box.xy[dir]
              let childScreenSize = child.box.wh[dir] + childXY 
              res = max(res, childScreenSize)
              debugPrint "calcBasicPost:fit-content: ", "res=", res, "childScreenSize=", childScreenSize
            if res == UiScalar.low():
              res = 0.0.UiScalar
            #   # Clamp to available width (pf is parent width)
            #   res = min(res, pf)
            #   if res == UiScalar.low():
            #     res = 0.0.UiScalar
        _:
          res = f
      res

  let csValue = getConstraintValue(node, dir, calc)
  
  debugPrint "CONTENT csValue:post", "name=", node.name, "calc=", calc, "dir=", repr(dir), "w=", node.box.w, "h=", node.box.h, "csValue=", repr(csValue)
  case csValue.kind
  of UiNone:
    # handle UiNone for height to account for minimum sizes of contents
    if calc == WH and dir == drow:
      f = max(f, node.bmin.h)
  of UiValue:
    f = calcBasic(csValue.value, f)
  of UiAdd, UiSub, UiMin, UiMax, UiMinMax:
    let (ls, rs) = csValue.cssFuncArgs()
    if ls.isBasicContentSized() or rs.isBasicContentSized():
      let lv = calcBasic(ls, f)
      let rv = calcBasic(rs, f)
      if csValue.kind == UiMax:
        debugPrint "calcBasicPost:max: ", "name=", node.name, " lv= ", lv, "rv= ", rv, "rs= ", rs
      f = computeCssFuncs(csValue.kind, lv, rv)
  of UiEnd:
    discard

  node.propogateCalcs(dir, calc, f)

  if calc == MINSZ and f == UiScalar.high: 
    let fprev = f
    if node.cxSize[dir].isFixed():
      let parentSize = max(node.getParentBoxOrWindows().box.wh[dir], 0.0.UiScalar)
      f = node.cxSize[dir].getFixedSize(parentSize, 0.0.UiScalar)
      debugPrint "calcBasicConstraintPostImpl:adjust:minsz: ", "name=", node.name, "dir=", dir, "val=", f, "fprev=", fprev, "csValue=", csValue, "bpad:xy:", node.bpad.xy[dir], "bpad:wh:", node.bpad.wh[dir], "parentSize=", parentSize
    else:
      let v = node.childBMinsPost(dir).clamp(0.UiScalar, UiScalar.high)
      f = clamp(v + node.bpad.xy[dir] + node.bpad.wh[dir], 0.UiScalar, UiScalar.high)
      debugPrint "calcBasicConstraintPostImpl:adjust:minsz: ", "name=", node.name, "dir=", dir, "val=", f, "fprev=", fprev, "csValue=", csValue, "v=", v, "bpad:xy:", node.bpad.xy[dir], "bpad:wh:", node.bpad.wh[dir]

  debugPrint "calcBasicConstraintPostImpl:done: ", "name=", node.name, " box= ", f

import std/typetraits

proc calcBasicConstraint*(node: GridNode) =
  ## calcuate sizes of basic constraints per field x/y/w/h for each node
  var pboxes = node.getParentBoxOrWindows()
  var parentBox = pboxes.box
  var parentPad = pboxes.padding

  when distinctBase(UiScalar) is SomeInteger:
    parentBox.wh = parentBox.wh.clamp(0) - parentPad.wh
  else:
    parentBox.wh = parentBox.wh - parentPad.wh

  node.box = uiBox(UiScalar.low, UiScalar.low, UiScalar.low, UiScalar.low)
  node.bmin = uiSize(UiScalar.high, UiScalar.high)
  node.bmax = uiSize(UiScalar.low,UiScalar.low)
  debugPrint "calcBasicConstraint:start", "name=", node.name, "parentBox=", parentBox, node.box.w, parentBox.w, node.box.x-parentPad.x, -parentPad.w
  # printLayout(node)

  calcBasicConstraintImpl(node, dcol, PADXY, node.bpad.x, parentBox.x, parentPad.x)
  calcBasicConstraintImpl(node, drow, PADXY, node.bpad.y, parentBox.y, parentPad.y)
  calcBasicConstraintImpl(node, dcol, PADWH, node.bpad.w, parentBox.w, parentPad.w)
  calcBasicConstraintImpl(node, drow, PADWH, node.bpad.h, parentBox.h, parentPad.h)

  calcBasicConstraintImpl(node, dcol, MINSZ, node.bmin.w, parentBox.w)
  calcBasicConstraintImpl(node, drow, MINSZ, node.bmin.h, parentBox.h)
  calcBasicConstraintImpl(node, dcol, MAXSZ, node.bmax.w, parentBox.w)
  calcBasicConstraintImpl(node, drow, MAXSZ, node.bmax.h, parentBox.h)

  calcBasicConstraintImpl(node, dcol, XY, node.box.x, parentBox.w, parentBox.x, parentPad.x)
  calcBasicConstraintImpl(node, drow, XY, node.box.y, parentBox.h, parentBox.y, parentPad.y)
  debugPrint "calcBasicConstraint:start:wh", "name=", node.name, "parentBox=", parentBox, node.box.w, parentBox.w, node.box.x-parentPad.x, -parentPad.w
  calcBasicConstraintImpl(node, dcol, WH, node.box.w, parentBox.w-parentPad.w, node.box.x-parentPad.x, ppad= -parentPad.w)
  calcBasicConstraintImpl(node, drow, WH, node.box.h, parentBox.h-parentPad.h, node.box.y-parentPad.y, ppad= -parentPad.h)

  # printLayout(node)

proc calcBasicConstraintPost*(node: GridNode) =
  ## calcuate sizes of basic constraints per field x/y/w/h for each node
  debugPrint "calcBasicConstraintPost:start", "name=", node.name
  calcBasicConstraintPostImpl(node, dcol, XY, node.box.w)
  calcBasicConstraintPostImpl(node, drow, XY, node.box.h)

  calcBasicConstraintPostImpl(node, dcol, MINSZ, node.bmin.w)
  calcBasicConstraintPostImpl(node, drow, MINSZ, node.bmin.h)
  calcBasicConstraintPostImpl(node, dcol, MAXSZ, node.bmax.w)
  calcBasicConstraintPostImpl(node, drow, MAXSZ, node.bmax.h)
  # w & h need to run after x & y
  calcBasicConstraintPostImpl(node, dcol, WH, node.box.w)
  calcBasicConstraintPostImpl(node, drow, WH, node.box.h)
  debugPrint "calcBasicConstraintPost:done", "name=", node.name, "box=", node.box, "bmin=", node.bmin
