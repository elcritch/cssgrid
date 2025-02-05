
import strformat
import terminal

import numberTypes, constraints, gridtypes

import strformat
import terminal

type ColorMode* = enum
  cmNone
  cmPlain
  cmTerminal

var prettyPrintWriteMode* = cmNone

template withStyle(fg: ForegroundColor, style: set[Style] = {}, text: string) =
  if prettyPrintWriteMode == cmTerminal:
    stdout.styledWrite(fg, style, text)
  elif prettyPrintWriteMode == cmTerminal:
    stdout.write(text)
  else:
    discard

template debugPrint*(args: varargs[string, `$`]) =
  for arg in args:
    withStyle(fgGreen, text = " " & arg)
  withStyle(fgGreen, text = "\n")

proc prettyConstraintSize*(cs: ConstraintSize, indent = "") =
  case cs.kind
  of UiAuto:
    if cs.amin.float32 == float32.high():
      withStyle(fgCyan, text = "cs:auto")
    else:
      withStyle(fgCyan, text = &"cs:auto({cs.amin.float.float:.2f})")
  of UiFrac:
    withStyle(fgMagenta, text = &"cs:{cs.frac.float:.2f}fr")
  of UiPerc:
    withStyle(fgYellow, text = &"cs:{cs.perc.float:.2f}%")
  of UiFixed:
    withStyle(fgGreen, text = &"cs:{cs.coord.float:.2f}px")
  of UiContentMin:
    if cs.cmin.float32 == float32.high():
      withStyle(fgBlue, text = "cs:min-content")
    else:
      withStyle(fgBlue, text = &"cs:min-content({cs.cmin.float:.2f})")
  of UiContentMax:
    withStyle(fgBlue, text = &"cs:max-content({cs.cmax.float:.2f})")

proc prettyConstraint*(c: Constraint, indent = "") =
  case c.kind
  of UiNone:
    withStyle(fgWhite, text = "none")
  of UiValue:
    prettyConstraintSize(c.value, indent)
  of UiMin:
    withStyle(fgWhite, text = "min(")
    prettyConstraintSize(c.lmin, "")
    withStyle(fgWhite, text = ", ")
    prettyConstraintSize(c.rmin, "")
    withStyle(fgWhite, text = ")")
  of UiMax:
    withStyle(fgWhite, text = "max(")
    prettyConstraintSize(c.lmax, "")
    withStyle(fgWhite, text = ", ")
    prettyConstraintSize(c.rmax, "")
    withStyle(fgWhite, text = ")")
  of UiSum:
    withStyle(fgWhite, text = "sum(")
    prettyConstraintSize(c.lsum, "")
    withStyle(fgWhite, text = ", ")
    prettyConstraintSize(c.rsum, "")
    withStyle(fgWhite, text = ")")
  of UiMinMax:
    withStyle(fgWhite, text = "minmax(")
    prettyConstraintSize(c.lmm, "")
    withStyle(fgWhite, text = ", ")
    prettyConstraintSize(c.rmm, "")
    withStyle(fgWhite, text = ")")
  of UiEnd:
    withStyle(fgRed, text = "end")

proc prettyGridLine*(line: GridLine, indent = "") =
  if line.track.kind != UiEnd:
    withStyle(fgWhite, {styleBright}, text = indent & "track: ")
    prettyConstraint(line.track, "")
    # withStyle(fgWhite, text = "\n")
    
    if line.aliases.len > 0:
      withStyle(fgWhite, text = indent)
      let lines = line.aliases.toSeq.join(", ")
      withStyle(fgCyan, text = &" names: [{lines}]\n")
    
    withStyle(fgWhite, {styleBright}, text = " start: ")
    withStyle(fgYellow, text = &"{line.start.float:6.2f}")
    
    withStyle(fgWhite, {styleBright}, text = " width: ")
    withStyle(fgYellow, text = &"{line.width.float:6.2f}")
    
    if line.isAuto:
      withStyle(fgWhite, {styleBright}, text = " isAuto: ")
      withStyle(fgCyan, text = "true")
  else:
    withStyle(fgRed, text = &" [end track]\n")
  withStyle(fgWhite, text = "\n")

proc prettyGridTemplate*(grid: GridTemplate, indent = "") =
  if grid.isNil:
    withStyle(fgWhite, {styleBright}, text = indent & "GridTemplate: ")
    withStyle(fgRed, text = "nil\n")
    return

  withStyle(fgBlue, {styleBright}, text = indent & "GridTemplate:\n")
  
  # Add columns
  withStyle(fgGreen, {styleBright}, text = indent & "  Columns:\n")
  for i, col in grid.lines[dcol]:
    withStyle(fgYellow, text = indent & &"    [{i+1}]:")
    prettyGridLine(col, indent & "  ")
  
  # Add rows
  withStyle(fgGreen, {styleBright}, text = indent & "  Rows:\n")
  for i, row in grid.lines[drow]:
    withStyle(fgYellow, text = indent & &"    [{i+1}]:")
    prettyGridLine(row, indent & "  ")
  
  # Add properties
  withStyle(fgMagenta, {styleBright}, text = indent & "  Properties:\n")
  
  # Add each property with appropriate coloring
  for (name, value) in [
    ("gaps", &"[{grid.gaps[dcol].float:.2f}, {grid.gaps[drow].float:.2f}]"),
    ("justifyItems", $grid.justifyItems),
    ("alignItems", $grid.alignItems),
    ("autoFlow", $grid.autoFlow),
    ("overflowSizes", &"[{grid.overflowSizes[dcol].float:.2f}, {grid.overflowSizes[drow].float:.2f}]")
  ]:
    withStyle(fgWhite, {styleBright}, text = indent & &"    {name}: ")
    withStyle(
      if name in ["justifyItems", "alignItems", "autoFlow"]: fgCyan else: fgYellow,
      text = value & "\n"
    )

proc prettyLayout*(node: GridNode, indent = "") =
  # Node name
  withStyle(fgWhite, {styleBright}, text = indent & "Node: ")
  withStyle(fgGreen, text = node.name & "\n")
  
  # Box dimensions
  withStyle(fgWhite, {styleBright}, text = indent & "  box: ")
  withStyle(fgYellow, text = &"[x: {node.box.x.float:.2f}, y: {node.box.y.float:.2f}, w: {node.box.w.float:.2f}, h: {node.box.h.float:.2f}]\n")
  
  # Grid template
  if not node.gridTemplate.isNil:
    prettyGridTemplate(node.gridTemplate, indent & "  ")
  
  # Grid item
  if not node.gridItem.isNil:
    withStyle(fgBlue, {styleBright}, text = indent & "  gridItem:\n")
    
    withStyle(fgWhite, {styleBright}, text = indent & "    span: ")
    withStyle(fgYellow, text = &"[col: {node.gridItem.span[dcol]}, row: {node.gridItem.span[drow]}]\n")
    
    if node.gridItem.justify.isSome:
      withStyle(fgWhite, {styleBright}, text = indent & "    justify: ")
      withStyle(fgCyan, text = $node.gridItem.justify.get & "\n")
    
    if node.gridItem.align.isSome:
      withStyle(fgWhite, {styleBright}, text = indent & "    align: ")
      withStyle(fgCyan, text = $node.gridItem.align.get & "\n")
  
  # Constraints
  for i, constraint in node.cxSize:
    if constraint.kind != UiNone:
      let dir = if i == dcol: "width" else: "height"
      withStyle(fgWhite, {styleBright}, text = indent & &"  {dir}: ")
      prettyConstraint(constraint, "")
      withStyle(fgWhite, text = "\n")
  
  for i, constraint in node.cxOffset:
    if constraint.kind != UiNone:
      let dir = if i == dcol: "x" else: "y"
      withStyle(fgWhite, {styleBright}, text = indent & &"  {dir}: ")
      prettyConstraint(constraint, "")
      withStyle(fgWhite, text = "\n")
  
  # Process children
  for child in node.children:
    prettyLayout(child, indent & "  ")

proc printLayout*(node: GridNode) =
  prettyLayout(node, "")
  stdout.flushFile()

proc printGrid*(grid: GridTemplate) =
  prettyGridTemplate(grid, "")
  stdout.flushFile()