import unittest
import cssgrid/gridtypes
import cssgrid/parser
import cssgrid/constraints
import cssgrid/layout
import cssgrid/prettyprints

import commontestutils

suite "CSS variables":
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
    parent.gridTemplate = newGridTemplate()
    
    # Create some children nodes
    var child = newTestNode("child", parent)
    child.cxSize = [100'ux, 100'ux]
    child.gridItem = GridItem()
    child.gridItem.column = 1 // 2
    child.gridItem.row = 1 // 2
    
    # Set up grid template columns with auto tracks
    parseGridTemplateColumns parent.gridTemplate:
      [] auto
      [] auto
    
    # Add child to parent
    
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