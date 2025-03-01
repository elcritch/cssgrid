import typetraits

import unittest
import cssgrid/numberTypes
import cssgrid/gridtypes
import cssgrid/layout
import cssgrid/parser
import cssgrid/prettyprints

type
  TestNode* = ref object
    box*, bpad*: UiBox
    bmin*, bmax*: UiSize
    name*: string
    parent*: TestNode
    children*: seq[TestNode]
    cxSize*: array[GridDir, Constraint] = [csAuto(), csNone()]  # For width/height
    cxOffset*: array[GridDir, Constraint] = [csAuto(), csAuto()] # For x/y positions
    cxMin*: array[GridDir, Constraint] = [csNone(), csNone()] # For x/y positions
    cxMax*: array[GridDir, Constraint] = [csNone(), csNone()] # For x/y positions
    cxPadOffset*: array[GridDir, Constraint] = [csNone(), csNone()] # For padding x/y positions
    cxPadSize*: array[GridDir, Constraint] = [csNone(), csNone()] # For padding width/height
    gridItem*: GridItem
    gridTemplate*: GridTemplate
    frame*: Frame

  Frame* = ref object
    windowSize*: UiBox

proc `box=`*[T](v: T, box: UiBox) = 
  v.box = box

template getParentBoxOrWindows*(node: GridNode): tuple[box, padding: UiBox] =
  if node.parent.isNil:
    (box: node.frame.windowSize, padding: uiBox(0,0,0,0))
  else:
    (box: node.parent.box, padding: node.parent.bpad)

proc newTestNode*(name: string, parent: TestNode = nil): TestNode =
  result = TestNode(
    name: name,
    box: uiBox(0, 0, 0, 0),
    children: @[],
    frame: Frame(windowSize: uiBox(0, 0, 800, 600)),
    parent: parent
  )
  if parent != nil:
    parent.children.add(result)

proc newTestNode*(name: string, x, y, w, h: float32, parent: TestNode = nil): TestNode =
  result = TestNode(
    name: name,
    box: uiBox(0, 0, 0, 0),
    cxOffset: [csFixed(x), csFixed(y)],
    cxSize: [csFixed(w), csFixed(h)],
    children: @[],
    frame: Frame(windowSize: uiBox(0, 0, 800, 600)),
    parent: parent
  )
  if parent != nil:
    parent.children.add(result)

# addChild proc removed to enforce the use of parent parameter in constructors

# Convenience function to create a node with children
proc newTestTree*(name: string, children: varargs[TestNode]): TestNode =
  result = newTestNode(name)
  for child in children:
    result.children.add(child)
    child.parent = result

# Convenience function to create a positioned node with children
proc newTestTree*(name: string, x, y, w, h: float32, children: varargs[TestNode]): TestNode =
  result = newTestNode(name, x, y, w, h)
  for child in children:
    result.children.add(child)
    child.parent = result

proc toVal*[T](v: T): float =
  when distinctBase(UiScalar) is SomeFloat:
    v
  else:
    trunc(v)

template printChildrens*(nodes: seq[TestNode], start = 0) =
  for i in start ..< nodes.len():
    echo "\tchild:box: ", nodes[i].name, " => ", nodes[i].box, " span: ", nodes[i].gridItem.span.repr

template checkUiFloats*(af, bf, ln, ls) =
  if abs(af.float-bf.float) >= 1.0e-3:
    checkpoint("Check failed: field: " & astToStr(af) & " value was: " & $af & " expected: " & $bf)
    fail()

template checks*(a: untyped, b: float) =
  if abs(a.float-b) >= 1.0e-3:
    checkpoint("Check failed: " & astToStr(a) & " value was: " & $a & " expected: " & $b)
    fail()

# template checks*(a: untyped, b: UiBox) =
#   checkUiFloats(a.x, b.x, "", "")
#   checkUiFloats(a.y, b.y, "", "")
#   checkUiFloats(a.w, b.w, "", "")
#   checkUiFloats(a.h, b.h, "", "")

# template checks*(a: untyped, b: UiSize) =
#   checkUiFloats(a.w, b.w, "", "")
#   checkUiFloats(a.h, b.h, "", "")

# template checks*(a: untyped, b: Slice[int16]) =
#   check a == b

import std/macros

macro checks*(args: untyped{nkInfix}) =
  let a = args[1]
  let b = args[2]
  let ln = args.lineinfo()
  let ls = args.repr()
  result = quote do:

    when `a` is SomeFloat:
      if abs(`a`-`b`) >= 1.0e-3:
        checkpoint(`ln` & ": Check failed: " & `ls` & " value was: " & $`a` & " expected: " & $`b`)
        fail()
    when `a` is UiBox:
      checkUiFloats(`a`.x,`b`.x, `ln`, `ls`)
      checkUiFloats(`a`.y,`b`.y, `ln`, `ls`)
      checkUiFloats(`a`.w,`b`.w, `ln`, `ls`)
      checkUiFloats(`a`.h,`b`.h, `ln`, `ls`)
    when `a` is UiSize:
      checkUiFloats(`a`.w,`b`.w, `ln`, `ls`)
      checkUiFloats(`a`.h,`b`.h, `ln`, `ls`)
  result.copyLineInfo(args)
