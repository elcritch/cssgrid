import std/unittest

import cssgrid/constraints
import cssgrid/variables
suite "constraints":


  test "basic constraint creation":
    check csAuto() == Constraint(kind: UiValue, value: ConstraintSize(kind: UiAuto))
    check csFixed(100) == Constraint(kind: UiValue, value: ConstraintSize(kind: UiFixed, coord: 100.UiScalar))
    check csFrac(1) == Constraint(kind: UiValue, value: ConstraintSize(kind: UiFrac, frac: 1.UiScalar))
    check csPerc(50) == Constraint(kind: UiValue, value: ConstraintSize(kind: UiPerc, perc: 50.UiScalar))
    check csContentMin() == Constraint(kind: UiValue, value: ConstraintSize(kind: UiContentMin))
    check csContentMax() == Constraint(kind: UiValue, value: ConstraintSize(kind: UiContentMax))
    check csContentFit() == Constraint(kind: UiValue, value: ConstraintSize(kind: UiContentFit))

  test "constraint helpers":
    check 1'ux == csFixed(1)
    check 2.5'ux == csFixed(2.5)
    check 1'fr == csFrac(1)
    check 0.5'fr == csFrac(0.5)
    check 100'pp == csPerc(100)
    check 50.5'pp == csPerc(50.5)
    check 50.5'vp == csViewPort(50.5)

  test "constraint constants":
    check cx"auto" == csAuto()
    check cx"min-content" == csContentMin()
    check cx"max-content" == csContentMax()
    check cx"fit-content" == csContentFit()

  test "constraint algebras":
    let minSize = min(100'ux, 100'pp)
    let maxSize = max(200'pp, cx"auto")
    let addSize = 200'pp + 10'ux
    let subSize = 200'pp - 10'ux

    check minSize == csMin(100'ux, 100'pp)
    check maxSize == csMax(200'pp, csAuto())
    check addSize == csAdd(200.0'pp, 10'ux)
    check subSize == csSub(200.0'pp, 10'ux)
    
    # expect(ValueError):
    #   let s1 = csSub(200.0'pp, csAuto())

  test "constraint operations":
    let fixed1 = csFixed(100)
    let fixed2 = csFixed(200)
    let frac1 = csFrac(1)
    let frac2 = csFrac(2)

    # Test sum operation
    check (fixed1 + fixed2) == csAdd(fixed1, fixed2)
    check (frac1 + frac2) == csAdd(frac1, frac2)
    check (fixed1 + frac1) == csAdd(fixed1, frac1)

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
    check isContentSized(csContentFit())
    check not isContentSized(csFixed(100))
    check not isContentSized(csPerc(50))
    
  test "basic content sizing checks":
    check isBasicContentSized(ConstraintSize(kind: UiContentMin))
    check isBasicContentSized(ConstraintSize(kind: UiContentMax))
    check isBasicContentSized(ConstraintSize(kind: UiContentFit))
    check not isBasicContentSized(ConstraintSize(kind: UiAuto))
    check not isBasicContentSized(ConstraintSize(kind: UiFrac))
    check not isBasicContentSized(ConstraintSize(kind: UiFixed))

  test "auto sizing checks":
    check isAuto(csAuto())
    check not isAuto(csFrac(1)) # in the css grid spec frac is handled on it's own
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
    check complexSum.kind == UiAdd
    check complexSum.ladd == fracSize.value
    check complexSum.radd == csFixed(50).value

  test "string representation":
    check $ConstraintSize(kind: UiFrac, frac: 1.UiScalar) == "1.0'fr"
    check $ConstraintSize(kind: UiFixed, coord: 100.UiScalar) == "100.0'ux"
    check $ConstraintSize(kind: UiPerc, perc: 50.UiScalar) == "50.0'perc"
    check $ConstraintSize(kind: UiContentMin) == "cx'content-min"
    check $ConstraintSize(kind: UiContentMax) == "cx'content-max"
    check $ConstraintSize(kind: UiContentFit) == "cx'fit-content"
    check $ConstraintSize(kind: UiAuto) == "cx'auto"
