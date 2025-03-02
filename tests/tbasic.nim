import unittest

import cssgrid/numberTypes
import vmath

suite "grids":

  test "UiSize":
    type FF = float64
    let f1: FF = 1.1
    let f2: FF = 10.1
    echo "test: ", f1 <= f2

    let x = uiSize(12.1, 13.4)
    let y = uiSize(10.0, 10.0)
    var z = uiSize(0.0, 0.0)
    let c = 1.0.UiScalar

    echo "x + y: ", repr(x + y)
    echo "x - y: ", repr(x - y)
    echo "x / y: ", repr(x / y)
    echo "x / c: ", repr(x / c)
    echo "x * y: ", repr(x * y)
    echo "x == y: ", repr(x == y)
    when UiScalar is SomeFloat:
      echo "x ~= y: ", repr(x ~= y)
    # echo "min(x, y): ", repr(min(x, y))

    z = gvec2[UiScalar](1.0.UiScalar, 1.0.UiScalar).UiSize
    z += y
    z.w += 3.1.UiScalar
    z.w = 3.1.UiScalar
    check z.w == 3.1.UiScalar
    z.h = 13.1.UiScalar
    check z.h == 13.1.UiScalar
    echo "z: ", repr(z)
    z = gvec2[UiScalar](1.0.UiScalar, 1.0.UiScalar).UiSize
    echo "z: ", repr(-z)
    echo "x:hash: ", hash(x)
    echo "x:toPos: ", x.toPos()

    echo "clamp: ", x.clamp(0.UiScalar, 13.UiScalar)
    check x.clamp(0.UiScalar, 13.UiScalar).w == 12.1.UiScalar
    check x.clamp(0.UiScalar, 13.UiScalar).h == 13.UiScalar

  test "UiPos":
    type FF = float64
    let f1: FF = 1.1
    let f2: FF = 10.1
    echo "test: ", f1 <= f2

    let x = uiPos(12.1, 13.4)
    let y = uiPos(10.0, 10.0)
    var z = uiPos(0.0, 0.0)
    let c = 1.0.UiScalar

    echo "x + y: ", repr(x + y)
    echo "x - y: ", repr(x - y)
    echo "x / y: ", repr(x / y)
    echo "x / c: ", repr(x / c)
    echo "x * y: ", repr(x * y)
    echo "x == y: ", repr(x == y)
    when UiScalar is SomeFloat:
      echo "x ~= y: ", repr(x ~= y)
    # echo "min(x, y): ", repr(min(x, y))

    z = gvec2[UiScalar](1.0.UiScalar, 1.0.UiScalar).UiPos
    z += y
    z.x += 3.1.UiScalar
    z.x = 3.1.UiScalar
    check z.x == 3.1.UiScalar
    z.y = 13.1.UiScalar
    check z.y == 13.1.UiScalar
    echo "z: ", repr(z)
    z = gvec2[UiScalar](1.0.UiScalar, 1.0.UiScalar).UiPos
    echo "z: ", repr(-z)
    # echo "z: ", repr(sin(z))
    check x.clamp(0.UiScalar, 13.UiScalar).x == 12.1.UiScalar
    check x.clamp(0.UiScalar, 13.UiScalar).y == 13.UiScalar
  
  test "box ":
    let x = uiBox(1.0, 2.0, 3.0, 4.0)
    let y = uiBox(10.0, 20.0, 5.0, 6.0)
    let c = 10.0.UiScalar
    var z = uiBox(10.0, 10.0, 5.0, 5.0)
    let v = uiSize(10.0, 10.0)

    check x.x == 1.0.UiScalar
    check x.y == 2.0.UiScalar
    check x.w == 3.0.UiScalar
    check x.h == 4.0.UiScalar
    echo "x:x: ", x.x
    echo "x:y: ", x.y
    echo "x:w: ", x.w
    echo "x:h: ", x.h

    echo "x.w: ", repr(x.w)

    echo "x + y: ", repr(x + y)
    echo "x / y: ", repr(x / c)
    echo "x * y: ", repr(x * c)
    echo "x == y: ", repr(x = y)

    z = uiBox(10.0, 10.0, 5.0, 5.0)
    z.xy= v
    z.x = 3.1.UiScalar
    z.x += 3.1.UiScalar

    # z += 3.1'f32
    echo "z: ", repr(z)
    echo "z.xy: ", repr(z.xy)
    echo "z.wh: ", repr(z.wh)

    z = x + y
    echo "z = x+y ", repr(z)
    check z.x == x.x + y.x
    check z.y == x.y + y.y
    check z.w == x.w
    check z.h == x.h

    check x.clamp(0.UiScalar, 3.UiScalar).x == 1.0.UiScalar
    check x.clamp(0.UiScalar, 3.UiScalar).y == 2.0.UiScalar
    check x.clamp(0.UiScalar, 3.UiScalar).w == 3.0.UiScalar
    check x.clamp(0.UiScalar, 3.UiScalar).h == 3.0.UiScalar

  test "example static dispatch":
    type Url[T: static string] = distinct void

    template url(s: static string): auto = Url[s]

    proc doThing(_: typedesc[url"hello"]) = echo "hello"
    proc doThing(_: typedesc[url"world"]) = echo "world"

    doThing url"hello"
    doThing url"world"
