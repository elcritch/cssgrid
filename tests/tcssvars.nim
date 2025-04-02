import unittest
import cssgrid/gridtypes
import cssgrid/parser
import cssgrid/constraints
import cssgrid/layout

import commontestutils


suite "CSS variables":
  test "CSS variables with computeLayout as parameter":
    # Create a node with a grid template
    var parent = newTestNode("parent", 0, 0, 300, 200)
    parent.gridTemplate = newGridTemplate()
    
    # Create some children nodes
    var child1 = newTestNode("child1", 0, 0, 100, 100, parent)
    child1.gridItem = GridItem()
    child1.gridItem.column = 1 // 2
    child1.gridItem.row = 1 // 2
    
    var child2 = newTestNode("child2", 0, 0, 100, 100, parent)
    child2.gridItem = GridItem()
    child2.gridItem.column = 2 // 3
    child2.gridItem.row = 1 // 2
    
    # Set up grid template columns with auto tracks
    parseGridTemplateColumns parent.gridTemplate:
      [] auto
      [] auto
      [] auto

    # Add children to parent
    
    # Create CSS variables container
    let cssVars = newCssVariables()
    
    # Register width variable
    let widthIdx = cssVars.registerVariable("width", ConstraintSize(kind: UiFixed, coord: 100.UiScalar))
    
    # Set child1's width to use the CSS variable
    child1.cxSize[dcol] = csVar(widthIdx)
    
    # Set child2's width directly
    child2.cxSize[dcol] = csFixed(50)
    
    # Compute layout using the cssVars parameter
    computeLayout(parent, cssVars)
    
    # Check that child1's width is using the CSS variable value
    check(child1.box.w == 100.UiScalar)
    
    # Check that child2's width is set directly
    check(child2.box.w == 50.UiScalar)
    
    # Update the CSS variable
    discard cssVars.registerVariable("width", ConstraintSize(kind: UiFixed, coord: 150.UiScalar))
    
    # Recompute layout
    computeLayout(parent, cssVars)
    
    # Check that child1's width is updated
    check(child1.box.w == 150.UiScalar)
    
    # Check that child2's width remains the same
    check(child2.box.w == 50.UiScalar)

  test "CSS variables with nested variable references":
    # Create a node with a grid template
    var parent = newTestNode("parent", 0, 0, 300, 200)
    parent.gridTemplate = newGridTemplate()
    
    # Create some children nodes
    var child = newTestNode("child", 0, 0, 100, 100, parent)
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
    
    # Register base size variable
    let baseIdx = cssVars.registerVariable("base", ConstraintSize(kind: UiFixed, coord: 50.UiScalar))
    
    # Register width variable that references base
    let widthVarIdx = cssVars.registerVariable("width", ConstraintSize(kind: UiVariable, varIdx: baseIdx))
    
    # Set child's width to use the variable that references another variable
    child.cxSize[dcol] = csVar(widthVarIdx)
    
    # Compute layout
    computeLayout(parent, cssVars)
    
    # Check that child's width is correctly resolved through the chain of variables
    check(child.box.w == 50.UiScalar)
    
    # Update the base variable
    discard cssVars.registerVariable("base", ConstraintSize(kind: UiFixed, coord: 120.UiScalar))
    
    # Recompute layout
    computeLayout(parent, cssVars)
    
    # Check that child's width is updated through the chain
    check(child.box.w == 120.UiScalar) 