import numberTypes, constraints, gridtypes

import prettyprints

type
  CalcKind* {.pure.} = enum
    PADXY, PADWH, XY, WH, MINSZ, MAXSZ

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

proc childBMins(node: GridNode, dir: GridDir): UiScalar =
  result = UiScalar.low()
  for child in node.children:
    result = max(result, child.bmin[dir])
  # if result == UiScalar.high():
  #   result = 0.0.UiScalar

proc childBMaxs(node: GridNode, dir: GridDir): UiScalar =
  result = UiScalar.low()
  for child in node.children:
    result = max(result, child.bmax[dir])
  # if result == UiScalar.low():
  #   result = 0.0.UiScalar

proc childBMinsPost(node: GridNode, dir: GridDir): UiScalar =
  # I'm not sure about this, it's sorta hacky
  # but implement min/max content for non-grid nodes...
  result = UiScalar.high()
  for child in node.children:
    let childXY = child.box.xy[dir]
    let childScreenSize = child.box.wh[dir] + childXY
    let childScreenMin = child.bmin[dir] + childXY
    result = min(result, min(childScreenSize, childScreenMin))
    debugPrint "calcBasicPost:min-content: ", "res=", result, "childScreenSize=", childScreenSize, "childScreenMin=", childScreenMin
  if result == UiScalar.high():
    result = 0.0.UiScalar

proc propogateCalcs(node: GridNode, dir: GridDir, calc: CalcKind, f: var UiScalar) =
  if calc == MINSZ and f == UiScalar.high:
    match node.cxSize[dir]:
      UiValue(value):
        match value:
          UiFixed(coord):
            f = coord
          _: discard
      _: discard
  if calc == MAXSZ and f == UiScalar.low:
    match node.cxSize[dir]:
      UiValue(value):
        match value:
          UiFixed(coord):
            f = coord
          _: discard
      _: discard

proc calcBasicConstraintImpl(
    node: GridNode,
    dir: GridDir,
    calc: CalcKind,
    f: var UiScalar,
    pf: UiScalar,
    f0 = 0.UiScalar, # starting point for field, e.g. for WH it'll be node XY's
    pad = 0.UiScalar, # margin
) =
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
          if calc == WH and dir == dcol:
            res = pf - f0
          elif calc == WH and dir == drow:
            let mins = node.childBMins(dir)
            res = mins
        UiFixed(coord):
          res = coord.UiScalar
        UiFrac(frac):
          res = frac.UiScalar * pf
        UiPerc(perc):
          res = perc.UiScalar / 100.0.UiScalar * pf
        UiContentMin():
          res = node.childBMins(dir)
        UiContentMax():
          res = node.childBMaxs(dir)
        UiContentFit():
          # fit-content - calculate as max-content but clamped by available space
          res = node.childBMins(dir)
          res = min(res, pf)
        _:
          discard
      debugPrint "calcBasicCx:basic",  "name=", node.name, "dir=", dir, "calc=", calc, "val: ", val, "pf=", pf, "f0=", f0, "pad=", pad, "kind=", val.kind, " res: ", res
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
    of PADXY:
      node.cxPadOffset[dir]
    of PADWH:
      node.cxPadSize[dir]

  debugPrint "calcBasicCx", "name=", node.name, "csValue:", csValue, "dir=", dir, "calc=", calc
  match csValue:
    UiNone:
      # # handle UiNone for height to account for minimum sizes of contents
      # if calc == WH and dir == drow:
      #   f = node.bmin.h
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
      debugPrint "calcBasicCx:max: ", " name=", node.name, "dir=", dir, "calc=", calc, "lv=", lv, "rv= ", rv, "rs=", rs
    UiValue(value):
      f = calcBasic(value)
    UiMinMax(ls, rs):
      return
    UiEnd:
      return

  # debugPrint "calcBasicCx:done: ", " name= ", node.name, " val= ", f
  node.propogateCalcs(dir, calc, f)

  if calc == XY:
    f += pad
  elif calc == WH:
    f += pad

  debugPrint "calcBasicCx:done: ", " name= ", node.name, "dir=", dir, "calc=", calc, " val= ", f

proc calcBasicConstraintPostImpl(node: GridNode, dir: GridDir, calc: CalcKind, f: var UiScalar) =
  ## computes basic constraints for box'es when set
  ## this let's the use do things like set 90'pp (90 percent)
  ## of the box width post css grid or auto constraints layout
  debugPrint "\ncalcBasicConstraintPostImpl: ", "name=", node.name, "calc=", calc, "dir=", dir, "box=", f
  let parentBox = node.getParentBoxOrWindows()
  template calcBasic(val: untyped): untyped =
    block:
      var res: UiScalar
      debugPrint "calcBasicPost: ", "name=", node.name, "val=", val
      match val:
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
    of PADXY:
      node.cxPadOffset[dir]
    of PADWH:
      node.cxPadSize[dir]
  
  debugPrint "CONTENT csValue:post", "node=", node.name, "calc=", calc, "dir=", repr(dir), "w=", node.box.w, "h=", node.box.h
  match csValue:
    UiNone:
      discard
      # # handle UiNone for height to account for minimum sizes of contents
      if calc == WH and dir == drow:
        f = node.bmin.h
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
        debugPrint "calcBasicPost:max: ", " name= ", node.name, " lv= ", lv, "rv= ", rv, "rs= ", rs
        f = max(lv, rv)
    UiMinMax(ls, rs):
      return # doesn't make sense here
    UiValue(value):
      f = calcBasic(value)
    UiEnd:
      discard

  node.propogateCalcs(dir, calc, f)

  if calc == MINSZ and f == UiScalar.high:
    f = node.childBMins(dir) + node.bpad.xy[dir] + node.bpad.wh[dir]

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
  printLayout(node)

  calcBasicConstraintImpl(node, dcol, XY, node.box.x, parentBox.w, parentBox.x, parentPad.x)
  calcBasicConstraintImpl(node, drow, XY, node.box.y, parentBox.h, parentBox.y, parentPad.y)
  debugPrint "calcBasicConstraint:start:wh", "name=", node.name, "parentBox=", parentBox, node.box.w, parentBox.w, node.box.x-parentPad.x, -parentPad.w
  calcBasicConstraintImpl(node, dcol, WH, node.box.w, parentBox.w, node.box.x-parentPad.x, -parentPad.w)
  calcBasicConstraintImpl(node, drow, WH, node.box.h, parentBox.h, node.box.y-parentPad.y, -parentPad.h)

  calcBasicConstraintImpl(node, dcol, PADXY, node.bpad.x, parentBox.x, parentPad.x)
  calcBasicConstraintImpl(node, drow, PADXY, node.bpad.y, parentBox.y, parentPad.y)
  calcBasicConstraintImpl(node, dcol, PADWH, node.bpad.w, parentBox.w, parentPad.w)
  calcBasicConstraintImpl(node, drow, PADWH, node.bpad.h, parentBox.h, parentPad.h)

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

  calcBasicConstraintPostImpl(node, dcol, MINSZ, node.bmin.w)
  calcBasicConstraintPostImpl(node, drow, MINSZ, node.bmin.h)
  calcBasicConstraintPostImpl(node, dcol, MAXSZ, node.bmax.w)
  calcBasicConstraintPostImpl(node, drow, MAXSZ, node.bmax.h)
  # w & h need to run after x & y
  calcBasicConstraintPostImpl(node, dcol, WH, node.box.w)
  calcBasicConstraintPostImpl(node, drow, WH, node.box.h)
  debugPrint "calcBasicConstraintPost:done", "name=", node.name, "box=", node.box, "bmin=", node.bmin
