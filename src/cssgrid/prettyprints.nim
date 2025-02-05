
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

template withStyle(mode: ColorMode, fg: ForegroundColor, style: set[Style] = {}, text: string) =
  if mode == cmTerminal:
    stdout.styledWrite(fg, style, text)
  elif mode == cmTerminal:
    stdout.write(text)
  else:
    discard

template debugPrint*(args: varargs[string, `$`]) =
  for arg in args:
    prettyPrintWriteMode.withStyle(fgGreen, text = arg & " ")
  prettyPrintWriteMode.withStyle(fgGreen, text = "\n")

proc prettyConstraintSize*(cs: ConstraintSize, indent = "", mode: ColorMode = cmNone) =
  case cs.kind
  of UiAuto:
    if cs.amin.float32 == float32.high():
      mode.withStyle(fgCyan, text = "auto")
    else:
      mode.withStyle(fgCyan, text = &"auto(min:{cs.amin.float.float:.2f})")
  of UiFrac:
    mode.withStyle(fgMagenta, text = &"{cs.frac.float:.2f}'fr (min:{cs.fmin.float:.2f})")
  of UiPerc:
    mode.withStyle(fgYellow, text = &"{cs.perc.float:.2f}'pp")
  of UiFixed:
    mode.withStyle(fgGreen, text = &"{cs.coord.float:.2f}'ui")
  of UiContentMin:
    if cs.cmin.float32 == float32.high():
      mode.withStyle(fgBlue, text = "min-content")
    else:
      mode.withStyle(fgBlue, text = &"min-content({cs.cmin.float:.2f})")
  of UiContentMax:
    mode.withStyle(fgBlue, text = &"max-content({cs.cmax.float:.2f})")

proc prettyConstraint*(c: Constraint, indent = "", mode: ColorMode = cmNone) =
  case c.kind
  of UiNone:
    mode.withStyle(fgCyan, text = "none")
  of UiValue:
    prettyConstraintSize(c.value, indent, mode)
  of UiMin:
    mode.withStyle(fgWhite, text = "min(")
    prettyConstraintSize(c.lmin, "", mode)
    mode.withStyle(fgWhite, text = ", ")
    prettyConstraintSize(c.rmin, "", mode)
    mode.withStyle(fgWhite, text = ")")
  of UiMax:
    mode.withStyle(fgWhite, text = "max(")
    prettyConstraintSize(c.lmax, "", mode)
    mode.withStyle(fgWhite, text = ", ")
    prettyConstraintSize(c.rmax, "", mode)
    mode.withStyle(fgWhite, text = ")")
  of UiSum:
    mode.withStyle(fgWhite, text = "sum(")
    prettyConstraintSize(c.lsum, "", mode)
    mode.withStyle(fgWhite, text = ", ")
    prettyConstraintSize(c.rsum, "", mode)
    mode.withStyle(fgWhite, text = ")")
  of UiMinMax:
    mode.withStyle(fgWhite, text = "minmax(")
    prettyConstraintSize(c.lmm, "", mode)
    mode.withStyle(fgWhite, text = ", ")
    prettyConstraintSize(c.rmm, "", mode)
    mode.withStyle(fgWhite, text = ")")
  of UiEnd:
    mode.withStyle(fgRed, text = "end")

proc prettyGridLine*(line: GridLine, indent = "", mode: ColorMode = cmNone) =
  if line.track.kind != UiEnd:
    mode.withStyle(fgWhite, {styleBright}, text = indent & "track: ")
    prettyConstraint(line.track, "", mode)
    # withStyle(fgWhite, text = "\n")
    
    if line.aliases.len > 0:
      mode.withStyle(fgWhite, text = indent)
      let lines = line.aliases.toSeq.join(", ")
      mode.withStyle(fgCyan, text = &" names: [{lines}]\n")
    
    mode.withStyle(fgWhite, {styleBright}, text = " start: ")
    mode.withStyle(fgYellow, text = &"{line.start.float:6.2f}")
    
    mode.withStyle(fgWhite, {styleBright}, text = " width: ")
    mode.withStyle(fgYellow, text = &"{line.width.float:6.2f}")
    
    if line.isAuto:
      mode.withStyle(fgWhite, {styleBright}, text = " isAuto: ")
      mode.withStyle(fgCyan, text = "true")
  else:
    mode.withStyle(fgRed, text = &" [end track]\n")
  mode.withStyle(fgWhite, text = "\n")

proc prettyGridTemplate*(grid: GridTemplate, indent = "", mode: ColorMode = cmNone) =
  if grid.isNil:
    mode.withStyle(fgWhite, {styleBright}, text = indent & "GridTemplate: ")
    mode.withStyle(fgRed, text = "nil\n")
    return

  mode.withStyle(fgBlue, {styleBright}, text = indent & "GridTemplate:\n")
  
  # Add columns
  mode.withStyle(fgGreen, {styleBright}, text = indent & "  Columns:\n")
  for i, col in grid.lines[dcol]:
    mode.withStyle(fgYellow, text = indent & &"    [{i+1}]:")
    prettyGridLine(col, indent & "  ", mode)
  
  # Add rows
  mode.withStyle(fgGreen, {styleBright}, text = indent & "  Rows:\n")
  for i, row in grid.lines[drow]:
    mode.withStyle(fgYellow, text = indent & &"    [{i+1}]:")
    prettyGridLine(row, indent & "  ", mode)
  
  # Add properties
  mode.withStyle(fgMagenta, {styleBright}, text = indent & "  Properties:\n")
  
  # Add each property with appropriate coloring
  for (name, value) in [
    ("gaps", &"[{grid.gaps[dcol].float:.2f}, {grid.gaps[drow].float:.2f}]"),
    ("justifyItems", $grid.justifyItems),
    ("alignItems", $grid.alignItems),
    ("autoFlow", $grid.autoFlow),
    ("overflowSizes", &"[{grid.overflowSizes[dcol].float:.2f}, {grid.overflowSizes[drow].float:.2f}]")
  ]:
    mode.withStyle(fgWhite, {styleBright}, text = indent & &"    {name}: ")
    mode.withStyle(
      if name in ["justifyItems", "alignItems", "autoFlow"]: fgCyan else: fgYellow,
      text = value & "\n"
    )

proc prettyLayout*(node: GridNode, indent = "", mode: ColorMode = cmNone) =
  # Node name
  mode.withStyle(fgWhite, {styleBright}, text = indent & "Node: ")
  mode.withStyle(fgGreen, text = node.name & "\n")
  
  # Box dimensions
  mode.withStyle(fgWhite, {styleBright}, text = indent & "  box: ")
  mode.withStyle(fgYellow, text = &"[x: {node.box.x.float:.2f}, y: {node.box.y.float:.2f}, w: {node.box.w.float:.2f}, h: {node.box.h.float:.2f}]\n")
  
  # Constraints
  for i, constraint in node.cxSize:
    let dir = if i == dcol: "W" else: "H"
    mode.withStyle(fgWhite, {styleBright}, text = indent & &"  {dir}: ")
    prettyConstraint(constraint, "", mode)
  mode.withStyle(fgWhite, text = "\n")
  
  for i, constraint in node.cxOffset:
    let dir = if i == dcol: "X" else: "Y"
    mode.withStyle(fgWhite, {styleBright}, text = indent & &"  {dir}: ")
    prettyConstraint(constraint, "", mode)
  mode.withStyle(fgWhite, text = "\n")
  
  # Grid template
  if not node.gridTemplate.isNil:
    prettyGridTemplate(node.gridTemplate, indent & "  ", mode)
  
  # Grid item
  if not node.gridItem.isNil:
    mode.withStyle(fgBlue, {styleBright}, text = indent & "  gridItem:\n")
    
    mode.withStyle(fgWhite, {styleBright}, text = indent & "    span: ")
    mode.withStyle(fgYellow, text = &"[col: {node.gridItem.span[dcol]}, row: {node.gridItem.span[drow]}]\n")
    
    if node.gridItem.justify.isSome:
      mode.withStyle(fgWhite, {styleBright}, text = indent & "    justify: ")
      mode.withStyle(fgCyan, text = $node.gridItem.justify.get & "\n")
    
    if node.gridItem.align.isSome:
      mode.withStyle(fgWhite, {styleBright}, text = indent & "    align: ")
      mode.withStyle(fgCyan, text = $node.gridItem.align.get & "\n")
  
  # Process children
  for child in node.children:
    prettyLayout(child, indent & "  ", mode)

proc printLayout*(node: GridNode, mode: ColorMode = cmNone) =
  prettyLayout(node, "", mode)
  stdout.flushFile()

proc printGrid*(grid: GridTemplate, mode: ColorMode = cmNone) =
  prettyGridTemplate(grid, "", mode)
  stdout.flushFile()