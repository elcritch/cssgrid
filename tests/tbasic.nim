
import unittest
import cssgrid/numberTypes

suite "grids":

  test "UiSize":
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
    echo "x ~= y: ", repr(x ~= y)
    echo "min(x, y): ", repr(min(x, y))

    z = vec2(1.0, 1.0).UiSize
    z += y
    z += 3.1'f32
    echo "z: ", repr(z)
    z = vec2(1.0, 1.0).UiSize
    echo "z: ", repr(-z)
    echo "z: ", repr(sin(z))
  
  test "box ":
    let x = uiBox(10.0, 10.0, 2.0, 2.0)
    let y = uiBox(10.0, 10.0, 5.0, 5.0)
    let c = 10.0.UiScalar
    var z = uiBox(10.0, 10.0, 5.0, 5.0)
    let v = uiSize(10.0, 10.0)

    echo "x.w: ", repr(x.w)
    echo "x + y: ", repr(x + y)
    echo "x / y: ", repr(x / c)
    echo "x * y: ", repr(x * c)
    echo "x == y: ", repr(x == y)

    z = uiBox(10.0, 10.0, 5.0, 5.0)
    z.xy= v
    # z += 3.1'f32
    echo "z: ", repr(z)
    z = uiBox(10.0, 10.0, 5.0, 5.0)

  test "example static dispatch":
    type Url[T: static string] = distinct void

    template url(s: static string): auto = Url[s]

    proc doThing(_: typedesc[url"hello"]) = echo "hello"
    proc doThing(_: typedesc[url"world"]) = echo "world"

    doThing url"hello"
    doThing url"world"
