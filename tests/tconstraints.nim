import std/unittest

import cssgrid/constraints

suite "constraints":


  test "basic constraint creation":
    check csAuto() == Constraint(kind: UiValue, value: ConstraintSize(kind: UiAuto, amin: 0.UiScalar))
    check csFixed(100) == Constraint(kind: UiValue, value: ConstraintSize(kind: UiFixed, coord: 100.UiScalar))
    check csFrac(1) == Constraint(kind: UiValue, value: ConstraintSize(kind: UiFrac, frac: 1.UiScalar))
    check csPerc(50) == Constraint(kind: UiValue, value: ConstraintSize(kind: UiPerc, perc: 50.UiScalar))
    check csContentMin() == Constraint(kind: UiValue, value: ConstraintSize(kind: UiContentMin, cmin: UiScalar.high()))
    check csContentMax() == Constraint(kind: UiValue, value: ConstraintSize(kind: UiContentMax, cmax: 0.UiScalar))

  test "constraint helpers":
    check 1'ux == csFixed(1)
    check 2.5'ux == csFixed(2.5)
    check 1'fr == csFrac(1)
    check 0.5'fr == csFrac(0.5)
    check 100'pp == csPerc(100)
    check 50.5'pp == csPerc(50.5)

  test "constraint constants":
    check cx"auto" == csAuto()
    check cx"min-content" == csContentMin()
    check cx"max-content" == csContentMax()

  test "constraint operations":
    let fixed1 = csFixed(100)
    let fixed2 = csFixed(200)
    let frac1 = csFrac(1)
    let frac2 = csFrac(2)

    # Test sum operation
    check (fixed1 + fixed2) == csSum(fixed1, fixed2)
    check (frac1 + frac2) == csSum(frac1, frac2)
    check (fixed1 + frac1) == csSum(fixed1, frac1)

    # Test min/max operations
    check csMin(fixed1, fixed2) == Constraint(
      kind: UiMin,
      lmin: fixed1.value,
      rmin: fixed2.value
    )
    check csMax(fixed1, fixed2) == Constraint(
      kind: UiMax,
      lmax: fixed1.value,
      rmax: fixed2.value
    )

  test "content sizing checks":
    check isContentSized(csAuto())
    check isContentSized(csFrac(1))
    check isContentSized(csContentMin())
    check isContentSized(csContentMax())
    check not isContentSized(csFixed(100))
    check not isContentSized(csPerc(50))

  test "auto sizing checks":
    check isAuto(csAuto())
    check isAuto(csFrac(1))
    check not isAuto(csFixed(100))
    check not isAuto(csPerc(50))

  test "complex constraint combinations":
    let minSize = 100'ux
    let maxSize = 200'ux
    let fracSize = 1'fr
    
    # Test min-max combination
    let minMaxConstraint = csMinMax(minSize, maxSize)
    check minMaxConstraint.kind == UiMinMax
    check minMaxConstraint.lmm == minSize.value
    check minMaxConstraint.rmm == maxSize.value

    # Test combining fractions with fixed sizes
    let complexSum = fracSize + 50'ux
    check complexSum.kind == UiSum
    check complexSum.lsum == fracSize.value
    check complexSum.rsum == csFixed(50).value

  test "string representation":
    check $ConstraintSize(kind: UiFrac, frac: 1.UiScalar) == "1.0'fr"
    check $ConstraintSize(kind: UiFixed, coord: 100.UiScalar) == "100.0'ux"
    check $ConstraintSize(kind: UiPerc, perc: 50.UiScalar) == "50.0'perc"

