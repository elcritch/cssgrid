import unittest
import cssgrid/gridtypes
import cssgrid/parser
import cssgrid/constraints
import cssgrid/layout
import cssgrid/prettyprints
import cssgrid/variables
import commontestutils

suite "CSS variables":
  test "css variables":
    # Create a CSS variables container
    let vars = newCssVariables()
    
    # Register some variables
    let var1 = vars.registerVariable("width", 100'ux)
    let var2 = vars.registerVariable("height", 50'pp)
    let var3 = vars.registerVariable("gap", 1'fr)
    
    # Check registration worked
    check var1.int == 1
    check var2.int == 2
    check var3.int == 3
    
    # Create constraints using variables
    let widthVar = csVar(vars, "width", 100'ux)
    let heightVar = csVar(vars, "height", 50'pp)
    let gapVar = csVar(vars, "gap", 1'fr)
    
    # Verify variable constraints
    check widthVar.kind == UiValue
    check widthVar.value.kind == UiVariable
    check widthVar.value.varIdx == var1
    
    # Resolve variables
    var resolvedWidth: ConstraintSize
    check vars.resolveVariable(widthVar, resolvedWidth)
    var resolvedHeight: ConstraintSize
    check vars.resolveVariable(heightVar, resolvedHeight)
    var resolvedGap: ConstraintSize
    check vars.resolveVariable(gapVar, resolvedGap)
    
    # Check resolution
    check resolvedWidth.kind == UiFixed
    check resolvedWidth.coord == 100.UiScalar
    
    check resolvedHeight.kind == UiPerc
    check resolvedHeight.perc == 50.UiScalar
    
    check resolvedGap.kind == UiFrac
    check resolvedGap.frac == 1.UiScalar
    
    # Test variable lookup by name
    var widthSize: ConstraintSize
    let widthOpt = vars.lookupVariable("width", widthSize)
    check widthOpt
    check widthSize.kind == UiFixed
    check widthSize.coord == 100.UiScalar
    
    # Test variable name lookup
    let widthVar2 = vars.csVar("width")
    check widthVar2.kind == UiValue
    check widthVar2.value.kind == UiVariable
    check widthVar2.value.varIdx == var1
    
    # Test using variables in complex constraints
    let minSize = csMin(widthVar, heightVar)
    var resolvedMinSize: ConstraintSize
    check vars.resolveVariable(minSize, resolvedMinSize)
    
    # The minimum of 100px and 50% should be equivalent to min(fixed(100), perc(50))
    check resolvedMinSize.kind == UiFixed
    check resolvedMinSize.coord == 100.UiScalar
    check resolvedMinSize.kind == UiPerc
    check resolvedMinSize.perc == 50.UiScalar

  test "CSS variables with computeLayout as parameter":
    # Create a node with a grid template
    var parent = newTestNode("parent")
    parent.cxSize = [300'ux, 200'ux]
    
    # Create CSS variables container
    let cssVars = newCssVariables()
    let widthVar = cssVars.registerVariable("width", 100'ux)

    # Create some children nodes
    var child1 = newTestNode("child1", parent)
    child1.cxSize = [widthVar, 75'ux]
    
    var child2 = newTestNode("child2", parent)
    child2.cxSize = [50'ux, 0'ux]
    
    # Compute layout using the cssVars parameter
    computeLayout(parent, cssVars)
    # printLayout(parent, cmTerminal)

    # Check that child1's width is using the CSS variable value
    check(child1.box.w == 100.UiScalar)
    check(child2.box.w == 50.UiScalar)
    
    # Update the CSS variable
    discard cssVars.registerVariable("width", ConstraintSize(kind: UiFixed, coord: 150.UiScalar))
    
    # Recompute layout
    computeLayout(parent, cssVars)
    
    check(child1.box.w == 150.UiScalar)
    check(child2.box.w == 50.UiScalar)

  test "CSS variables with nested variable references":
    # Create a node with a grid template
    var parent = newTestNode("parent")
    parent.cxSize = [300'ux, 200'ux]
    
    # Create some children nodes
    var child = newTestNode("child", parent)
    child.cxSize = [100'ux, 100'ux]
    
    # Create CSS variables container with nested references
    let cssVars = newCssVariables()
    let baseVar = cssVars.registerVariable("base", 50'ux)
    let widthVar = cssVars.registerVariable("width", baseVar)
    
    # Set child's width to use the variable that references another variable
    child.cxSize[dcol] = widthVar
    
    # Compute layout
    computeLayout(parent, cssVars)
    printLayout(parent, cmTerminal, cssVars)
    
    # Check that child's width is correctly resolved through the chain of variables
    check(child.box.w == 50.UiScalar)
    
    # Update the base variable
    discard cssVars.registerVariable("base", 120'ux)
    
    # Recompute layout
    computeLayout(parent, cssVars)
    
    # Check that child's width is updated through the chain
    check(child.box.w == 120.UiScalar)