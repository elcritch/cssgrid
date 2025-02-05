import numberTypes, constraints, gridtypes, parser

proc calculateMinOrMaxes*(node: GridNode, fs: static string, doMax: static bool): UiSize =
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

template calcBasicConstraintImpl(node: GridNode, dir: static GridDir, f: untyped) =
  ## computes basic constraints for box'es when set
  ## this let's the use do things like set 90'pp (90 percent)
  ## of the box width post css grid or auto constraints layout
  trace "calcBasicConstraintImpl: ", name= node.name
  let parentBox =
    if node.parent.isNil:
      node.frame[].windowSize
    else:
      node.parent[].box
  template calcBasic(val: untyped): untyped =
    block:
      var res: UiSize
      match val:
        UiAuto(_):
          when astToStr(f) in ["w"]:
            res = parentBox.f - node.box.x
          elif astToStr(f) in ["h"]:
            res = parentBox.f - node.box.y
        UiFixed(coord):
          res = coord.UiSize
        UiFrac(frac):
          node.checkParent()
          res = frac.UiSize * node.parent[].box.f
        UiPerc(perc):
          let ppval =
            when astToStr(f) == "x":
              parentBox.w
            elif astToStr(f) == "y":
              parentBox.h
            else:
              parentBox.f
          res = perc.UiSize / 100.0.UiSize * ppval
        UiContentMin(cmins):
          res = node.calculateMinOrMaxes(astToStr(f), doMax=false)
        UiContentMax(cmaxs):
          res = node.calculateMinOrMaxes(astToStr(f), doMax=true)
      res

  trace "CONTENT csValue: ", node = node.name, d = repr(dir), w = node.box.w, h = node.box.h
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
  trace "calcBasicConstraintImpl:done: ", name= node.name, boxH= node.box.h

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
