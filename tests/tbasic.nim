
import unittest
import cssgrid/basic

suite "grids":

  test "position":
    let x = initPosition(12.1, 13.4)
    let y = initPosition(10.0, 10.0)
    var z = initPosition(0.0, 0.0)
    let c = 1.0'ui

    echo "x + y: ", repr(x + y)
    echo "x - y: ", repr(x - y)
    echo "x / y: ", repr(x / y)
    echo "x / c: ", repr(x / c)
    echo "x * y: ", repr(x * y)
    echo "x == y: ", repr(x == y)
    echo "x ~= y: ", repr(x ~= y)
    echo "min(x, y): ", repr(min(x, y))

    z = vec2(1.0, 1.0).Position
    z += y
    z += 3.1'f32
    echo "z: ", repr(z)
    z = vec2(1.0, 1.0).Position
    echo "z: ", repr(-z)
    echo "z: ", repr(sin(z))
  
  test "box ":
    let x = initBox(10.0, 10.0, 2.0, 2.0).Box
    let y = initBox(10.0, 10.0, 5.0, 5.0).Box
    let c = 10.0'ui
    var z = initBox(10.0, 10.0, 5.0, 5.0).Box
    let v = initPosition(10.0, 10.0)

    echo "x.w: ", repr(x.w)
    echo "x + y: ", repr(x + y)
    echo "x / y: ", repr(x / c)
    echo "x * y: ", repr(x * c)
    echo "x == y: ", repr(x == y)

    z = rect(10.0, 10.0, 5.0, 5.0).Box
    z.xy= v
    # z += 3.1'f32
    echo "z: ", repr(z)
    z = rect(10.0, 10.0, 5.0, 5.0).Box
