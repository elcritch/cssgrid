## Table of Contents

03. [3 Grid Layout Concepts and Terminology](#grid-concepts)
    
    1. [3.1 Grid Lines](#grid-line-concept)
    2. [3.2 Grid Tracks and Cells](#grid-track-concept)
    3. [3.3 Grid Areas](#grid-area-concept)
    4. [3.4 Nested vs. Subgridded Items](#subgrid-items)
04. [4 Reordering and Accessibility](#order-accessibility)
05. [5 Grid Containers](#grid-model)
    
    1. [5.1 Establishing Grid Containers: the grid and inline-grid display values](#grid-containers)
    2. [5.2 Sizing Grid Containers](#intrinsic-sizes)
    3. [5.3 Scrollable Grid Overflow](#overflow)
    4. [5.4 Limiting Large Grids](#overlarge-grids)
06. [6 Grid Items](#grid-items)
    
    1. [6.1 Grid Item Display](#grid-item-display)
    2. [6.2 Grid Item Sizing](#grid-item-sizing)
    3. [6.3 Reordered Grid Items: the order property](#order-property)
    4. [6.4 Grid Item Margins and Paddings](#item-margins)
    5. [6.5 Z-axis Ordering: the z-index property](#z-order)
    6. [6.6 Automatic Minimum Size of Grid Items](#min-size-auto)
07. [7 Defining the Grid](#grid-definition)
    
    1. [7.1 The Explicit Grid](#explicit-grids)
    2. [7.2 Explicit Track Sizing: the grid-template-rows and grid-template-columns properties](#track-sizing)
       
       1. [7.2.1 Track Sizes](#track-sizes)
       2. [7.2.2 Naming Grid Lines: the \[&lt;custom-ident&gt;\*\] syntax](#named-lines)
       3. [7.2.3 Repeating Rows and Columns: the repeat() notation](#repeat-notation)
          
          1. [7.2.3.1 Syntax of repeat()](#repeat-syntax)
          2. [7.2.3.2 Repeat-to-fill: auto-fill and auto-fit repetitions](#auto-repeat)
          3. [7.2.3.3 Interpolation/Combination of repeat()](#repeat-interpolation)
       4. [7.2.4 Flexible Lengths: the fr unit](#fr-unit)
       5. [7.2.5 Computed Value of a Track Listing](#computed-tracks)
       6. [7.2.6 Resolved Value of a Track Listing](#resolved-track-list)
          
          1. [7.2.6.1 Resolved Value of a Standalone Track Listing](#resolved-track-list-standalone)
          2. [7.2.6.2 Resolved Value of a Subgridded Track Listing](#resolved-track-list-subgrid)
    3. [7.3 Named Areas: the grid-template-areas property](#grid-template-areas-property)
       
       1. [7.3.1 Serialization Of Template Strings](#serialize-template)
       2. [7.3.2 Implicitly-Assigned Line Names](#implicit-named-lines)
       3. [7.3.3 Implicitly-Named Areas](#implicit-named-areas)
    4. [7.4 Explicit Grid Shorthand: the grid-template property](#explicit-grid-shorthand)
    5. [7.5 The Implicit Grid](#implicit-grids)
    6. [7.6 Implicit Track Sizing: the grid-auto-rows and grid-auto-columns properties](#auto-tracks)
    7. [7.7 Automatic Placement: the grid-auto-flow property](#grid-auto-flow-property)
    8. [7.8 Grid Definition Shorthand: the grid property](#grid-shorthand)
08. [8 Placing Grid Items](#placement)
    
    1. [8.1 Common Patterns for Grid Placement](#common-uses)
       
       1. [8.1.1 Named Areas](#common-uses-named-areas)
       2. [8.1.2 Numeric Indexes and Spans](#common-uses-numeric)
       3. [8.1.3 Named Lines and Spans](#common-uses-named-lines)
       4. [8.1.4 Auto Placement](#common-uses-auto-placement)
    2. [8.2 Grid Item Placement vs. Source Order](#placement-a11y)
    3. [8.3 Line-based Placement: the grid-row-start, grid-column-start, grid-row-end, and grid-column-end properties](#line-placement)
       
       1. [8.3.1 Grid Placement Conflict Handling](#grid-placement-errors)
    4. [8.4 Placement Shorthands: the grid-column, grid-row, and grid-area properties](#placement-shorthands)
    5. [8.5 Grid Item Placement Algorithm](#auto-placement-algo)
09. [9 Subgrids](#subgrids)
10. [10 Absolute Positioning](#abspos)
    
    1. [10.1 With a Grid Container as Containing Block](#abspos-items)
    2. [10.2 With a Grid Container as Parent](#static-position)
11. [11 Alignment and Spacing](#alignment)
    
    1. [11.1 Gutters: the row-gap, column-gap, and gap properties](#gutters)
    2. [11.2 Aligning with auto margins](#auto-margins)
    3. [11.3 Inline-axis Alignment: the justify-self and justify-items properties](#row-align)
    4. [11.4 Block-axis Alignment: the align-self and align-items properties](#column-align)
    5. [11.5 Aligning the Grid: the justify-content and align-content properties](#grid-align)
    6. [11.6 Grid Container Baselines](#grid-baselines)
12. [12 Grid Layout Algorithm](#layout-algorithm)
    
    1. [12.1 Grid Sizing Algorithm](#algo-grid-sizing)
    2. [12.2 Track Sizing Terminology](#algo-terms)
    3. [12.3 Track Sizing Algorithm](#algo-track-sizing)
    4. [12.4 Initialize Track Sizes](#algo-init)
    5. [12.5 Resolve Intrinsic Track Sizes](#algo-content)
       
       1. [12.5.1 Distributing Extra Space Across Spanned Tracks](#extra-space)
    6. [12.6 Maximize Tracks](#algo-grow-tracks)
    7. [12.7 Expand Flexible Tracks](#algo-flex-tracks)
       
       1. [12.7.1 Find the Size of an fr](#algo-find-fr-size)
    8. [12.8 Stretch auto Tracks](#algo-stretch)
13. [13 Fragmenting Grid Layout](#pagination)
    
    1. [13.1 Sample Fragmentation Algorithm](#fragmentation-alg)
14. [14 Privacy Considerations](#privacy)
15. [15 Security Considerations](#security)
16. [16 Changes](#changes)
    
    1. [16.1 Changes since the 18 December 2020 CR](#changes-202012)
    2. [16.2 Changes since the August 2020 CR](#changes-202008)
    3. [Changes since the December 2019 CSS Grid Layout Level 2 Working Draft](#changes-20180904)
    4. [16.3 Additions Since Level 1](#changes-2)
17. [17 Acknowledgements](#acknowledgements)
18. [Conformance](#w3c-conformance)
    
    1. [Document conventions](#w3c-conventions)
    2. [Conformance classes](#w3c-conformance-classes)
    3. [Partial implementations](#w3c-partial)
       
       1. [Implementations of Unstable and Proprietary Features](#w3c-conform-future-proofing)
    4. [Non-experimental implementations](#w3c-testing)
    5. [CR exit criteria](#w3c-cr-exit-criteria)
19. [Index](#index)
    
    1. [Terms defined by this specification](#index-defined-here)
    2. [Terms defined by reference](#index-defined-elsewhere)
20. [References](#references)
    
    1. [Normative References](#normative)
    2. [Informative References](#informative)
21. [Property Index](#property-index)
22. [Issues Index](#issues-index)

[](#issue-436134ac)If you notice any inconsistencies between this Grid Layout Module and the [Flexible Box Layout Module](https://www.w3.org/TR/css-flexbox/), please report them to the CSSWG, as this is likely an error.


## 3. Grid Layout Concepts and Terminology[](#grid-concepts)

In grid layout, the content of a [grid container](#grid-container) is laid out by positioning and aligning it into a [grid](#grid). The grid is an intersecting set of horizontal and vertical [grid lines](#grid-line) that divides the grid container’s space into [grid areas](#grid-area), into which [grid items](#grid-item) (representing the grid container’s content) can be placed. There are two sets of grid lines: one set defining columns that run along the [block axis](https://www.w3.org/TR/css3-writing-modes/#block-axis), and an orthogonal set defining rows along the [inline axis](https://www.w3.org/TR/css3-writing-modes/#inline-axis). [\[CSS3-WRITING-MODES\]](#biblio-css3-writing-modes "CSS Writing Modes Level 3")

![Image: Grid Lines.](images/grid-lines.png)

Grid lines: Three in the block axis and four in the inline axis.

### 3.1. Grid Lines[](#grid-line-concept)

Grid lines are the horizontal and vertical dividing lines of the [grid](#grid). A [grid line](#grid-line) exists on either side of a column or row. They can be referred to by numerical index, or by an author-specified name. A [grid item](#grid-item) references the grid lines to determine its position within the grid using the [grid-placement properties](#placement).

[](#example-38bc117e)The following two examples both create three column [grid lines](#grid-line) and four row grid lines.

This first example demonstrates how an author would position a [grid item](#grid-item) using [grid line](#grid-line) numbers:

```css
#grid {
  display: grid;
  grid-template-columns: 150px 1fr;
  grid-template-rows: 50px 1fr 50px;
}

#item1 { grid-column: 2;
         grid-row-start: 1; grid-row-end: 4; }
```

This second example uses explicitly named [grid lines](#grid-line):

```css
/* equivalent layout to the prior example, but using named lines */
#grid {
  display: grid;
  grid-template-columns: 150px [item1-start] 1fr [item1-end];
  grid-template-rows: [item1-start] 50px 1fr 50px [item1-end];
}

#item1 {
  grid-column: item1-start / item1-end;
  grid-row: item1-start / item1-end;
}
```

### 3.2. Grid Tracks and Cells[](#grid-track-concept)

Grid track is a generic term for a [grid column](#grid-column) or [grid row](#grid-row)—in other words, it is the space between two adjacent [grid lines](#grid-line). Each [grid track](#grid-track) is assigned a sizing function, which controls how wide or tall the column or row may grow, and thus how far apart its bounding grid lines are. Adjacent grid tracks can be separated by [gutters](#gutters) but are otherwise packed tightly.

A grid cell is the intersection of a grid row and a grid column. It is the smallest unit of the grid that can be referenced when positioning [grid items](#grid-item).

[](#example-1c5d4651)In the following example there are two columns and three rows. The first column is fixed at 150px. The second column uses flexible sizing, which is a function of the unassigned space in the grid, and thus will vary as the width of the [grid container](#grid-container) changes. If the used width of the grid container is 200px, then the second column is 50px wide. If the used width of the grid container is 100px, then the second column is 0px and any content positioned in the column will overflow the grid container.

```
#grid {
  display: grid;
  grid-template-columns: 150px 1fr;  /* two columns */
  grid-template-rows: 50px 1fr 50px; /* three rows  */
}
```

### 3.3. Grid Areas[](#grid-area-concept)

A grid area is the logical space used to lay out one or more [grid items](#grid-item). A [grid area](#grid-area) consists of one or more adjacent [grid cells](#grid-cell). It is bound by four [grid lines](#grid-line), one on each side of the grid area, and participates in the sizing of the [grid tracks](#grid-track) it intersects. A grid area can be named explicitly using the [grid-template-areas](#propdef-grid-template-areas) property of the [grid container](#grid-container), or referenced implicitly by its bounding grid lines. A grid item is assigned to a grid area using the [grid-placement properties](#placement).

[](#example-909c0a0c)

```
/* using the template syntax */
#grid  {
  display: grid;
  grid-template-areas: ". a"
                       "b a"
                       ". a";
  grid-template-columns: 150px 1fr;
  grid-template-rows: 50px 1fr 50px;
  height: 100vh;
}

#item1 { grid-area: a }
#item2 { grid-area: b }
#item3 { grid-area: b }

/* Align items 2 and 3 at different points in the grid area "b".  */
/* By default, grid items are stretched to fit their grid area    */
/* and these items would layer one over the other. */
#item2 { align-self: start; }
#item3 { justify-self: end; align-self: end; }
```

A [grid item](#grid-item)’s [grid area](#grid-area) forms the containing block into which it is laid out. Grid items placed into the same grid area do not directly affect each other’s layout. Indirectly, however, a grid item occupying a [grid track](#grid-track) with an [intrinsic sizing function](#intrinsic-sizing-function) can affect the size of that track (and thus the positions of its bounding [grid lines](#grid-line)), which in turn can affect the position or size of another grid item.

### 3.4. Nested vs. Subgridded Items[](#subgrid-items)

A [grid item](#grid-item) can itself be a [grid container](#grid-container) by giving it [display: grid](https://www.w3.org/TR/css-display-4/#propdef-display). In the general case the layout of this nested grid’s contents will be independent of the layout of the parent grid it participates in.

However, in some cases it might be necessary for the contents of multiple [grid items](#grid-item) to align to each other. A [nested grid](#nested-grid) can defer the definition of its rows and/or columns to its parent [grid container](#grid-container), making it a subgrid. In this case, the grid items of the [subgrid](#subgrid) participate in sizing the [parent grid](#parent-grid), allowing the contents of both grids to align. See [§ 9 Subgrids](#subgrids).

A [subgrid](#subgrid) is established by the [subgrid](#valdef-grid-template-rows-subgrid) keyword of [grid-template-rows](#propdef-grid-template-rows) or [grid-template-columns](#propdef-grid-template-columns), and can be [subgridded](#subgridded-axis) in either axis or in both. A grid that has no subgridded axis is a standalone grid.

[](#example-921f3930)For example, suppose we have a form consisting of a list of inputs with labels:

```html
<ul>
  <li><label>Name:</label> <input name=fn>
  <li><label>Address:</label> <input name=address>
  <li><label>Phone:</label> <input name=phone>
</ul>
```

We want the labels and inputs to align, and we want to style each list item with a border. This can be accomplished with subgrid layout:

```
ul {
  display: grid;
  grid: auto-flow / auto 1fr;
}
li {
  grid-column: span 2;
  display: grid;
  grid-template-columns: subgrid;
  border: solid;
}
label {
  grid-column: 1;
}
input {
  grid-column: 2;
}
```

## 4. Reordering and Accessibility[](#order-accessibility)

Grid layout gives authors great powers of rearrangement over the document. However, these are not a substitute for correct ordering of the document source. The [order](https://www.w3.org/TR/css-flexbox-1/#propdef-order) property and [grid placement](#grid-placement) *do not* affect ordering in non-visual media (such as [speech](https://www.w3.org/TR/css3-speech/)). Likewise, rearranging grid items visually does not affect the default traversal order of sequential navigation modes (such as cycling through links, see e.g. [`tabindex`](https://html.spec.whatwg.org/multipage/interaction.html#attr-tabindex) [\[HTML\]](#biblio-html "HTML Standard")).

**Authors *must* use [order](https://www.w3.org/TR/css-flexbox-1/#propdef-order) and the [grid-placement properties](#grid-placement-property) only for visual, not logical, reordering of content. Style sheets that use these features to perform logical reordering are non-conforming.**

Note: This is so that non-visual media and non-CSS UAs, which typically present content linearly, can rely on a logical source order, while grid layout’s placement and ordering features are used to tailor the visual arrangement. (Since visual perception is two-dimensional and non-linear, the desired visual order is not always equivalent to the desired reading order.)

[](#example-33799738)Many web pages have a similar shape in the markup, with a header on top, a footer on bottom, and then a content area and one or two additional columns in the middle. Generally, it’s desirable that the content come first in the page’s source code, before the additional columns. However, this makes many common designs, such as simply having the additional columns on the left and the content area on the right, difficult to achieve. This has been addressed in many ways over the years, often going by the name "Holy Grail Layout" when there are two additional columns. Grid Layout makes this example trivial. For example, take the following sketch of a page’s code and desired layout:

```markup
<!DOCTYPE html>
<header>...</header>
<main>...</main>
<nav>...</nav>
<aside>...</aside>
<footer>...</footer>
```

![In this page the header is at the top and the footer at the bottom, but the main is in the center, flanked by the nav on the right and the aside on the left.](images/grid-order-page.svg)

This layout can be easily achieved with grid layout:

```css
body { display: grid;
       grid: "h h h"
             "a b c"
             "f f f";
       grid-template-columns: auto 1fr 20%; }
main    { grid-area: b; min-width: 12em;     }
nav     { grid-area: a; /* auto min-width */ }
aside   { grid-area: c; min-width: 12em;     }
```

As an added bonus, the columns will all be [equal-height](https://www.w3.org/TR/css-align-3/#valdef-align-self-stretch) by default, and the main content will be as wide as necessary to fill the screen. Additionally, this can then be combined with media queries to switch to an all-vertical layout on narrow screens:

```css
@media all and (max-width: 60em) {
  /* Too narrow to support three columns */
  body { display: block; }
}
```

In order to preserve the author’s intended ordering in all presentation modes, authoring tools—including WYSIWYG editors as well as Web-based authoring aids—​must reorder the underlying document source and not use [order](https://www.w3.org/TR/css-flexbox-1/#propdef-order) or [grid-placement properties](#grid-placement-property) to perform reordering unless the author has explicitly indicated that the underlying document order (which determines speech and navigation order) should be *out-of-sync* with the visual order.

[](#example-29a4cd08)For example, a tool might offer both drag-and-drop arrangement of grid items as well as handling of media queries for alternate layouts per screen size range.

Since most of the time, reordering should affect all screen ranges as well as navigation and speech order, the tool would match the resulting drag-and-drop visual arrangement by simultaneously reordering the DOM layer. In some cases, however, the author may want different visual arrangements per screen size. The tool could offer this functionality by using the [grid-placement properties](#grid-placement-property) together with media queries, but also tie the smallest screen size’s arrangement to the underlying DOM order (since this is most likely to be a logical linear presentation order) while using grid-placement properties to rearrange the visual presentation in other size ranges.

This tool would be conformant, whereas a tool that only ever used the [grid-placement properties](#grid-placement-property) to handle drag-and-drop grid rearrangement (however convenient it might be to implement it that way) would be non-conformant.

## 5. Grid Containers[](#grid-model)

### 5.1. Establishing Grid Containers: the [grid](#valdef-display-grid) and [inline-grid](#valdef-display-inline-grid) [display](https://www.w3.org/TR/css-display-4/#propdef-display) values[](#grid-containers)

Name: [display](https://www.w3.org/TR/css-display-4/#propdef-display) [New values:](https://www.w3.org/TR/css-values/#value-defs) grid [|](https://www.w3.org/TR/css-values-4/#comb-one) inline-grid

grid

This value causes an element to generate a [grid container](#grid-container) box that is [block-level](https://www.w3.org/TR/css-display-4/#block-level) when placed in [flow layout](https://www.w3.org/TR/css-display-4/#flow-layout).

inline-grid

This value causes an element to generate a [grid container](#grid-container) box that is [inline-level](https://www.w3.org/TR/css-display-4/#inline-level) when placed in [flow layout](https://www.w3.org/TR/css-display-4/#flow-layout).

A grid container that is not a [subgrid](#subgrid) establishes an [independent](https://www.w3.org/TR/css-display-4/#independent-formatting-context) grid formatting context for its contents. This is the same as establishing an independent [block formatting context](https://www.w3.org/TR/css-display-4/#block-formatting-context), except that grid layout is used instead of block layout: floats do not intrude into the grid container, and the grid container’s margins do not collapse with the margins of its contents. The contents of a [grid container](#grid-container) are laid out into a [grid](#grid), with [grid lines](#grid-line) forming the boundaries of each [grid items](#grid-item)’ containing block.

Unlike those of a regular nested grid, a [subgrid](#subgrid)’s contents participate in its parent [grid formatting context](#grid-formatting-context); thus a subgrid does not establish an [independent formatting context](https://www.w3.org/TR/css-display-4/#independent-formatting-context).

Grid containers are not block containers, and so some properties that were designed with the assumption of block layout don’t apply in the context of grid layout. In particular:

- [float](https://www.w3.org/TR/CSS2/visuren.html#propdef-float) and [clear](https://www.w3.org/TR/CSS2/visuren.html#propdef-clear) have no effect on a [grid item](#grid-item). However, the float property still affects the computed value of [display](https://www.w3.org/TR/css-display-4/#propdef-display) on children of a grid container, as this occurs *before* grid items are determined.
- [vertical-align](https://www.w3.org/TR/css-inline-3/#propdef-vertical-align) has no effect on a grid item.
- the [::first-line](https://www.w3.org/TR/css-pseudo-4/#selectordef-first-line) and [::first-letter](https://www.w3.org/TR/css-pseudo-4/#selectordef-first-letter) pseudo-elements do not apply to [grid containers](#grid-container), and grid containers do not contribute a first formatted line or first letter to their ancestors.

If an element’s specified [display](https://www.w3.org/TR/css-display-4/#propdef-display) is [inline-grid](#valdef-display-inline-grid) and the element is floated or absolutely positioned, the computed value of display is [grid](#valdef-display-grid). The table in [CSS 2.1 Chapter 9.7](https://www.w3.org/TR/CSS2/visuren.html#dis-pos-flo) is thus amended to contain an additional row, with inline-grid in the "Specified Value" column and grid in the "Computed Value" column.

### 5.2. Sizing Grid Containers[](#intrinsic-sizes)

Note see [\[CSS-SIZING-3\]](#biblio-css-sizing-3 "CSS Box Sizing Module Level 3") for a definition of the terms in this section.

A [grid container](#grid-container) is sized using the rules of the formatting context in which it participates:

- As a [block-level](https://www.w3.org/TR/css-display-4/#block-level) box in a [block formatting context](https://www.w3.org/TR/css-display-4/#block-formatting-context), it is sized like a [block box](https://www.w3.org/TR/css-display-4/#block-box) that establishes a formatting context, with an [auto](#grid-placement-auto) [inline size](https://www.w3.org/TR/css-writing-modes-4/#inline-size) calculated as for non-replaced block boxes.
- As an inline-level box in an [inline formatting context](https://www.w3.org/TR/css-display-4/#inline-formatting-context), it is sized as an atomic inline-level box (such as an inline-block).

In both inline and block formatting contexts, the [grid container](#grid-container)’s [auto](#grid-placement-auto) [block size](https://www.w3.org/TR/css-writing-modes-4/#block-size) is its max-content size.

The block layout spec should probably define this, but it isn’t written yet.

The [max-content size](https://www.w3.org/TR/css-sizing-3/#max-content) ([min-content size](https://www.w3.org/TR/css-sizing-3/#min-content)) of a [grid container](#grid-container) is the sum of the grid container’s track sizes (including gutters) in the appropriate axis, when the grid is sized under a [max-content constraint](https://www.w3.org/TR/css-sizing-3/#max-content-constraint) ([min-content constraint](https://www.w3.org/TR/css-sizing-3/#min-content-constraint)).

### 5.3. Scrollable Grid Overflow[](#overflow)

The [overflow](https://www.w3.org/TR/css-overflow-3/#propdef-overflow) property applies to [grid containers](#grid-container).

Just as it is included in intrinsic sizing (see [§ 5.2 Sizing Grid Containers](#intrinsic-sizes)), the [grid](#grid) is also included in a [grid container](#grid-container)’s [scrollable overflow region](https://www.w3.org/TR/css-overflow-3/#scrollable-overflow-region).

Note: Beware the interaction with padding when the [grid container](#grid-container) is a [scroll container](https://www.w3.org/TR/css-overflow-3/#scroll-container): additional padding is defined to be added to the [scrollable overflow rectangle](https://www.w3.org/TR/css-overflow-3/#scrollable-overflow-rectangle) as needed to enable [place-content: end](https://www.w3.org/TR/css-align-3/#propdef-place-content) alignment of scrollable content. See [CSS Overflow 3 § 2.2 Scrollable Overflow](https://www.w3.org/TR/css-overflow-3/#scrollable)

### 5.4. Limiting Large Grids[](#overlarge-grids)

Since memory is limited, UAs may clamp the possible size of the [implicit grid](#implicit-grid) to be within a UA-defined limit (which should accommodate lines in the range \[-10000, 10000]), dropping all lines outside that limit. If a grid item is placed outside this limit, its grid area must be [clamped](#clamp-a-grid-area) to within this limited grid.

To clamp a grid area:

- If the [grid area](#grid-area) would [span](#grid-span) outside the limited grid, its span is clamped to the last line of the limited [grid](#grid).
- If the [grid area](#grid-area) would be placed completely outside the limited grid, its span must be truncated to 1 and the area repositioned into the last [grid track](#grid-track) on that side of the grid.

[](#example-39312220)For example, if a UA only supported grids with at most 1000 tracks in each dimension, the following placement properties:

```css
.grid-item {
  grid-row: 500 / 1500;
  grid-column: 2000 / 3000;
}
```

Would end up being equivalent to:

```css
.grid-item {
  grid-row: 500 / 1001;
  grid-column: 1000 / 1001;
}
```

## 6. Grid Items[](#grid-items)

Loosely speaking, the grid items of a [grid container](#grid-container) are boxes representing its [in-flow](https://www.w3.org/TR/css-display-4/#in-flow) contents.

Each [in-flow](https://www.w3.org/TR/css-display-4/#in-flow) child of a [grid container](#grid-container) becomes a [grid item](#grid-item), and each child [text sequence](https://www.w3.org/TR/css-display-4/#css-text-sequence) is wrapped in an [anonymous](https://www.w3.org/TR/css-display-4/#anonymous) [block container](https://www.w3.org/TR/css-display-4/#block-container) grid item. However, if the text sequence contains only [white space](https://www.w3.org/TR/CSS2/text.html#white-space-prop) (i.e. characters that can be affected by the [white-space](https://www.w3.org/TR/css-text-4/#propdef-white-space) property) it is instead not rendered (just as if its [text nodes](https://www.w3.org/TR/css-display-4/#text-nodes) were display:none).

[](#example-4842bdfd)

Examples of grid items:

```markup
<div style="display: grid">

  <!-- grid item: block child -->
  <div id="item1">block</div>

  <!-- grid item: floated element; floating is ignored -->
  <div id="item2" style="float: left;">float</div>

  <!-- grid item: anonymous block box around inline content -->
  anonymous item 3

  <!-- grid item: inline child -->
  <span>
    item 4
    <!-- grid items do not split around blocks -->
    <q style="display: block" id=not-an-item>item 4</q>
    item 4
  </span>
</div>
```

grid items determined from above code block

[grid item containing `block`. grid item containing `float`. (Anonymous, unstyleable) grid item containing `anonymous item 3`. grid item containing three blocks in succession: Anonymous block containing `item 4`. `<q>` element block containing `item 4`. Anonymous block containing `item 4`.](examples/grid-item-determination.html)

Note: inter-element white space disappears: it does not become its own grid item, even though inter-element text *does* get wrapped in an anonymous grid item.

Note: The box of a anonymous item is unstyleable, since there is no element to assign style rules to. Its contents will however inherit styles (such as font settings) from the grid container.

### 6.1. Grid Item Display[](#grid-item-display)

Unless it is a [subgrid](#subgrid), a [grid item](#grid-item) [establishes an independent formatting context](https://www.w3.org/TR/css-display-4/#establish-an-independent-formatting-context) for its contents. However, grid items are grid-level boxes, not block-level boxes: they participate in their container’s [grid formatting context](#grid-formatting-context), not in a block formatting context.

If the [computed](https://www.w3.org/TR/css-cascade-5/#computed-value) [display](https://www.w3.org/TR/css-display-4/#propdef-display) value of an element’s nearest ancestor element (skipping display:contents ancestors) is [grid](#valdef-display-grid) or [inline-grid](#valdef-display-inline-grid), the element’s own display value is [blockified](https://www.w3.org/TR/css-display-4/#blockify). (See [CSS2.1§9.7](https://www.w3.org/TR/CSS2/visuren.html#dis-pos-flo) [\[CSS2\]](#biblio-css2 "Cascading Style Sheets Level 2 Revision 1 (CSS 2.1) Specification") and [CSS Display 3 § 2.7 Automatic Box Type Transformations](https://www.w3.org/TR/css-display-3/#transformations) for details on this type of display value conversion.)

Note: Blockification still occurs even when the [grid](#valdef-display-grid) or [inline-grid](#valdef-display-inline-grid) element does not end up generating a [grid container](#grid-container) box, e.g. when it is [replaced](https://www.w3.org/TR/css-display-4/#replaced-element) or in a [display: none](https://www.w3.org/TR/css-display-4/#propdef-display) subtree.

Note: Some values of [display](https://www.w3.org/TR/css-display-4/#propdef-display) normally trigger the creation of anonymous boxes around the original box. If such a box is a [grid item](#grid-item), it is blockified first, and so anonymous box creation will not happen. For example, two contiguous grid items with display: table-cell will become two separate display: block grid items, instead of being wrapped into a single anonymous table.

### 6.2. Grid Item Sizing[](#grid-item-sizing)

A [grid item](#grid-item) is sized within the containing block defined by its [grid area](#grid-area).

[Grid item](#grid-item) calculations for [automatic sizes](https://www.w3.org/TR/css-sizing-3/#automatic-size) in a given dimensions vary by their [self-alignment values](https://www.w3.org/TR/css-align-3/#self-alignment):

[normal](https://www.w3.org/TR/css-align-3/#valdef-align-self-normal)

If the grid item has no [preferred aspect ratio](https://www.w3.org/TR/css-sizing-4/#preferred-aspect-ratio), and no [natural size](https://www.w3.org/TR/css-images-3/#natural-size) in the relevant axis (if it is a [replaced element](https://www.w3.org/TR/css-display-4/#replaced-element)), the grid item is sized as for [align-self: stretch](https://www.w3.org/TR/css-align-3/#propdef-align-self).

Otherwise, the grid item is sized consistent with the size calculation rules for block-level elements for the corresponding axis. (See [CSS 2 §  10 Visual formatting model details](https://www.w3.org/TR/CSS2/visudet.html#q10.0).)

[stretch](https://www.w3.org/TR/css-align-3/#valdef-align-self-stretch)

Use the [inline size](https://www.w3.org/TR/css-writing-modes-4/#inline-size) calculation rules for non-replaced boxes (defined in [CSS 2 § 10.3.3 Block-level, non-replaced elements in normal flow](https://www.w3.org/TR/CSS2/visudet.html#blockwidth)), i.e. the [stretch-fit size](https://www.w3.org/TR/css-sizing-3/#stretch-fit-size).

Note: This can distort the aspect ratio of an item with a [preferred aspect ratio](https://www.w3.org/TR/css-sizing-4/#preferred-aspect-ratio), if its size is also constrained in the other axis.

all other values

Size the item as [fit-content](https://www.w3.org/TR/css-sizing-4/#valdef-width-fit-content).

The following informative table summarizes the automatic sizing of grid items:

Summary of automatic sizing behavior of grid items Alignment Non-replaced Element Size Replaced Element Size [normal](https://www.w3.org/TR/css-align-3/#valdef-align-self-normal) Fill grid area Use [natural size](https://www.w3.org/TR/css-images-3/#natural-size) [stretch](https://www.w3.org/TR/css-align-3/#valdef-align-self-stretch) Fill grid area Fill grid area [start](https://www.w3.org/TR/css-align-3/#valdef-self-position-start)/[center](https://www.w3.org/TR/css-align-3/#valdef-self-position-center)/etc. [fit-content](https://www.w3.org/TR/css-sizing-4/#valdef-width-fit-content) sizing (like floats) Use [natural size](https://www.w3.org/TR/css-images-3/#natural-size)

Note: The [auto](https://www.w3.org/TR/css-sizing-3/#valdef-width-auto) value of [min-width](https://www.w3.org/TR/CSS2/visudet.html#propdef-min-width) and [min-height](https://www.w3.org/TR/CSS2/visudet.html#propdef-min-height) affects track sizing in the relevant axis similar to how it affects the main size of a [flex item](https://www.w3.org/TR/css-flexbox-1/#flex-item). See [§ 6.6 Automatic Minimum Size of Grid Items](#min-size-auto).

### 6.3. Reordered Grid Items: the [order](https://www.w3.org/TR/css-flexbox-1/#propdef-order) property[](#order-property)

The [order](https://www.w3.org/TR/css-flexbox-1/#propdef-order) property also applies to [grid items](#grid-item). It affects their [auto-placement](#grid-auto-flow-property) and [painting order](#z-order).

**As with reordering flex items, the [order](https://www.w3.org/TR/css-flexbox-1/#propdef-order) property must only be used when the visual order needs to be *out-of-sync* with the speech and navigation order; otherwise the underlying document source should be reordered instead. See [CSS Flexbox 1 § 5.4.1 Reordering and Accessibility](https://www.w3.org/TR/css-flexbox-1/#order-accessibility) in [\[CSS-FLEXBOX-1\]](#biblio-css-flexbox-1 "CSS Flexible Box Layout Module Level 1").**

### 6.4. Grid Item Margins and Paddings[](#item-margins)

As adjacent grid items are independently contained within the containing block formed by their [grid areas](#grid-area), the margins of adjacent [grid items](#grid-item) do not [collapse](https://www.w3.org/TR/CSS2/box.html#collapsing-margins).

Percentage margins and paddings on [grid items](#grid-item), like those on [block boxes](https://www.w3.org/TR/css-display-4/#block-box), are resolved against the [inline size](https://www.w3.org/TR/css-writing-modes-4/#inline-size) of their [containing block](https://www.w3.org/TR/css-display-4/#containing-block), e.g. left/right/top/bottom percentages all resolve against their containing block’s *width* in horizontal [writing modes](https://www.w3.org/TR/css-writing-modes-4/#writing-mode).

Auto margins expand to absorb extra space in the corresponding dimension, and can therefore be used for alignment. See [§ 11.2 Aligning with auto margins](#auto-margins)

### 6.5. Z-axis Ordering: the [z-index](https://www.w3.org/TR/CSS2/visuren.html#propdef-z-index) property[](#z-order)

[Grid items](#grid-item) can overlap when they are positioned into intersecting [grid areas](#grid-area), or even when positioned in non-intersecting areas because of negative margins or positioning. The painting order of grid items is exactly the same as inline blocks [\[CSS2\]](#biblio-css2 "Cascading Style Sheets Level 2 Revision 1 (CSS 2.1) Specification"), except that [order-modified document order](https://www.w3.org/TR/css-flexbox-1/#order-modified-document-order) is used in place of raw document order, and [z-index](https://www.w3.org/TR/CSS2/visuren.html#propdef-z-index) values other than [auto](https://drafts.csswg.org/css2/#valdef-z-index-auto) create a stacking context even if [position](https://www.w3.org/TR/css-position-3/#propdef-position) is [static](https://www.w3.org/TR/css-position-3/#valdef-position-static) (behaving exactly as if position were [relative](https://www.w3.org/TR/css-position-3/#valdef-position-relative)). Thus the z-index property can easily be used to control the z-axis order of grid items.

Note: Descendants that are positioned outside a grid item still participate in any stacking context established by the grid item.

[](#example-ae2f6ea5)The following diagram shows several overlapping grid items, with a combination of implicit source order and explicit [z-index](https://www.w3.org/TR/CSS2/visuren.html#propdef-z-index) used to control their stacking order.

![](images/drawing-order.png)

Drawing order controlled by z-index and source order.

```
<style type="text/css">
#grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  grid-template-rows: 1fr 1fr
}
#A { grid-column: 1 / span 2; grid-row: 2; align-self: end; }
#B { grid-column: 1; grid-row: 1; z-index: 10; }
#C { grid-column: 2; grid-row: 1; align-self: start; margin-left: -20px; }
#D { grid-column: 2; grid-row: 2; justify-self: end; align-self: start; }
#E { grid-column: 1 / span 2; grid-row: 1 / span 2;
     z-index: 5; justify-self: center; align-self: center; }
</style>

<div id="grid">
  <div id="A">A</div>
  <div id="B">B</div>
  <div id="C">C</div>
  <div id="D">D</div>
  <div id="E">E</div>
</div>
```

### 6.6. Automatic Minimum Size of Grid Items[](#min-size-auto)

Note: Much of the sizing terminology used in this section (and throughout the rest of the specification) is defined in [CSS Intrinsic and Extrinsic Sizing](https://www.w3.org/TR/css-sizing-3/) [\[CSS-SIZING-3\]](#biblio-css-sizing-3 "CSS Box Sizing Module Level 3").

To provide a more reasonable default [minimum size](https://www.w3.org/TR/css-sizing-3/#min-width) for [grid items](#grid-item), the used value of its [automatic minimum size](https://www.w3.org/TR/css-sizing-3/#automatic-minimum-size) in a given axis is the [content-based minimum size](#content-based-minimum-size) if all of the following are true:

- its [computed](https://www.w3.org/TR/css-cascade-5/#computed-value) [overflow](https://www.w3.org/TR/css-overflow-3/#propdef-overflow) is not a [scrollable overflow value](https://drafts.csswg.org/css-overflow-3/#scrollable-overflow-value)
- it spans at least one [track](#grid-track) in that axis whose [min track sizing function](#min-track-sizing-function) is [auto](#valdef-grid-template-columns-auto)
- if it spans more than one track in that axis, none of those tracks are [flexible](#flexible-tracks)

Otherwise, the [automatic minimum size](https://www.w3.org/TR/css-sizing-3/#automatic-minimum-size) is zero, as usual.

Note: The [content-based minimum size](#content-based-minimum-size) is a type of [intrinsic size contribution](https://www.w3.org/TR/css-sizing-3/#intrinsic-size-contribution), and thus the provisions in [CSS Sizing 3 § 5.2 Intrinsic Contributions](https://www.w3.org/TR/css-sizing-3/#intrinsic-contribution) apply.

The content-based minimum size for a [grid item](#grid-item) in a given dimension is its [specified size suggestion](#specified-size-suggestion) if it exists, otherwise its [transferred size suggestion](#transferred-size-suggestion) if that exists and the element is [replaced](https://www.w3.org/TR/css-display-4/#replaced-element), else its [content size suggestion](#content-size-suggestion), see below. However, if in a given dimension the grid item spans only [grid tracks](#grid-track) that have a [fixed](#fixed-sizing-function) [max track sizing function](#max-track-sizing-function), then its specified size suggestion and content size suggestion in that dimension (and its input from this dimension to the transferred size suggestion in the opposite dimension) are further clamped to less than or equal to the [stretch fit](https://www.w3.org/TR/css-sizing-3/#stretch-fit) into the [grid area](#grid-area)’s maximum size in that dimension, as represented by the sum of those grid tracks’ max track sizing functions plus any intervening fixed [gutters](https://www.w3.org/TR/css-align-3/#gutter).

In all cases, the size suggestion is additionally clamped by the [maximum size](https://www.w3.org/TR/css-sizing-3/#max-width) in the affected axis, if it’s [definite](https://www.w3.org/TR/css-sizing-3/#definite). If the item is a [compressible replaced element](https://www.w3.org/TR/css-sizing-3/#min-content-zero), and has a definite [preferred size](https://www.w3.org/TR/css-sizing-3/#preferred-size) or maximum size in the relevant axis, the size suggestion is capped by those sizes; for this purpose, any indefinite percentages in these sizes are resolved against zero (and considered definite).

Note: The argument to [fit-content()](#funcdef-grid-template-columns-fit-content) does *not* clamp the [content-based minimum size](#content-based-minimum-size) in the same way as a [fixed](#fixed-sizing-function) [max track sizing function](#max-track-sizing-function).

The [content size suggestion](#content-size-suggestion), [specified size suggestion](#specified-size-suggestion), and [transferred size suggestion](#transferred-size-suggestion) used in this calculation account for the relevant min/max/preferred size properties so that the [content-based minimum size](#content-based-minimum-size) does not interfere with any author-provided constraints, and are defined below:

specified size suggestion

If the item’s [preferred size](https://www.w3.org/TR/css-sizing-3/#preferred-size) in the relevant axis is [definite](https://www.w3.org/TR/css-sizing-3/#definite), then the [specified size suggestion](#specified-size-suggestion) is that size. It is otherwise undefined.

transferred size suggestion

If the item has a [preferred aspect ratio](https://www.w3.org/TR/css-sizing-4/#preferred-aspect-ratio) and its [preferred size](https://www.w3.org/TR/css-sizing-3/#preferred-size) in the opposite axis is [definite](https://www.w3.org/TR/css-sizing-3/#definite), then the [transferred size suggestion](#transferred-size-suggestion) is that size (clamped by the opposite-axis [minimum](https://www.w3.org/TR/css-sizing-3/#min-width) and [maximum sizes](https://www.w3.org/TR/css-sizing-3/#max-width) if they are definite), converted through the aspect ratio. It is otherwise undefined.

If the item has a [definite](https://www.w3.org/TR/css-sizing-3/#definite) [preferred size](https://www.w3.org/TR/css-sizing-3/#preferred-size) or [maximum size](https://www.w3.org/TR/css-sizing-3/#max-width) in the relevant axis, the [transferred size suggestion](#transferred-size-suggestion) is capped by those sizes; for this purpose, any indefinite percentages in these sizes are resolved against zero (and considered definite).

content size suggestion

The [content size suggestion](#content-size-suggestion) is the [min-content size](https://www.w3.org/TR/css-sizing-3/#min-content) in the relevant axis, clamped, if it has a [preferred aspect ratio](https://www.w3.org/TR/css-sizing-4/#preferred-aspect-ratio), by any [definite](https://www.w3.org/TR/css-sizing-3/#definite) opposite-axis [minimum](https://www.w3.org/TR/css-sizing-3/#min-width) and [maximum sizes](https://www.w3.org/TR/css-sizing-3/#max-width) converted through the aspect ratio.

For the purpose of calculating an intrinsic size of the box (e.g. the box’s [min-content size](https://www.w3.org/TR/css-sizing-3/#min-content)), a [content-based minimum size](#content-based-minimum-size) causes the box’s size in that axis to become indefinite (even if e.g. its [width](https://www.w3.org/TR/css-sizing-3/#propdef-width) property specifies a [definite](https://www.w3.org/TR/css-sizing-3/#definite) size). Note this means that percentages calculated against this size will [behave as auto](https://www.w3.org/TR/css-sizing-3/#behave-as-auto).

For any purpose *other than* calculating intrinsic sizes, a [content-based minimum size](#content-based-minimum-size) (unlike an explicit [min-content](#valdef-grid-template-columns-min-content)/etc [minimum size](https://www.w3.org/TR/css-sizing-3/#min-width)) does not force the box’s size to become indefinite. However, if a percentage resolved against the box’s size *before* this minimum was applied, it must be re-resolved against the new size after it is applied.

[](#min-size-opt)Note that while a content-based minimum size is often appropriate, and helps prevent content from overlapping or spilling outside its container, in some cases it is not:

In particular, if grid layout is being used for a major content area of a document, it is better to set an explicit font-relative minimum width such as [min-width: 12em](https://www.w3.org/TR/CSS2/visudet.html#propdef-min-width). A content-based minimum width could result in a large table or large image stretching the size of the entire content area, potentially into an overflow zone, and thereby making lines of text needlessly long and hard to read.

Note also, when content-based sizing is used on an item with large amounts of content, the layout engine must traverse all of this content before finding its minimum size, whereas if the author sets an explicit minimum, this is not necessary. (For items with small amounts of content, however, this traversal is trivial and therefore not a performance concern.)

## 7. Defining the Grid[](#grid-definition)

### 7.1. The Explicit Grid[](#explicit-grids)

The three properties [grid-template-rows](#propdef-grid-template-rows), [grid-template-columns](#propdef-grid-template-columns), and [grid-template-areas](#propdef-grid-template-areas) together define the explicit grid of a [grid container](#grid-container) by specifying its explicit grid tracks. The final grid may end up larger due to [grid items](#grid-item) placed outside the [explicit grid](#explicit-grid); in this case implicit tracks will be created, these implicit tracks will be sized by the [grid-auto-rows](#propdef-grid-auto-rows) and [grid-auto-columns](#propdef-grid-auto-columns) properties.

The size of the [explicit grid](#explicit-grid) is determined by the larger of the number of rows/columns defined by [grid-template-areas](#propdef-grid-template-areas) and the number of rows/columns sized by [grid-template-rows](#propdef-grid-template-rows)/[grid-template-columns](#propdef-grid-template-columns). Any rows/columns defined by grid-template-areas but not sized by grid-template-rows/grid-template-columns take their size from the [grid-auto-rows](#propdef-grid-auto-rows)/[grid-auto-columns](#propdef-grid-auto-columns) properties. If these properties don’t define *any* explicit tracks the explicit grid still contains one [grid line](#grid-line) in each axis.

Numeric indexes in the [grid-placement properties](#grid-placement-property) count from the edges of the [explicit grid](#explicit-grid). Positive indexes count from the [start](https://www.w3.org/TR/css-writing-modes-4/#start) side (starting from 1 for the start-most explicit line), while negative indexes count from the [end](https://www.w3.org/TR/css-writing-modes-4/#end) side (starting from -1 for the end-most explicit line).

The [grid](#propdef-grid) and [grid-template](#propdef-grid-template) properties are [shorthands](https://www.w3.org/TR/css-cascade-5/#shorthand-property) that can be used to set all three explicit grid properties ([grid-template-rows](#propdef-grid-template-rows), [grid-template-columns](#propdef-grid-template-columns), and [grid-template-areas](#propdef-grid-template-areas)) at the same time. The grid shorthand also resets properties controlling the [implicit grid](#implicit-grid), whereas the grid-template property leaves them unchanged.

### 7.2. Explicit Track Sizing: the [grid-template-rows](#propdef-grid-template-rows) and [grid-template-columns](#propdef-grid-template-columns) properties[](#track-sizing)

Name: grid-template-columns, grid-template-rows [Value:](https://www.w3.org/TR/css-values/#value-defs) none [|](https://www.w3.org/TR/css-values-4/#comb-one) [&lt;track-list&gt;](#typedef-track-list) | [&lt;auto-track-list&gt;](#typedef-auto-track-list) | subgrid [&lt;line-name-list&gt;](#typedef-line-name-list)[?](https://www.w3.org/TR/css-values-4/#mult-opt) [Initial:](https://www.w3.org/TR/css-cascade/#initial-values) none [Applies to:](https://www.w3.org/TR/css-cascade/#applies-to) [grid containers](#grid-container) [Inherited:](https://www.w3.org/TR/css-cascade/#inherited-property) no [Percentages:](https://www.w3.org/TR/css-values/#percentages) refer to corresponding dimension of the content area [Computed value:](https://www.w3.org/TR/css-cascade/#computed) the keyword [none](#valdef-grid-template-rows-none) or a [computed track list](#computed-track-list) [Canonical order:](https://www.w3.org/TR/cssom/#serializing-css-values) per grammar [Animation type:](https://www.w3.org/TR/web-animations/#animation-type) if the list lengths match, by computed value type per item in the [computed track list](#computed-track-list) (see [§ 7.2.5 Computed Value of a Track Listing](#computed-tracks) and [§ 7.2.3.3 Interpolation/Combination of repeat()](#repeat-interpolation)); discrete otherwise

These properties specify, as a space-separated track list, the [line names](#line-name) and [track sizing functions](#grid-template-rows-track-sizing-function) of the [grid](#grid). The [grid-template-columns](#propdef-grid-template-columns) property specifies the [track list](#track-list) for the grid’s columns, while [grid-template-rows](#propdef-grid-template-rows) specifies the track list for the grid’s rows.

Values have the following meanings:

none

Indicates that no [explicit](#explicit-grid) grid tracks are created by this property (though explicit grid tracks could still be created by [grid-template-areas](#propdef-grid-template-areas)).

Note: In the absence of an [explicit grid](#explicit-grid) any rows/columns will be [implicitly generated](#implicit-grids), and their size will be determined by the [grid-auto-rows](#propdef-grid-auto-rows) and [grid-auto-columns](#propdef-grid-auto-columns) properties.

[&lt;track-list&gt;](#typedef-track-list) | [&lt;auto-track-list&gt;](#typedef-auto-track-list)

Specifies the [track list](#track-list) as a series of [track sizing functions](#grid-template-rows-track-sizing-function) and [line names](#line-name). Each track sizing function can be specified as a length, a percentage of the [grid container](#grid-container)’s size, a measurement of the contents occupying the column or row, or a fraction of the free space in the grid. It can also be specified as a range using the [minmax()](#funcdef-grid-template-columns-minmax) notation, which can combine any of the previously mentioned mechanisms to specify separate [min](#min-track-sizing-function) and [max track sizing functions](#max-track-sizing-function) for the column or row.

subgrid [&lt;line-name-list&gt;](#typedef-line-name-list)?

The subgrid value indicates that the grid will adopt the spanned portion of its [parent grid](#parent-grid) in that axis (the subgridded axis). Rather than being specified explicitly, the sizes of the grid rows/columns will be taken from the parent grid’s definition, and the [subgrid](#subgrid)’s items will participate in the [intrinsic size calculations](https://www.w3.org/TR/css-grid-1/#algo-content) ([CSS Grid Layout 1 § 11.5 Resolve Intrinsic Track Sizes](https://www.w3.org/TR/css-grid-1/#algo-content)) of any tracks shared with the parent grid. Essentially, subgrids provide the ability to pass grid parameters down through nested elements, and content-based sizing information back up to their parent grid.

The [&lt;line-name-list&gt;](#typedef-line-name-list) argument allows local naming of the grid lines shared with the [parent grid](#parent-grid): if a &lt;line-name-list&gt; is given, the specified [&lt;line-names&gt;](#typedef-line-names)s are assigned to the lines of the [subgrid](#subgrid)’s [explicit grid](#explicit-grid), one per line, starting with line 1. Excess &lt;line-names&gt; are ignored.

If there is no [parent grid](#parent-grid), or if the [grid container](#grid-container) is otherwise forced to establish an [independent formatting context](https://www.w3.org/TR/css-display-4/#independent-formatting-context) (for example, due to [layout containment](https://www.w3.org/TR/css-contain-2/#layout-containment) [\[CSS-CONTAIN-2\]](#biblio-css-contain-2 "CSS Containment Module Level 2") or [absolute positioning](https://www.w3.org/TR/css-position-3/#absolute-position) [\[CSS-POSITION-3\]](#biblio-css-position-3 "CSS Positioned Layout Module Level 3")), the [used value](https://www.w3.org/TR/css-cascade-5/#used-value) is the initial value, [none](#valdef-grid-template-rows-none), and the grid container is not a [subgrid](#subgrid).

An axis that is not [subgridded](#subgridded-axis) is a standalone axis.

The syntax of a [track list](#track-list) is:

```
<track-list>          = [ <line-names>? [ <track-size> | <track-repeat> ] ]+ <line-names>?
<auto-track-list>     = [ <line-names>? [ <fixed-size> | <fixed-repeat> ] ]* <line-names>? <auto-repeat>
                        [ <line-names>? [ <fixed-size> | <fixed-repeat> ] ]* <line-names>?
<explicit-track-list> = [ <line-names>? <track-size> ]+ <line-names>?

<line-name-list>      = [ <line-names> | <name-repeat> ]+
<track-size>          = <track-breadth> | minmax( <inflexible-breadth> , <track-breadth> ) | fit-content( <length-percentage [0,∞]> )
<fixed-size>          = <fixed-breadth> | minmax( <fixed-breadth> , <track-breadth> ) | minmax( <inflexible-breadth> , <fixed-breadth> )
<track-breadth>       = <length-percentage [0,∞]> | <flex [0,∞]> | min-content | max-content | auto
<inflexible-breadth>  = <length-percentage [0,∞]> | min-content | max-content | auto
<fixed-breadth>       = <length-percentage [0,∞]>
<line-names>          = '[' <custom-ident>* ']'
```

Where the component values are defined as follows…

#### 7.2.1. Track Sizes[](#track-sizes)

[&lt;length-percentage \[0,∞\]&gt;](https://www.w3.org/TR/css-values-4/#typedef-length-percentage)

A non-negative length or percentage, as defined by CSS3 Values. [\[CSS-VALUES-3\]](#biblio-css-values-3 "CSS Values and Units Module Level 3")

[&lt;percentage&gt;](https://www.w3.org/TR/css-values-4/#percentage-value) values are relative to the [inner](https://www.w3.org/TR/css-sizing-3/#inner-size) [inline size](https://www.w3.org/TR/css-writing-modes-4/#inline-size) of the [grid container](#grid-container) in column [grid tracks](#grid-track), and the inner [block size](https://www.w3.org/TR/css-writing-modes-4/#block-size) of the grid container in row grid tracks. If the size of the grid container depends on the size of its tracks, then the &lt;percentage&gt; must be treated as [auto](https://www.w3.org/TR/css-sizing-3/#valdef-width-auto), for the purpose of calculating the intrinsic sizes of the grid container and then resolve against that resulting grid container size for the purpose of laying out the [grid](#grid) and its items.

[&lt;flex \[0,∞\]&gt;](#typedef-flex)

A non-negative dimension with the unit [fr](#valdef-flex-fr) specifying the track’s flex factor. Each [&lt;flex&gt;](#typedef-flex)-sized track takes a share of the remaining space in proportion to its [flex factor](#grid-template-columns-flex-factor). For example, given a track listing of 1fr 2fr, the tracks will take up ⅓ and ⅔ of the [leftover space](#leftover-space), respectively. See [§ 7.2.4 Flexible Lengths: the fr unit](#fr-unit) for more details.

Note: If the sum of the [flex factors](#grid-template-columns-flex-factor) is less than 1, they’ll take up only a corresponding fraction of the [leftover space](#leftover-space), rather than expanding to fill the entire thing.

When appearing outside a [minmax()](#funcdef-grid-template-columns-minmax) notation, implies an automatic minimum (i.e. minmax(auto, [&lt;flex&gt;](#typedef-flex))).

minmax(`min`, `max`)

Defines a size range greater than or equal to `min` and less than or equal to `max`. If the `max` is less than the `min`, then the `max` will be floored by the `min` (essentially yielding minmax(`min`, `min`)). As a maximum, a [&lt;flex&gt;](#typedef-flex) value sets the track’s [flex factor](#grid-template-columns-flex-factor); it is invalid as a minimum.

Note: A future level of this spec may allow [&lt;flex&gt;](#typedef-flex) minimums, and will update the [track sizing algorithm](#track-sizing-algorithm) to account for this correctly

auto

As a *maximum*: represents the largest [max-content contribution](https://www.w3.org/TR/css-sizing-3/#max-content-contribution) of the [grid items](#grid-item) occupying the [grid track](#grid-track); however, unlike [max-content](#valdef-grid-template-columns-max-content), allows expansion of the track by the [align-content](https://www.w3.org/TR/css-align-3/#propdef-align-content) and [justify-content](https://www.w3.org/TR/css-align-3/#propdef-justify-content) properties.

As a *minimum*: represents the largest [minimum size](https://www.w3.org/TR/css-sizing-3/#min-width) (specified by [min-width](https://www.w3.org/TR/CSS2/visudet.html#propdef-min-width)/[min-height](https://www.w3.org/TR/CSS2/visudet.html#propdef-min-height)) of the [grid items](#grid-item) occupying the [grid track](#grid-track). (This initially is often, but not always, equal to a [min-content](#valdef-grid-template-columns-min-content) minimum—​see [§ 6.6 Automatic Minimum Size of Grid Items](#min-size-auto).)

When appearing outside a [minmax()](#funcdef-grid-template-columns-minmax) notation: equivalent to minmax(auto, auto), representing the range between the minimum and maximum described above. (This behaves similar to minmax(min-content, max-content) in the most basic cases, but with extra abilities.)

max-content

Represents the largest [max-content contribution](https://www.w3.org/TR/css-sizing-3/#max-content-contribution) of the [grid items](#grid-item) occupying the [grid track](#grid-track).

min-content

Represents the largest [min-content contribution](https://www.w3.org/TR/css-sizing-3/#min-content-contribution) of the [grid items](#grid-item) occupying the [grid track](#grid-track).

fit-content( [&lt;length-percentage&gt;](https://www.w3.org/TR/css-values-4/#typedef-length-percentage) )

Represents the formula `max(minimum, min(limit, max-content))`, where `minimum` represents an [auto](#valdef-grid-template-columns-auto) minimum (which is often, but not always, equal to a [min-content](#valdef-grid-template-columns-min-content) minimum), and `limit` is the [track sizing function](#grid-template-rows-track-sizing-function) passed as an argument to [fit-content()](#funcdef-grid-template-columns-fit-content). This is essentially calculated as the smaller of minmax(auto, max-content) and minmax(auto, `limit`).

[](#example-6651406f)Given the following [grid-template-columns](#propdef-grid-template-columns) declaration:

```
grid-template-columns: 100px 1fr max-content minmax(min-content, 1fr);
```

Five grid lines are created:

1. At the start edge of the [grid container](#grid-container).
2. 100px from the start edge of the [grid container](#grid-container).
3. A distance from the previous line equal to half the [free space](#free-space) (the width of the [grid container](#grid-container), minus the width of the non-flexible [grid tracks](#grid-track)).
4. A distance from the previous line equal to the maximum size of any [grid items](#grid-item) belonging to the column between these two lines.
5. A distance from the previous line at least as large as the largest minimum size of any [grid items](#grid-item) belonging to the column between these two lines, but no larger than the other half of the [free space](#free-space).

If the non-flexible sizes (100px, [max-content](#valdef-grid-template-columns-max-content), and [min-content](#valdef-grid-template-columns-min-content)) sum to larger than the [grid container](#grid-container)’s width, the final [grid line](#grid-line) will be a distance equal to their sum away from the start edge of the grid container (the 1fr sizes both resolve to 0). If the sum is less than the grid container’s width, the final grid line will be exactly at the end edge of the grid container. This is true in general whenever there’s at least one [&lt;flex&gt;](#typedef-flex) value among the [grid track](#grid-track) sizes.

[](#example-337b574e)Additional examples of valid [grid track](#grid-track) definitions:

```
/* examples of valid track definitions */
grid-template-rows: 1fr minmax(min-content, 1fr);
grid-template-rows: 10px repeat(2, 1fr auto minmax(30%, 1fr));
grid-template-rows: calc(4em - 5px);
```

Note: The size of the grid is not purely the sum of the track sizes, as [row-gap](https://www.w3.org/TR/css-align-3/#propdef-row-gap), [column-gap](https://www.w3.org/TR/css-align-3/#propdef-column-gap) and [justify-content](https://www.w3.org/TR/css-align-3/#propdef-justify-content), [align-content](https://www.w3.org/TR/css-align-3/#propdef-align-content) can add additional space between tracks.

#### 7.2.2. Naming Grid Lines: the \[[&lt;custom-ident&gt;](https://www.w3.org/TR/css-values-4/#identifier-value)\*] syntax[](#named-lines)

While [grid lines](#grid-line) can always be referred to by their numerical index, line names can make the [grid-placement properties](#grid-placement-property) easier to understand and maintain. [Line names](#line-name) can be explicitly assigned with the [grid-template-rows](#propdef-grid-template-rows) and [grid-template-columns](#propdef-grid-template-columns) properties, or [implicitly assigned](#implicitly-assigned-line-name) by [named grid areas](#named-grid-area) with the [grid-template-areas](#propdef-grid-template-areas) property.

[](#example-1cbfee50)For example, the following code gives meaningful names to all of the lines in the grid. Note that some of the lines have multiple names.

```
#grid {
  display: grid;
  grid-template-columns: [first nav-start] 150px [main-start] 1fr [last];
  grid-template-rows: [first header-start] 50px [main-start] 1fr [footer-start] 50px [last];
}
```

![Image: Named Grid Lines.](images/grid-named-lines.png)

Named Grid Lines.

A [line name](#line-name) cannot be span or auto, i.e. the [&lt;custom-ident&gt;](https://www.w3.org/TR/css-values-4/#identifier-value) in the [&lt;line-names&gt;](#typedef-line-names) production excludes the keywords span and auto.

#### 7.2.3. Repeating Rows and Columns: the [repeat()](#funcdef-track-repeat-repeat) notation[](#repeat-notation)

The repeat() notation represents a repeated fragment of the [track list](#track-list), allowing a large number of columns or rows that exhibit a recurring pattern to be written in a more compact form.

[](#example-e3dc5d22)This example shows two equivalent ways of writing the same grid definition. Both declarations produce four “main” columns, each 250px wide, surrounded by 10px “gutter” columns.

```
grid-template-columns: 10px [col-start] 250px [col-end]
                       10px [col-start] 250px [col-end]
                       10px [col-start] 250px [col-end]
                       10px [col-start] 250px [col-end] 10px;
/* same as above, except easier to write */
grid-template-columns: repeat(4, 10px [col-start] 250px [col-end]) 10px;
```

##### 7.2.3.1. Syntax of [repeat()](#funcdef-track-repeat-repeat)[](#repeat-syntax)

The generic form of the [repeat()](#funcdef-track-repeat-repeat) syntax is, approximately,

```
repeat( [ <integer [1,∞]> | auto-fill | auto-fit ] , <track-list> )
```

The first argument specifies the number of repetitions. The second argument is a [track list](#track-list), which is repeated that number of times. However, there are some restrictions:

- The [repeat()](#funcdef-track-repeat-repeat) notation can’t be nested.
- Automatic repetitions ([auto-fill](#valdef-repeat-auto-fill) or [auto-fit](#valdef-repeat-auto-fit)) cannot be combined with fully [intrinsic](#intrinsic-sizing-function) or [flexible](#flexible-sizing-function) sizes (see grammar).

Thus the precise syntax of the [repeat()](#funcdef-track-repeat-repeat) notation has several forms:

```
<track-repeat> = repeat( [ <integer [1,∞]> ] , [ <line-names>? <track-size> ]+ <line-names>? )
<auto-repeat>  = repeat( [ auto-fill | auto-fit ] , [ <line-names>? <fixed-size> ]+ <line-names>? )
<fixed-repeat> = repeat( [ <integer [1,∞]> ] , [ <line-names>? <fixed-size> ]+ <line-names>? )
<name-repeat> = repeat( [ <integer [1,∞]> | auto-fill ], <line-names>+)
```

- The [&lt;track-repeat&gt;](#typedef-track-repeat) variant can represent the repetition of any [&lt;track-size&gt;](#typedef-track-size), but is limited to a fixed number of repetitions.
- The [&lt;auto-repeat&gt;](#typedef-auto-repeat) variant can repeat automatically to fill a space, but requires [definite](https://www.w3.org/TR/css-sizing-3/#definite) track sizes so that the number of repetitions can be calculated. It can only appear once in the [track list](#track-list), but the same track list can also contain [&lt;fixed-repeat&gt;](#typedef-fixed-repeat)s.
- The [&lt;name-repeat&gt;](#typedef-name-repeat) variant is for adding [line names](#line-name) to [subgrids](#subgrid). It can only be used with the [subgrid](#valdef-grid-template-rows-subgrid) keyword and cannot specify track sizes, only line names.

If a [repeat()](#funcdef-track-repeat-repeat) function that is not a [&lt;name-repeat&gt;](#typedef-name-repeat) ends up placing two [&lt;line-names&gt;](#typedef-line-names) adjacent to each other, the name lists are merged. For example, repeat(2, \[a] 1fr \[b]) is equivalent to \[a] 1fr \[b a] 1fr \[b].

##### 7.2.3.2. Repeat-to-fill: [auto-fill](#valdef-repeat-auto-fill) and [auto-fit](#valdef-repeat-auto-fit) repetitions[](#auto-repeat)

On a [subgridded axis](#subgridded-axis), the [auto-fill](#valdef-repeat-auto-fill) keyword is only valid once per [&lt;line-name-list&gt;](#typedef-line-name-list), and repeats enough times for the name list to match the [subgrid](#subgrid)’s specified [grid span](#grid-span) (falling back to 0 if the span is already fulfilled).

Otherwise on a [standalone axis](#standalone-axis), when auto-fill is given as the repetition number, if the [grid container](#grid-container) has a [definite](https://www.w3.org/TR/css-sizing-3/#definite) [preferred size](https://www.w3.org/TR/css-sizing-3/#preferred-size) or [maximum size](https://www.w3.org/TR/css-sizing-3/#max-width) in the relevant axis, then the number of repetitions is the largest possible positive integer that does not cause the [grid](#grid) to overflow the [content box](https://www.w3.org/TR/css-box-4/#content-box) of its grid container taking [gap](https://www.w3.org/TR/css-align-3/#propdef-gap) into account; if any number of repetitions would overflow, then 1 repetition. Otherwise, if the grid container has a definite [minimum size](https://www.w3.org/TR/css-sizing-3/#min-width) in the relevant axis, the number of repetitions is the smallest possible positive integer that fulfills that minimum requirement. Otherwise, the specified [track list](#track-list) repeats only once.

For this purpose, each track is treated as its [max track sizing function](#max-track-sizing-function) if that is [definite](https://www.w3.org/TR/css-sizing-3/#definite) or else its [min track sizing function](#min-track-sizing-function) if that is definite. If both are definite, floor the max track sizing function by the min track sizing function. If neither are definite, the number of repetitions is one.

[](#example-5bb26bd3)For example, the following code will create as many 25-character columns as will fit into the window width. If there is any remaining space, it will be distributed among the 25-character columns.

```
body {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(25ch, 1fr));
}
```

The auto-fit keyword behaves the same as [auto-fill](#valdef-repeat-auto-fill), except that after [grid item placement](#auto-placement-algo) any empty repeated tracks are [collapsed](#collapsed-grid-track). An empty track is one with no [in-flow](https://www.w3.org/TR/css-display-4/#in-flow) grid items placed into or spanning across it. (This can result in *all* tracks being collapsed, if they’re all empty.)

A collapsed grid track is treated as having a fixed [track sizing function](#grid-template-rows-track-sizing-function) of 0px, and the [gutters](https://www.w3.org/TR/css-align-3/#gutter) on either side of it—​including any space allotted through [distributed alignment](https://www.w3.org/TR/css-align-3/#distributed-alignment)—​[collapse](#collapsed-gutter).

For the purpose of finding the number of auto-repeated tracks in a [standalone axis](#standalone-axis), the UA must floor the track size to a UA-specified value to avoid division by zero. It is suggested that this floor be 1px.

##### 7.2.3.3. Interpolation/Combination of [repeat()](#funcdef-track-repeat-repeat)[](#repeat-interpolation)

If two [repeat()](#funcdef-track-repeat-repeat) notations that have the same first argument (repetition count) and the same number of tracks in their second argument (the track listing), they are combined by combining each component of their [computed track lists](#computed-track-list) [by computed value](https://www.w3.org/TR/web-animations-1/#by-computed-value) (just like combining a top-level track list). They otherwise combine [discretely](https://www.w3.org/TR/web-animations-1/#discrete).

#### 7.2.4. Flexible Lengths: the [fr](#valdef-flex-fr) unit[](#fr-unit)

A flexible length or [&lt;flex&gt;](#typedef-flex) is a dimension with the fr unit, which represents a fraction of the [leftover space](#leftover-space) in the [grid container](#grid-container). Tracks sized with [fr](#valdef-flex-fr) units are called flexible tracks as they flex in response to leftover space similar to how [flex items](https://www.w3.org/TR/css-flexbox-1/#flex-item) with a zero base size fill space in a [flex container](https://www.w3.org/TR/css-flexbox-1/#flex-container).

The distribution of [leftover space](#leftover-space) occurs after all non-flexible [track sizing functions](#grid-template-rows-track-sizing-function) have reached their maximum. The total size of such rows or columns is subtracted from the available space, yielding the leftover space, which is then divided among the flex-sized rows and columns in proportion to their [flex factor](#grid-template-columns-flex-factor).

Each column or row’s share of the [leftover space](#leftover-space) can be computed as the column or row’s `<flex> * <leftover space> / <sum of all flex factors>`.

[&lt;flex&gt;](#typedef-flex) values between 0fr and 1fr have a somewhat special behavior: when the sum of the flex factors is less than 1, they will take up less than 100% of the leftover space.

A track’s [&lt;flex&gt;](#typedef-flex) value is effectively a request for some proportion of the leftover space, with 1fr meaning “100% of the leftover space”; then if the tracks in that axis are requesting more than 100% in total, the requests are rebalanced to keep the same ratio but use up exactly 100% of it. However, if the tracks request *less* than the full amount (such as three tracks that are each .25fr) then they’ll each get exactly what they request (25% of the leftover space to each, with the final 25% left unfilled). See [§ 12.7 Expand Flexible Tracks](#algo-flex-tracks) for the exact details of how leftover space is distributed.

This pattern is required for continuous behavior as [fr](#valdef-flex-fr) values approach zero (which means the tracks wants *none* of the leftover space). Without this, a 1fr track would take all of the leftover space; but so would a 0.1fr track, and a 0.01fr track, etc., until finally the value is small enough to underflow to zero and the track suddenly takes up none of the leftover space. With this behavior, the track instead gradually takes less of the leftover space as its flex factor shrinks below 1fr, smoothly transitioning to taking none of the leftover space at zero.

Unless this “partial fill” behavior is *specifically* what’s desired, authors should stick to values ≥ 1; for example, using 1fr and 2fr is usually better than using .33fr and .67fr, as they’re more likely to behave as intended if tracks are added or removed.

When the available space is infinite (which happens when the [grid container](#grid-container)’s width or height is [indefinite](https://www.w3.org/TR/css-sizing-3/#indefinite)), flex-sized [grid tracks](#grid-track) are sized to their contents while retaining their respective proportions. The used size of each flex-sized grid track is computed by determining the [max-content](#valdef-grid-template-columns-max-content) size of each flex-sized grid track and dividing that size by the respective [flex factor](#grid-template-columns-flex-factor) to determine a “hypothetical 1fr size”. The maximum of those is used as the resolved 1fr length (the flex fraction), which is then multiplied by each grid track’s flex factor to determine its final size.

Note: [&lt;flex&gt;](#typedef-flex) values are not [&lt;length&gt;](https://www.w3.org/TR/css-values-4/#length-value)s (nor are they compatible with &lt;length&gt;s, like some [&lt;percentage&gt;](https://www.w3.org/TR/css-values-4/#percentage-value) values), so they cannot be represented in or combined with other unit types in [calc()](https://www.w3.org/TR/css-values-4/#funcdef-calc) expressions.

#### 7.2.5. Computed Value of a Track Listing[](#computed-tracks)

The computed track list of a non-[subgrid](#valdef-grid-template-rows-subgrid) axis is a [list](https://infra.spec.whatwg.org/#list) alternating between [line name sets](#line-name-set) and [track sections](#track-section), with the first and last items being line name sets.

A line name set is a (potentially empty) [set](https://infra.spec.whatwg.org/#ordered-set) of identifiers representing line names.

A track section is either:

- a [minmax()](#funcdef-grid-template-columns-minmax) functional notation representing a single track’s size, with each [&lt;length-percentage&gt;](https://www.w3.org/TR/css-values-4/#typedef-length-percentage) computed (a computed track size)
- a [repeat()](#funcdef-track-repeat-repeat) functional notation representing a repeated track list section, with its [&lt;integer&gt;](https://www.w3.org/TR/css-values-4/#integer-value) computed and its [&lt;track-list&gt;](#typedef-track-list) represented as a [computed track list](#computed-track-list) (a computed repeat notation)

The [computed track list](#computed-track-list) of a [subgrid](#valdef-grid-template-rows-subgrid) axis is the subgrid keyword followed by a [list](https://infra.spec.whatwg.org/#list) of [line name sets](#line-name-set) and [computed repeat notations](#computed-repeat-notation) representing the line names specified for that axis.

#### 7.2.6. Resolved Value of a Track Listing[](#resolved-track-list)

The [grid-template-rows](#propdef-grid-template-rows) and [grid-template-columns](#propdef-grid-template-columns) properties are [resolved value special case properties](https://www.w3.org/TR/cssom-1/#resolved-value-special-case-property). [\[CSSOM\]](#biblio-cssom "CSS Object Model (CSSOM)")

##### 7.2.6.1. Resolved Value of a Standalone Track Listing[](#resolved-track-list-standalone)

When an element generates a [grid container](#grid-container) box, the [resolved value](https://www.w3.org/TR/cssom/#resolved-values) of its [grid-template-rows](#propdef-grid-template-rows) or [grid-template-columns](#propdef-grid-template-columns) property in a [standalone axis](#standalone-axis) is the [used value](https://www.w3.org/TR/css-cascade-5/#used-value), serialized with:

- Every track listed individually, whether implicitly or explicitly created, without using the [repeat()](#funcdef-track-repeat-repeat) notation.
- Every track size given as a length in pixels, regardless of sizing function.
- Adjacent line names collapsed into a single bracketed set.

[](#issue-cccd0e19)The first bullet point of the above list means that implicit tracks get serialized as part of [grid-template-rows](#propdef-grid-template-rows)/etc., despite the fact that an author *cannot* actually specify implicit track sizes in those properties! So grid-template-rows and [grid-template-columns](#propdef-grid-template-columns) values might not round-trip correctly:

```
const s = getComputedStyle(gridEl);
gridEl.style.gridTemplateRows = s.gridTemplateRows;
// Code like this should be a no-op,
// but if there are any implicit rows,
// this will convert them into explicit rows,
// possibly changing how grid items are positioned
// and altering the overall size of the grid!
```

This is an accidental property of an early implementation that leaked into later implementations without much thought given to it. We intend to remove it from the spec, but not until after we’ve defined a CSSOM API for getting information about implicit tracks, as currently this is the only way to get that information and a number of pages rely on that.

Otherwise, (e.g. when the element has [display: none](https://www.w3.org/TR/css-display-4/#propdef-display) or is not a [grid container](#grid-container)) the resolved value is simply the [computed value](https://www.w3.org/TR/css-cascade-5/#computed-value).

[](#example-d3b634e7)

```html
<style>
#grid {
  width: 500px;
  grid-template-columns:
    [a]     auto
    [b]     minmax(min-content, 1fr)
    [b c d] repeat(2, [e] 40px)
            repeat(5, auto);
}
</style>
<div id="grid">
  <div style="grid-column-start: 1; width: 50px"></div>
  <div style="grid-column-start: 9; width: 50px"></div>
</div>
<script>
  var gridElement = document.getElementById("grid");
  getComputedStyle(gridElement).gridTemplateColumns;
  // [a] 50px [b] 320px [b c d e] 40px [e] 40px 0px 0px 0px 0px 50px
</script>
```

Note: In general, resolved values are the computed values, except for a small list of legacy 2.1 properties. However, compatibility with early implementations of this module requires us to define [grid-template-rows](#propdef-grid-template-rows) and [grid-template-columns](#propdef-grid-template-columns) as returning used values.

[](#issue-e2bc4d57)The CSS Working Group is considering whether to also return used values for the [grid-placement properties](#grid-placement-property) and is looking for feedback, especially from implementors. See [discussion](https://github.com/w3c/csswg-drafts/issues/2681).

##### 7.2.6.2. Resolved Value of a Subgridded Track Listing[](#resolved-track-list-subgrid)

When an element generates a [grid container](#grid-container) box that is a [subgrid](#subgrid), the [resolved value](https://www.w3.org/TR/cssom-1/#resolved-value) of the [grid-template-rows](#propdef-grid-template-rows) and [grid-template-columns](#propdef-grid-template-columns) properties represents the [used](https://www.w3.org/TR/css-cascade-5/#used-value) number of columns, serialized as the [subgrid](#valdef-grid-template-rows-subgrid) keyword followed by a list representing each of its lines as a [line name set](#line-name-set) of all the line’s names explicitly defined on the subgrid (not including those adopted from the [parent grid](#parent-grid)), without using the [repeat()](#funcdef-track-repeat-repeat) notation.

[](#example-8cc1f771)For example, when applied to a [subgrid](#subgrid) with [grid-column: span 4](#propdef-grid-column), each of the following [grid-template-columns](#propdef-grid-template-columns) [specified values](https://www.w3.org/TR/css-cascade-5/#specified-value) becomes the corresponding [resolved values](https://www.w3.org/TR/cssom-1/#resolved-value):

```css
specified: subgrid [a] repeat(auto-fill, [b]) [c]
resolved:  subgrid [a] [b] [b] [b] [c]
```

```css
specified: subgrid [a] [a] [a] [a] repeat(auto-fill, [b]) [c] [c]
resolved:  subgrid [a] [a] [a] [a] [c]
```

```css
specified: subgrid [] [a]
resolved:  subgrid [] [a] [] [] []
```

```css
specified: subgrid [a] [b] [c] [d] [e] [f]
resolved:  subgrid [a] [b] [c] [d] [e]
```

Note: This violates the general "shortest equivalent serialization" principle by serializing empty trailing [line name sets](#line-name-set), as the trailing line name sets provide potentially-useful information about how many tracks the [subgrid](#subgrid) is spanning.

### 7.3. Named Areas: the [grid-template-areas](#propdef-grid-template-areas) property[](#grid-template-areas-property)

Name: grid-template-areas [Value:](https://www.w3.org/TR/css-values/#value-defs) none [|](https://www.w3.org/TR/css-values-4/#comb-one) [&lt;string&gt;](https://www.w3.org/TR/css-values-4/#string-value)[+](https://www.w3.org/TR/css-values-4/#mult-one-plus) [Initial:](https://www.w3.org/TR/css-cascade/#initial-values) none [Applies to:](https://www.w3.org/TR/css-cascade/#applies-to) [grid containers](#grid-container) [Inherited:](https://www.w3.org/TR/css-cascade/#inherited-property) no [Percentages:](https://www.w3.org/TR/css-values/#percentages) n/a [Computed value:](https://www.w3.org/TR/css-cascade/#computed) the keyword [none](#valdef-grid-template-areas-none) or a list of string values [Canonical order:](https://www.w3.org/TR/cssom/#serializing-css-values) per grammar [Animation type:](https://www.w3.org/TR/web-animations/#animation-type) discrete

This property specifies named grid areas, which are not associated with any particular [grid item](#grid-item), but can be referenced from the [grid-placement properties](#grid-placement-property). The syntax of the [grid-template-areas](#propdef-grid-template-areas) property also provides a visualization of the structure of the [grid](#grid), making the overall layout of the [grid container](#grid-container) easier to understand.

Values have the following meanings:

none

Indicates that no [named grid areas](#named-grid-area), and likewise no [explicit grid](#explicit-grid) tracks, are defined by this property (though explicit grid tracks could still be created by [grid-template-columns](#propdef-grid-template-columns) or [grid-template-rows](#propdef-grid-template-rows)).

Note: In the absence of an [explicit grid](#explicit-grid) any rows/columns will be [implicitly generated](#implicit-grids), and their size will be determined by the [grid-auto-rows](#propdef-grid-auto-rows) and [grid-auto-columns](#propdef-grid-auto-columns) properties.

[&lt;string&gt;](https://www.w3.org/TR/css-values-4/#string-value)+

A row is created for every separate string listed for the [grid-template-areas](#propdef-grid-template-areas) property, and a column is created for each cell in the string, when parsed as follows:

Tokenize the string into a list of the following tokens, using longest-match semantics:

- A sequence of [ident code points](https://www.w3.org/TR/css-syntax-3/#ident-code-point), representing a named cell token with a name consisting of its code points.
- A sequence of one or more "." (U+002E FULL STOP), representing a null cell token.
- A sequence of [whitespace](https://www.w3.org/TR/css-syntax-3/#whitespace), representing nothing (do not produce a token).
- A sequence of any other characters, representing a trash token.

Note: These rules can produce cell names that do not match the [&lt;ident&gt;](https://www.w3.org/TR/css-values-4/#typedef-ident) syntax, such as "1st 2nd 3rd", which requires escaping when referencing those areas by name in other properties, like [grid-row: \\31st;](#propdef-grid-row) to reference the area named 1st.

- A [null cell token](#grid-template-areas-null-cell-token) represents an unnamed area in the [grid container](#grid-container).
- A [named cell token](#grid-template-areas-named-cell-token) creates a [named grid area](#named-grid-area) with the same name. Multiple named cell tokens within and between rows create a single named grid area that spans the corresponding [grid cells](#grid-cell).
- A [trash token](#grid-template-areas-trash-token) is a syntax error, and makes the declaration invalid.

All strings must define the same number of cell tokens ([named cell tokens](#grid-template-areas-named-cell-token) and/or [null cell tokens](#grid-template-areas-null-cell-token)), and at least one cell token, or else the declaration is invalid. If a [named grid area](#named-grid-area) spans multiple [grid cells](#grid-cell), but those cells do not form a single filled-in rectangle, the declaration is invalid.

Note: Non-rectangular or disconnected regions may be permitted in a future version of this module.

[](#example-9f77ebf7)In this example, the [grid-template-areas](#propdef-grid-template-areas) property is used to create a page layout where areas are defined for header content (`head`), navigational content (`nav`), footer content (`foot`), and main content (`main`). Accordingly, the template creates three rows and two columns, with four [named grid areas](#named-grid-area). The `head` area spans both columns and the first row of the grid.

```
#grid {
  display: grid;
  grid-template-areas: "head head"
                       "nav  main"
                       "foot ...."
}
#grid > header { grid-area: head; }
#grid > nav    { grid-area: nav; }
#grid > main   { grid-area: main; }
#grid > footer { grid-area: foot; }
```

#### 7.3.1. Serialization Of Template Strings[](#serialize-template)

When serializing either the [specified](https://www.w3.org/TR/css-cascade-5/#specified-value) or [computed value](https://www.w3.org/TR/css-cascade-5/#computed-value) of a [&lt;string&gt;](https://www.w3.org/TR/css-values-4/#string-value) value of [grid-template-areas](#propdef-grid-template-areas), each [null cell token](#grid-template-areas-null-cell-token) is serialized as a single "." (U+002E FULL STOP), and consecutive cell tokens are separated by a single space (U+0020 SPACE), with all other white space elided.

#### 7.3.2. Implicitly-Assigned Line Names[](#implicit-named-lines)

The [grid-template-areas](#propdef-grid-template-areas) property generates implicitly-assigned line names from the [named grid areas](#named-grid-area) in the template. For each named grid area `foo`, four [implicitly-assigned line names](#implicitly-assigned-line-name) are created: two named `foo`-start, naming the row-start and column-start lines of the named grid area, and two named `foo`-end, naming the row-end and column-end lines of the named grid area.

These [implicitly-assigned line names](#implicitly-assigned-line-name) behave just like any other [line names](#line-name), except that they do not appear in the value of [grid-template-rows](#propdef-grid-template-rows)/[grid-template-columns](#propdef-grid-template-columns). Even if an [explicitly-assigned line name](#explicitly-assigned-line-name) with the same name is defined, the implicitly-assigned line names are just more lines with the same name.

#### 7.3.3. Implicitly-Named Areas[](#implicit-named-areas)

Since a [named grid area](#named-grid-area) is referenced by the [implicitly-assigned line names](#implicitly-assigned-line-name) it produces, explicitly adding named lines of the same form (foo-start/foo-end) effectively creates a named grid area. Such implicitly-named areas do not appear in the value of [grid-template-areas](#propdef-grid-template-areas), but can still be referenced by the [grid-placement properties](#grid-placement-property).

### 7.4. Explicit Grid Shorthand: the [grid-template](#propdef-grid-template) property[](#explicit-grid-shorthand)

Name: grid-template [Value:](https://www.w3.org/TR/css-values/#value-defs) none [|](https://www.w3.org/TR/css-values-4/#comb-one) \[ [&lt;'grid-template-rows'&gt;](#propdef-grid-template-rows) / [&lt;'grid-template-columns'&gt;](#propdef-grid-template-columns) ] | \[ [&lt;line-names&gt;](#typedef-line-names)[?](https://www.w3.org/TR/css-values-4/#mult-opt) [&lt;string&gt;](https://www.w3.org/TR/css-values-4/#string-value) [&lt;track-size&gt;](#typedef-track-size)? &lt;line-names&gt;? ][+](https://www.w3.org/TR/css-values-4/#mult-one-plus) \[ / [&lt;explicit-track-list&gt;](#typedef-explicit-track-list) ]? [Initial:](https://www.w3.org/TR/css-cascade/#initial-values) none [Applies to:](https://www.w3.org/TR/css-cascade/#applies-to) [grid containers](#grid-container) [Inherited:](https://www.w3.org/TR/css-cascade/#inherited-property) see individual properties [Percentages:](https://www.w3.org/TR/css-values/#percentages) see individual properties [Computed value:](https://www.w3.org/TR/css-cascade/#computed) see individual properties [Animation type:](https://www.w3.org/TR/web-animations/#animation-type) see individual properties [Canonical order:](https://www.w3.org/TR/cssom/#serializing-css-values) per grammar

The [grid-template](#propdef-grid-template) property is a [shorthand](https://www.w3.org/TR/css-cascade-5/#shorthand-property) for setting [grid-template-columns](#propdef-grid-template-columns), [grid-template-rows](#propdef-grid-template-rows), and [grid-template-areas](#propdef-grid-template-areas) in a single declaration. It has several distinct syntax forms:

none

Sets all three properties to their initial values ([none](#valdef-grid-template-rows-none)).

[&lt;'grid-template-rows'&gt;](#propdef-grid-template-rows) / [&lt;'grid-template-columns'&gt;](#propdef-grid-template-columns)

Sets [grid-template-rows](#propdef-grid-template-rows) and [grid-template-columns](#propdef-grid-template-columns) to the specified values, respectively, and sets [grid-template-areas](#propdef-grid-template-areas) to [none](#valdef-grid-template-areas-none).

[](#example-25dd92dd)

```
grid-template: auto 1fr / auto 1fr auto;
```

is equivalent to

```
grid-template-rows: auto 1fr;
grid-template-columns: auto 1fr auto;
grid-template-areas: none;
```

\[ [&lt;line-names&gt;](#typedef-line-names)? [&lt;string&gt;](https://www.w3.org/TR/css-values-4/#string-value) [&lt;track-size&gt;](#typedef-track-size)? &lt;line-names&gt;? ]+ \[ / [&lt;explicit-track-list&gt;](#typedef-explicit-track-list) ]?

- Sets [grid-template-areas](#propdef-grid-template-areas) to the strings listed.
- Sets [grid-template-rows](#propdef-grid-template-rows) to the [&lt;track-size&gt;](#typedef-track-size)s following each string (filling in [auto](#valdef-grid-template-columns-auto) for any missing sizes), and splicing in the named lines defined before/after each size.
- Sets [grid-template-columns](#propdef-grid-template-columns) to the track listing specified after the slash (or [none](#valdef-grid-template-rows-none), if not specified).

This syntax allows the author to align track names and sizes inline with their respective grid areas.

[](#example-4fe2f42d)

```
grid-template: [header-top] "a   a   a"     [header-bottom]
                 [main-top] "b   b   b" 1fr [main-bottom]
                          / auto 1fr auto;
```

is equivalent to

```
grid-template-areas: "a a a"
                     "b b b";
grid-template-rows: [header-top] auto [header-bottom main-top] 1fr [main-bottom];
grid-template-columns: auto 1fr auto;
```

and creates the following grid:

- Three columns, sized [auto](#valdef-grid-template-columns-auto), 1fr, and [auto](#grid-placement-auto), respectively
- Two rows sized as [auto](#valdef-grid-template-columns-auto) and 1fr, respectively.
- A line named both “header-top” and “a-start” at the top, a line with four names—​“header-bottom”, “main-top”, “a-end”, and “b-start”—​in the middle, a line named “main-bottom” and “b-end” at the bottom.
- A line named “a-start” and “b-start” on the left edge, and a line named “a-end” and “b-end” on the right edge.

The grid created by the declarations above. (The “a/b-start/end” names are [implicitly assigned](#implicitly-assigned-line-name) by the [named grid areas](#named-grid-area).)

Note: Note that the [repeat()](#funcdef-track-repeat-repeat) function isn’t allowed in these track listings, as the tracks are intended to visually line up one-to-one with the rows/columns in the “ASCII art”.

Note: The [grid](#propdef-grid) shorthand accepts the same syntax, but also resets the implicit grid properties to their initial values. Unless authors want those to cascade in separately, it is therefore recommended to use grid instead of [grid-template](#propdef-grid-template).

### 7.5. The Implicit Grid[](#implicit-grids)

The [grid-template-rows](#propdef-grid-template-rows), [grid-template-columns](#propdef-grid-template-columns), and [grid-template-areas](#propdef-grid-template-areas) properties define a fixed number of tracks that form the [explicit grid](#explicit-grid). When [grid items](#grid-item) are positioned outside of these bounds, the [grid container](#grid-container) generates implicit grid tracks by adding implicit grid lines to the [grid](#grid). These lines together with the explicit grid form the implicit grid. The [grid-auto-rows](#propdef-grid-auto-rows) and [grid-auto-columns](#propdef-grid-auto-columns) properties size these [implicit grid tracks](#implicit-grid-track), as well as any [explicit grid tracks](#explicit-grid-track) created by grid-template-areas but not explicitly sized by grid-template-rows or grid-template-columns

The [grid-auto-flow](#propdef-grid-auto-flow) property controls auto-placement of [grid items](#grid-item) without an explicit position. Once the [explicit grid](#explicit-grid) is filled (or if there is no explicit grid) auto-placement will also cause the generation of [implicit grid tracks](#implicit-grid-track).

The [grid](#propdef-grid) [shorthand](https://www.w3.org/TR/css-cascade-5/#shorthand-property) property can set the implicit grid properties ([grid-auto-flow](#propdef-grid-auto-flow), [grid-auto-rows](#propdef-grid-auto-rows), and [grid-auto-columns](#propdef-grid-auto-columns)) together with the [explicit grid properties](#explicit-grid-properties) in a single declaration.

### 7.6. Implicit Track Sizing: the [grid-auto-rows](#propdef-grid-auto-rows) and [grid-auto-columns](#propdef-grid-auto-columns) properties[](#auto-tracks)

Name: grid-auto-columns, grid-auto-rows [Value:](https://www.w3.org/TR/css-values/#value-defs) [&lt;track-size&gt;](#typedef-track-size)[+](https://www.w3.org/TR/css-values-4/#mult-one-plus) [Initial:](https://www.w3.org/TR/css-cascade/#initial-values) auto [Applies to:](https://www.w3.org/TR/css-cascade/#applies-to) [grid containers](#grid-container) [Inherited:](https://www.w3.org/TR/css-cascade/#inherited-property) no [Percentages:](https://www.w3.org/TR/css-values/#percentages) see [Track Sizing](#track-sizing) [Computed value:](https://www.w3.org/TR/css-cascade/#computed) see [Track Sizing](#track-sizing) [Canonical order:](https://www.w3.org/TR/cssom/#serializing-css-values) per grammar [Animation type:](https://www.w3.org/TR/web-animations/#animation-type) if the list lengths match, by computed value type per item; discrete otherwise

The [grid-auto-columns](#propdef-grid-auto-columns) and [grid-auto-rows](#propdef-grid-auto-rows) properties specify the size of tracks not assigned a size by [grid-template-rows](#propdef-grid-template-rows) or [grid-template-columns](#propdef-grid-template-columns). If multiple track sizes are given, the pattern is repeated as necessary to find the size of the affected tracks. The first track after the last explicitly-sized track receives the first specified size, and so on forwards; and the last [implicit grid track](#implicit-grid-track) before the [explicit grid](#explicit-grid) receives the last specified size, and so on backwards.

Note: If a grid item is positioned into a row or column that is not explicitly declared by [grid-template-rows](#propdef-grid-template-rows)/[grid-template-columns](#propdef-grid-template-columns) and/or [grid-template-areas](#propdef-grid-template-areas), [implicit grid tracks](#implicit-grid-track) are created to hold it. This can happen either by explicitly positioning into a row or column that is out of range, or by the [auto-placement algorithm](#grid-item-placement-algorithm) creating additional rows or columns.

[](#example-b32ffb8f)

```html
<style>
  #grid {
    display: grid;
    grid-template-columns: 20px;
    grid-auto-columns: 40px;
    grid-template-rows: 20px;
    grid-auto-rows: 40px;
  }
  #A { grid-column: 1; grid-row: 1; }
  #B { grid-column: 2; grid-row: 1; }
  #C { grid-column: 1; grid-row: 2; }
  #D { grid-column: 2; grid-row: 2; }
</style>

<div id="grid">
  <div id="A">A</div>
  <div id="B">B</div>
  <div id="C">C</div>
  <div id="D">D</div>
</div>
```

![](images/auto-flow.svg)

A 2×2 grid with one explicit 20px×20px grid cell in the first row+column and three additional cells resulting from the implicit 40px column and row generated to hold the additional grid items.

### 7.7. Automatic Placement: the [grid-auto-flow](#propdef-grid-auto-flow) property[](#grid-auto-flow-property)

Name: grid-auto-flow [Value:](https://www.w3.org/TR/css-values/#value-defs) \[ row [|](https://www.w3.org/TR/css-values-4/#comb-one) column ] [||](https://www.w3.org/TR/css-values-4/#comb-any) dense [Initial:](https://www.w3.org/TR/css-cascade/#initial-values) row [Applies to:](https://www.w3.org/TR/css-cascade/#applies-to) [grid containers](#grid-container) [Inherited:](https://www.w3.org/TR/css-cascade/#inherited-property) no [Percentages:](https://www.w3.org/TR/css-values/#percentages) n/a [Computed value:](https://www.w3.org/TR/css-cascade/#computed) specified keyword(s) [Canonical order:](https://www.w3.org/TR/cssom/#serializing-css-values) per grammar [Animation type:](https://www.w3.org/TR/web-animations/#animation-type) discrete

[Grid items](#grid-item) that aren’t explicitly placed are automatically placed into an unoccupied space in the [grid container](#grid-container) by the [auto-placement algorithm](#grid-item-placement-algorithm). [grid-auto-flow](#propdef-grid-auto-flow) controls how the auto-placement algorithm works, specifying exactly how auto-placed items get flowed into the grid. See [§ 8.5 Grid Item Placement Algorithm](#auto-placement-algo) for details on precisely how the auto-placement algorithm works.

row

The [auto-placement algorithm](#grid-item-placement-algorithm) places items by filling each row in turn, adding new rows as necessary. If neither [row](#valdef-grid-auto-flow-row) nor [column](#valdef-grid-auto-flow-column) is provided, row is assumed.

column

The [auto-placement algorithm](#grid-item-placement-algorithm) places items by filling each column in turn, adding new columns as necessary.

dense

If specified, the [auto-placement algorithm](#grid-item-placement-algorithm) uses a “dense” packing algorithm, which attempts to fill in holes earlier in the grid if smaller items come up later. This may cause items to appear out-of-order, when doing so would fill in holes left by larger items.

If omitted, a “sparse” algorithm is used, where the placement algorithm only ever moves “forward” in the grid when placing items, never backtracking to fill holes. This ensures that all of the auto-placed items appear “in order”, even if this leaves holes that could have been filled by later items.

Note: A future level of this module is expected to add a value that flows auto-positioned items together into a single “default” cell.

Auto-placement takes [grid items](#grid-item) in [order-modified document order](https://www.w3.org/TR/css-flexbox-1/#order-modified-document-order).

[](#example-deb30762)In the following example, there are three columns, each auto-sized to their contents. No rows are explicitly defined. The [grid-auto-flow](#propdef-grid-auto-flow) property is [row](#valdef-grid-auto-flow-row) which instructs the grid to search across its three columns starting with the first row, then the next, adding rows as needed until sufficient space is located to accommodate the position of any auto-placed [grid item](#grid-item).

![Image: A form arranged using automatic placement.](images/auto-placed-form.png)

A form arranged using automatic placement.

```
<style type="text/css">
form {
  display: grid;
  /* Define three columns, all content-sized,
     and name the corresponding lines. */
  grid-template-columns: [labels] auto [controls] auto [oversized] auto;
  grid-auto-flow: row dense;
}
form > label {
  /* Place all labels in the "labels" column and
     automatically find the next available row. */
  grid-column: labels;
  grid-row: auto;
}
form > input, form > select {
  /* Place all controls in the "controls" column and
     automatically find the next available row. */
  grid-column: controls;
  grid-row: auto;
}

#department-block {
  /* Auto place this item in the "oversized" column
     in the first row where an area that spans three rows
     won’t overlap other explicitly placed items or areas
     or any items automatically placed prior to this area. */
  grid-column: oversized;
  grid-row: span 3;
}

/* Place all the buttons of the form
   in the explicitly defined grid area. */
#buttons {
  grid-row: auto;

  /* Ensure the button area spans the entire grid element
     in the inline axis. */
  grid-column: 1 / -1;
  text-align: end;
}
</style>
<form>
  <label for="firstname">First name:</label>
  <input type="text" id="firstname" name="firstname">
  <label for="lastname">Last name:</label>
  <input type="text" id="lastname" name="lastname">
  <label for="address">Address:</label>
  <input type="text" id="address" name="address">
  <label for="address2">Address 2:</label>
  <input type="text" id="address2" name="address2">
  <label for="city">City:</label>
  <input type="text" id="city" name="city">
  <label for="state">State:</label>
  <select type="text" id="state" name="state">
    <option value="WA">Washington</option>
  </select>
  <label for="zip">Zip:</label>
  <input type="text" id="zip" name="zip">

  <div id="department-block">
    <label for="department">Department:</label>
    <select id="department" name="department" multiple>
      <option value="finance">Finance</option>
      <option value="humanresources">Human Resources</option>
      <option value="marketing">Marketing</option>
    </select>
  </div>

  <div id="buttons">
    <button id="cancel">Cancel</button>
    <button id="back">Back</button>
    <button id="next">Next</button>
  </div>
</form>
```

### 7.8. Grid Definition Shorthand: the [grid](#propdef-grid) property[](#grid-shorthand)

Name: grid [Value:](https://www.w3.org/TR/css-values/#value-defs) [&lt;'grid-template'&gt;](#propdef-grid-template) [|](https://www.w3.org/TR/css-values-4/#comb-one) [&lt;'grid-template-rows'&gt;](#propdef-grid-template-rows) / \[ auto-flow [&amp;&amp;](https://www.w3.org/TR/css-values-4/#comb-all) dense[?](https://www.w3.org/TR/css-values-4/#mult-opt) ] [&lt;'grid-auto-columns'&gt;](#propdef-grid-auto-columns)? | \[ auto-flow [&amp;&amp;](https://www.w3.org/TR/css-values-4/#comb-all) dense[?](https://www.w3.org/TR/css-values-4/#mult-opt) ] [&lt;'grid-auto-rows'&gt;](#propdef-grid-auto-rows)? / [&lt;'grid-template-columns'&gt;](#propdef-grid-template-columns) [Initial:](https://www.w3.org/TR/css-cascade/#initial-values) none [Applies to:](https://www.w3.org/TR/css-cascade/#applies-to) [grid containers](#grid-container) [Inherited:](https://www.w3.org/TR/css-cascade/#inherited-property) see individual properties [Percentages:](https://www.w3.org/TR/css-values/#percentages) see individual properties [Computed value:](https://www.w3.org/TR/css-cascade/#computed) see individual properties [Animation type:](https://www.w3.org/TR/web-animations/#animation-type) see individual properties [Canonical order:](https://www.w3.org/TR/cssom/#serializing-css-values) per grammar

The [grid](#propdef-grid) property is a [shorthand](https://www.w3.org/TR/css-cascade-5/#shorthand-property) that sets all of the [explicit grid properties](#explicit-grid-properties) ([grid-template-rows](#propdef-grid-template-rows), [grid-template-columns](#propdef-grid-template-columns), and [grid-template-areas](#propdef-grid-template-areas)), and all the [implicit grid properties](#implicit-grid-properties) ([grid-auto-rows](#propdef-grid-auto-rows), [grid-auto-columns](#propdef-grid-auto-columns), and [grid-auto-flow](#propdef-grid-auto-flow)), in a single declaration. (It does not reset the [gutter](https://www.w3.org/TR/css-align-3/#gutter) properties.)

Its syntax matches [grid-template](#propdef-grid-template), plus an additional syntax form for defining auto-flow grids:

[&lt;'grid-template'&gt;](#propdef-grid-template)

Sets the [grid-template](#propdef-grid-template) longhands as as for grid-template, and the grid-auto-* longhands to their initial values.

[&lt;'grid-template-rows'&gt;](#propdef-grid-template-rows) / \[ auto-flow &amp;&amp; dense? ] [&lt;'grid-auto-columns'&gt;](#propdef-grid-auto-columns)?

\[ auto-flow &amp;&amp; dense? ] [&lt;'grid-auto-rows'&gt;](#propdef-grid-auto-rows)? / [&lt;'grid-template-columns'&gt;](#propdef-grid-template-columns)

Sets up auto-flow, by setting the tracks in one axis explicitly (setting either [grid-template-rows](#propdef-grid-template-rows) or [grid-template-columns](#propdef-grid-template-columns) as specified, and setting the other to [none](#valdef-grid-template-rows-none)), and specifying how to auto-repeat the tracks in the other axis (setting either [grid-auto-rows](#propdef-grid-auto-rows) or [grid-auto-columns](#propdef-grid-auto-columns) as specified, and setting the other to auto). [grid-auto-flow](#propdef-grid-auto-flow) is also set to either [row](#valdef-grid-auto-flow-row) or [column](#valdef-grid-auto-flow-column) accordingly, with [dense](#valdef-grid-auto-flow-dense) if it’s specified.

All other [grid](#propdef-grid) [sub-properties](https://www.w3.org/TR/css-cascade-5/#longhand) are reset to their initial values.

Note: Note that you can only specify the explicit *or* the implicit grid properties in a single [grid](#propdef-grid) declaration. The sub-properties you don’t specify are set to their initial value, as normal for [shorthands](https://www.w3.org/TR/css-cascade-5/#shorthand-property).

[](#example-dec34e0f)In addition to accepting the [grid-template](#propdef-grid-template) shorthand syntax for setting up the [explicit grid](#explicit-grid), the [grid](#propdef-grid) shorthand can also easily set up parameters for an auto-formatted grid. For example, grid: auto-flow 1fr / 100px; is equivalent to

```
grid-template: none / 100px;
grid-auto-flow: row;
grid-auto-rows: 1fr;
grid-auto-columns: auto;
```

Similarly, [grid: none / auto-flow 1fr](#propdef-grid) is equivalent to

```
grid-template: none;
grid-auto-flow: column;
grid-auto-rows: auto;
grid-auto-columns: 1fr;
```

When serializing, if all the grid-auto-* longhands have their initial values, the [grid-template](#propdef-grid-template) syntax is used.

## 8. Placing Grid Items[](#placement)

Every [grid item](#grid-item) is associated with a [grid area](#grid-area), a rectangular set of adjacent [grid cells](#grid-cell) that the grid item occupies. This grid area defines the [containing block](https://www.w3.org/TR/css-display-4/#containing-block) for the grid item within which the self-alignment properties ([justify-self](https://www.w3.org/TR/css-align-3/#propdef-justify-self) and [align-self](https://www.w3.org/TR/css-align-3/#propdef-align-self)) determine their actual position. The cells that a grid item occupies also influence the sizing of the grid’s rows and columns, defined in [§ 12 Grid Layout Algorithm](#layout-algorithm).

The location of a [grid item’s](#grid-item) [grid area](#grid-area) within the [grid](#grid) is defined by its placement, which consists of a [grid position](#grid-position) and a [grid span](#grid-span):

grid position

The [grid item](#grid-item)’s location in the [grid](#grid) in each axis. A [grid position](#grid-position) can be either definite (explicitly specified) or automatic (determined by [auto-placement](#auto-placement)).

grid span

How many [grid tracks](#grid-track) the [grid item](#grid-item) occupies in each axis. The [grid span](#grid-span) in an axis can be [implicit](#implicit-grid-span), [explicit](#explicit-grid-span), or [automatic](#automatic-grid-span):

- If both the \*-start and \*-end values of its [grid-placement properties](#grid-placement-property) specify a line, its [grid span](#grid-span) is implicit.
- If it has an explicit span value, its [grid span](#grid-span) is explicit.
- Otherwise, its [grid span](#grid-span) is automatic: if it is [subgridded](#subgridded-axis) in that axis, its grid span is [determined](#subgrid-span) from its [&lt;line-name-list&gt;](#typedef-line-name-list); otherwise its grid span is 1.

The grid-placement properties—​the longhands [grid-row-start](#propdef-grid-row-start), [grid-row-end](#propdef-grid-row-end), [grid-column-start](#propdef-grid-column-start), [grid-column-end](#propdef-grid-column-end), and their shorthands [grid-row](#propdef-grid-row), [grid-column](#propdef-grid-column), and [grid-area](#propdef-grid-area)—​allow the author to specify a [grid item](#grid-item)’s [placement](#grid-placement) by providing any (or none) of the following six pieces of information:

Row Column `Start` row-start line column-start line `End` row-end line column-end line `Span` row span column span

A definite value for any two of `Start`, `End`, and `Span` in a given dimension implies a definite value for the third.

### 8.1. Common Patterns for Grid Placement[](#common-uses)

*This section is informative.*

The [grid-placement property](#grid-placement-property) longhands are organized into three shorthands:

[grid-area](#propdef-grid-area) [grid-column](#propdef-grid-column) [grid-row](#propdef-grid-row) [grid-column-start](#propdef-grid-column-start) [grid-column-end](#propdef-grid-column-end) [grid-row-start](#propdef-grid-row-start) [grid-row-end](#propdef-grid-row-end)

#### 8.1.1. Named Areas[](#common-uses-named-areas)

An item can be placed into a [named grid area](#named-grid-area) (such as those produced by the template in [grid-template-areas](#propdef-grid-template-areas)) by specifying the area’s name in [grid-area](#propdef-grid-area):

[](#example-a024ab3a)

```
article {
  grid-area: main;
  /* Places item into the named area "main". */
}
```

An item can also be *partially* aligned with a [named grid area](#named-grid-area), with other edges aligned to some other line:

[](#example-676a9f77)

```
.one {
  grid-row-start: main;
  /* Align the row-start edge to the start edge of the "main" named area. */
}
```

#### 8.1.2. Numeric Indexes and Spans[](#common-uses-numeric)

Grid items can be positioned and sized by number, which is particularly helpful for script-driven layouts:

[](#example-85154965)

```
.two {
  grid-row: 2;    /* Place item in the second row. */
  grid-column: 3; /* Place item in the third column. */
  /* Equivalent to grid-area: 2 / 3; */
}
```

By default, a grid item has a span of 1. Different spans can be given explicitly:

[](#example-a58ad9ce)

```
.three {
  grid-row: 2 / span 5;
  /* Starts in the 2nd row,
     spans 5 rows down (ending in the 7th row). */
}

.four {
  grid-row: span 5 / 7;
  /* Ends in the 7th row,
     spans 5 rows up (starting in the 2nd row). */
}
```

Note: Note that grid indexes are [writing mode](https://www.w3.org/TR/css-writing-modes-4/#writing-mode) relative. For example, in a right-to-left language like Arabic, the first column is the rightmost column.

#### 8.1.3. Named Lines and Spans[](#common-uses-named-lines)

Instead of counting lines by number, lines can be referenced by their [line name](#line-name):

[](#example-9c11bd3f)

```
.five {
  grid-column: first / middle;
  /* Span from line "first" to line "middle". */
}
```

Note: Note that if a [named grid area](#named-grid-area) has the same name as a [line name](#line-name), the placement algorithm will prefer to use named grid area’s lines instead.

If there are multiple lines of the same name, they effectively establish a named set of grid lines, which can be exclusively indexed by filtering the placement by name:

[](#example-ca2f749c)

```
.six {
  grid-row: text 5 / text 7;
  /* Span between the 5th and 7th lines named "text". */
  grid-row: text 5 / span text 2;
  /* Same as above - start at the 5th line named "text",
     then span across two more "text" lines, to the 7th. */
}
```

#### 8.1.4. Auto Placement[](#common-uses-auto-placement)

A [grid item](#grid-item) can be automatically placed into the next available empty [grid cell](#grid-cell), growing the [grid](#grid) if there’s no space left.

[](#example-b79de521)

```
.eight {
  grid-area: auto; /* Initial value */
}
```

This can be used, for example, to list a number of sale items on a catalog site in a grid pattern.

Auto-placement can be combined with an explicit span, if the item should take up more than one cell:

[](#example-f32a97df)

```
.nine {
  grid-area: span 2 / span 3;
  /* Auto-placed item, covering two rows and three columns. */
}
```

Whether the [auto-placement algorithm](#grid-item-placement-algorithm) searches across and adds rows, or searches across and adds columns, is controlled by the [grid-auto-flow](#propdef-grid-auto-flow) property.

Note: By default, the [auto-placement algorithm](#grid-item-placement-algorithm) looks linearly through the grid without backtracking; if it has to skip some empty spaces to place a larger item, it will not return to fill those spaces. To change this behavior, specify the [dense](#valdef-grid-auto-flow-dense) keyword in [grid-auto-flow](#propdef-grid-auto-flow).

### 8.2. Grid Item Placement vs. Source Order[](#placement-a11y)

> “With great power comes great responsibility.”

The abilities of the [grid-placement properties](#grid-placement-property) allow content to be freely arranged and reordered within the [grid](#grid), such that the visual presentation can be largely disjoint from the underlying document source order. These abilities allow the author great freedom in tailoring the rendering to different devices and modes of presentation e.g. using [media queries](https://www.w3.org/TR/mediaqueries-5/#media-query). However **they are not a substitute for correct source ordering**.

Correct source order is important for speech, for sequential navigation (such as keyboard navigation), and non-CSS UAs such as search engines, tactile browsers, etc. Grid placement *only* affects the visual presentation! This allows authors to optimize the document source for non-CSS/non-visual interaction modes, and use grid placement techniques to further manipulate the visual presentation so as to leave that source order intact.

### 8.3. Line-based Placement: the [grid-row-start](#propdef-grid-row-start), [grid-column-start](#propdef-grid-column-start), [grid-row-end](#propdef-grid-row-end), and [grid-column-end](#propdef-grid-column-end) properties[](#line-placement)

Name: grid-row-start, grid-column-start, grid-row-end, grid-column-end [Value:](https://www.w3.org/TR/css-values/#value-defs) [&lt;grid-line&gt;](#typedef-grid-row-start-grid-line) [Initial:](https://www.w3.org/TR/css-cascade/#initial-values) auto [Applies to:](https://www.w3.org/TR/css-cascade/#applies-to) [grid items](#grid-item) and absolutely-positioned boxes whose containing block is a [grid container](#grid-container) [Inherited:](https://www.w3.org/TR/css-cascade/#inherited-property) no [Percentages:](https://www.w3.org/TR/css-values/#percentages) n/a [Computed value:](https://www.w3.org/TR/css-cascade/#computed) specified keyword, identifier, and/or integer [Canonical order:](https://www.w3.org/TR/cssom/#serializing-css-values) per grammar [Animation type:](https://www.w3.org/TR/web-animations/#animation-type) discrete

```
<grid-line> =
  auto |
  <custom-ident> |
  [ [ <integer [-∞,-1]> | <integer [1,∞]> ] && <custom-ident>? ] |
  [ span && [ <integer [1,∞]> || <custom-ident> ] ]
```

The [grid-row-start](#propdef-grid-row-start), [grid-column-start](#propdef-grid-column-start), [grid-row-end](#propdef-grid-row-end), and [grid-column-end](#propdef-grid-column-end) properties determine a [grid item](#grid-item)’s size and location within the [grid](#grid) by contributing a line, a span, or nothing (automatic) to its [grid placement](#grid-placement), thereby specifying the [inline-start](https://www.w3.org/TR/css-writing-modes-4/#inline-start), [block-start](https://www.w3.org/TR/css-writing-modes-4/#block-start), [inline-end](https://www.w3.org/TR/css-writing-modes-4/#inline-end), and [block-end](https://www.w3.org/TR/css-writing-modes-4/#block-end) edges of its [grid area](#grid-area).

Values have the following meanings:

[&lt;custom-ident&gt;](https://www.w3.org/TR/css-values-4/#identifier-value)

First attempt to match the [grid area](#grid-area)’s edge to a [named grid area](#named-grid-area): if there is a [grid line](#grid-line) whose [line name](#line-name) is [&lt;custom-ident&gt;](https://www.w3.org/TR/css-values-4/#identifier-value)-start (for grid-\*-start) / [&lt;custom-ident&gt;](https://www.w3.org/TR/css-values-4/#identifier-value)-end (for grid-\*-end), contributes the first such line to the [grid item](#grid-item)’s [placement](#grid-placement).

Note: [Named grid areas](#named-grid-area) automatically generate [implicitly-assigned line names](#implicitly-assigned-line-name) of this form, so specifying [grid-row-start: foo](#propdef-grid-row-start) will choose the start edge of that named grid area (unless another line named foo-start was explicitly specified before it).

Otherwise, treat this as if the integer 1 had been specified along with the [&lt;custom-ident&gt;](https://www.w3.org/TR/css-values-4/#identifier-value).

\[ [&lt;integer \[-∞,-1\]&gt;](https://www.w3.org/TR/css-values-4/#integer-value) | &lt;integer \[1,∞]&gt; ] &amp;&amp; [&lt;custom-ident&gt;](https://www.w3.org/TR/css-values-4/#identifier-value)?

Contributes the `N`th [grid line](#grid-line) to the [grid item](#grid-item)’s [placement](#grid-placement). If a negative integer is given, it instead counts in reverse, starting from the end edge of the [explicit grid](#explicit-grid).

If a name is given as a [&lt;custom-ident&gt;](https://www.w3.org/TR/css-values-4/#identifier-value), only lines with that name are counted. If not enough lines with that name exist, all [implicit grid lines](#implicit-grid-lines) are assumed to have that name for the purpose of finding this position.

An [&lt;integer&gt;](https://www.w3.org/TR/css-values-4/#integer-value) value of zero makes the declaration invalid.

span &amp;&amp; \[ [&lt;integer \[1,∞\]&gt;](https://www.w3.org/TR/css-values-4/#integer-value) || [&lt;custom-ident&gt;](https://www.w3.org/TR/css-values-4/#identifier-value) ]

Contributes a [grid span](#grid-span) to the [grid item](#grid-item)’s [placement](#grid-placement) such that the corresponding edge of the grid item’s [grid area](#grid-area) is `N` lines from its opposite edge in the corresponding direction. For example, [grid-column-end: span 2](#propdef-grid-column-end) indicates the second grid line in the endward direction from the [grid-column-start](#propdef-grid-column-start) line.

If a name is given as a [&lt;custom-ident&gt;](https://www.w3.org/TR/css-values-4/#identifier-value), only lines with that name are counted. If not enough lines with that name exist, all [implicit grid lines](#implicit-grid-lines) on the side of the [explicit grid](#explicit-grid) corresponding to the search direction are assumed to have that name for the purpose of counting this span.

[](#example-4e2ea185)For example, given the following declarations:

```css
.grid { grid-template-columns: 100px; }
.griditem { grid-column: span foo / 4; }
```

The [grid container](#grid-container) has an [explicit grid](#explicit-grid) with two grid lines, numbered 1 and 2. The [grid item’s](#grid-item) column-end edge is specified to be at line 4, so two lines are generated in the endward side of the [implicit grid](#implicit-grid).

Its column-start edge must be the first "foo" line it can find startward of that. There is no "foo" line in the grid, though, so the only possibility is a line in the [implicit grid](#implicit-grid). Line 3 is not a candidate, because it’s on the endward side of the [explicit grid](#explicit-grid), while the [grid-column-start](#propdef-grid-column-start) span forces it to search startward. So, the only option is for the implicit grid to generate a line on the startward side of the explicit grid.

![](images/implicit-lines-search.svg)

An illustration of the result.

If the [&lt;integer&gt;](https://www.w3.org/TR/css-values-4/#integer-value) is omitted, it defaults to 1. Negative integers or zero are invalid.

auto

The property contributes nothing to the [grid item](#grid-item)’s [placement](#grid-placement), indicating [auto-placement](#auto-placement) or a default span of one. (See [§ 8 Placing Grid Items](#placement), above.)

In all the above productions, the [&lt;custom-ident&gt;](https://www.w3.org/TR/css-values-4/#identifier-value) additionally excludes the keywords span and auto.

[](#example-4a841210)Given a single-row, 8-column grid and the following 9 named lines:

```
1  2  3  4  5  6  7  8  9
+--+--+--+--+--+--+--+--+
|  |  |  |  |  |  |  |  |
A  B  C  A  B  C  A  B  C
|  |  |  |  |  |  |  |  |
+--+--+--+--+--+--+--+--+
```

The following declarations place the grid item between the lines indicated by index:

```
grid-column-start: 4; grid-column-end: auto;
/* Line 4 to line 5 */

grid-column-start: auto; grid-column-end: 6;
/* Line 5 to line 6 */

grid-column-start: C; grid-column-end: C -1;
/* Line 3 to line 9 */

grid-column-start: C; grid-column-end: span C;
/* Line 3 to line 6 */

grid-column-start: span C; grid-column-end: C -1;
/* Line 6 to line 9 */

grid-column-start: span C; grid-column-end: span C;
/* Error: The end span is ignored, and an auto-placed
   item can’t span to a named line.
   Equivalent to ''grid-column: span 1;''. */

grid-column-start: 5; grid-column-end: C -1;
/* Line 5 to line 9 */

grid-column-start: 5; grid-column-end: span C;
/* Line 5 to line 6 */

grid-column-start: 8; grid-column-end: 8;
/* Error: line 8 to line 9 */

grid-column-start: B 2; grid-column-end: span 1;
/* Line 5 to line 6 */
```

#### 8.3.1. Grid Placement Conflict Handling[](#grid-placement-errors)

If the [placement](#grid-placement) for a [grid item](#grid-item) contains two lines, and the [start](https://www.w3.org/TR/css-writing-modes-4/#start) line is further end-ward than the [end](https://www.w3.org/TR/css-writing-modes-4/#end) line, swap the two lines. If the start line is *equal* to the end line, remove the end line.

If the [placement](#grid-placement) contains two spans, remove the one contributed by the [end](https://www.w3.org/TR/css-writing-modes-4/#end) [grid-placement property](#grid-placement-property).

If the [placement](#grid-placement) contains only a span for a named line, replace it with a span of 1.

### 8.4. Placement Shorthands: the [grid-column](#propdef-grid-column), [grid-row](#propdef-grid-row), and [grid-area](#propdef-grid-area) properties[](#placement-shorthands)

Name: grid-row, grid-column [Value:](https://www.w3.org/TR/css-values/#value-defs) [&lt;grid-line&gt;](#typedef-grid-row-start-grid-line) \[ / &lt;grid-line&gt; ][?](https://www.w3.org/TR/css-values-4/#mult-opt) [Initial:](https://www.w3.org/TR/css-cascade/#initial-values) auto [Applies to:](https://www.w3.org/TR/css-cascade/#applies-to) [grid items](#grid-item) and absolutely-positioned boxes whose containing block is a [grid container](#grid-container) [Inherited:](https://www.w3.org/TR/css-cascade/#inherited-property) no [Percentages:](https://www.w3.org/TR/css-values/#percentages) N/A [Computed value:](https://www.w3.org/TR/css-cascade/#computed) see individual properties [Animation type:](https://www.w3.org/TR/web-animations/#animation-type) discrete [Canonical order:](https://www.w3.org/TR/cssom/#serializing-css-values) per grammar

The [grid-row](#propdef-grid-row) and [grid-column](#propdef-grid-column) properties are shorthands for [grid-row-start](#propdef-grid-row-start)/[grid-row-end](#propdef-grid-row-end) and [grid-column-start](#propdef-grid-column-start)/[grid-column-end](#propdef-grid-column-end), respectively.

If two [&lt;grid-line&gt;](#typedef-grid-row-start-grid-line) values are specified, the [grid-row-start](#propdef-grid-row-start)/[grid-column-start](#propdef-grid-column-start) longhand is set to the value before the slash, and the [grid-row-end](#propdef-grid-row-end)/[grid-column-end](#propdef-grid-column-end) longhand is set to the value after the slash.

When the second value is omitted, if the first value is a [&lt;custom-ident&gt;](https://www.w3.org/TR/css-values-4/#identifier-value), the [grid-row-end](#propdef-grid-row-end)/[grid-column-end](#propdef-grid-column-end) longhand is also set to that &lt;custom-ident&gt;; otherwise, it is set to [auto](#grid-placement-auto).

Name: grid-area [Value:](https://www.w3.org/TR/css-values/#value-defs) [&lt;grid-line&gt;](#typedef-grid-row-start-grid-line) \[ / &lt;grid-line&gt; ][{0,3}](https://www.w3.org/TR/css-values-4/#mult-num-range) [Initial:](https://www.w3.org/TR/css-cascade/#initial-values) auto [Applies to:](https://www.w3.org/TR/css-cascade/#applies-to) [grid items](#grid-item) and absolutely-positioned boxes whose containing block is a [grid container](#grid-container) [Inherited:](https://www.w3.org/TR/css-cascade/#inherited-property) no [Percentages:](https://www.w3.org/TR/css-values/#percentages) N/A [Computed value:](https://www.w3.org/TR/css-cascade/#computed) see individual properties [Animation type:](https://www.w3.org/TR/web-animations/#animation-type) discrete [Canonical order:](https://www.w3.org/TR/cssom/#serializing-css-values) per grammar

The [grid-area](#propdef-grid-area) property is a [shorthand](https://www.w3.org/TR/css-cascade-5/#shorthand-property) for [grid-row-start](#propdef-grid-row-start), [grid-column-start](#propdef-grid-column-start), [grid-row-end](#propdef-grid-row-end) and [grid-column-end](#propdef-grid-column-end).

If four [&lt;grid-line&gt;](#typedef-grid-row-start-grid-line) values are specified, [grid-row-start](#propdef-grid-row-start) is set to the first value, [grid-column-start](#propdef-grid-column-start) is set to the second value, [grid-row-end](#propdef-grid-row-end) is set to the third value, and [grid-column-end](#propdef-grid-column-end) is set to the fourth value.

When [grid-column-end](#propdef-grid-column-end) is omitted, if [grid-column-start](#propdef-grid-column-start) is a [&lt;custom-ident&gt;](https://www.w3.org/TR/css-values-4/#identifier-value), grid-column-end is set to that &lt;custom-ident&gt;; otherwise, it is set to [auto](#grid-placement-auto).

When [grid-row-end](#propdef-grid-row-end) is omitted, if [grid-row-start](#propdef-grid-row-start) is a [&lt;custom-ident&gt;](https://www.w3.org/TR/css-values-4/#identifier-value), grid-row-end is set to that &lt;custom-ident&gt;; otherwise, it is set to [auto](#grid-placement-auto).

When [grid-column-start](#propdef-grid-column-start) is omitted, if [grid-row-start](#propdef-grid-row-start) is a [&lt;custom-ident&gt;](https://www.w3.org/TR/css-values-4/#identifier-value), all four longhands are set to that value. Otherwise, it is set to [auto](#grid-placement-auto).

Note: The resolution order for this shorthand is row-start/column-start/row-end/column-end, which goes CCW for LTR pages, the opposite direction of the related 4-edge properties using physical directions, like [margin](https://www.w3.org/TR/CSS2/box.html#propdef-margin).

### 8.5. Grid Item Placement Algorithm[](#auto-placement-algo)

The following grid item placement algorithm resolves [automatic positions](#automatic-grid-position) of [grid items](#grid-item) into [definite positions](#definite-grid-position), ensuring that every grid item has a well-defined [grid area](#grid-area) to lay out into. ([Grid spans](#grid-span) need no special resolution; if they’re not explicitly specified, they default to 1.)

Note: This algorithm can result in the creation of new rows or columns in the [implicit grid](#implicit-grid), if there is no room in the [explicit grid](#explicit-grid) to place an auto-positioned [grid item](#grid-item).

Every [grid cell](#grid-cell) (in both the [explicit](#explicit-grid) and [implicit grids](#implicit-grid)) can be occupied or unoccupied. A cell is [occupied](#occupied) if it’s covered by the [grid area](#grid-area) of a [grid item](#grid-item) with a [definite grid position](#definite-grid-position); otherwise, the cell is [unoccupied](#unoccupied). A cell’s occupied/unoccupied status can change during this algorithm.

To aid in clarity, this algorithm is written with the assumption that [grid-auto-flow](#propdef-grid-auto-flow) has [row](#valdef-grid-auto-flow-row) specified. If it is instead set to [column](#valdef-grid-auto-flow-column), swap all mentions of rows and columns, inline and block, etc. in this algorithm.

Note: The [auto-placement algorithm](#grid-item-placement-algorithm) works with the [grid items](#grid-item) in [order-modified document order](https://www.w3.org/TR/css-flexbox-1/#order-modified-document-order), not their original document order.

0. **Generate anonymous grid items** as described in [§ 6 Grid Items](#grid-items). (Anonymous [grid items](#grid-item) are always auto-placed, since their boxes can’t have any [grid-placement properties](#grid-placement-property) specified.)
1. **Position anything that’s not auto-positioned.**
2. **Process the items locked to a given row.**
   
   For each [grid item](#grid-item) with a [definite row position](#definite-grid-position) (that is, the [grid-row-start](#propdef-grid-row-start) and [grid-row-end](#propdef-grid-row-end) properties define a definite grid position), in [order-modified document order](https://www.w3.org/TR/css-flexbox-1/#order-modified-document-order):
   
   “sparse” packing (default behavior)
   
   Set the column-start line of its [placement](#grid-placement) to the earliest (smallest positive index) line index that ensures this item’s [grid area](#grid-area) will not overlap any [occupied](#occupied) grid cells and that is past any [grid items](#grid-item) previously placed in this row by this step.
   
   “dense” packing ([dense](#valdef-grid-auto-flow-dense) specified)
   
   Set the column-start line of its [placement](#grid-placement) to the earliest (smallest positive index) line index that ensures this item’s [grid area](#grid-area) will not overlap any [occupied](#occupied) grid cells.
3. **Determine the columns in the implicit grid.**
   
   Create columns in the [implicit grid](#implicit-grid):
   
   1. Start with the columns from the [explicit grid](#explicit-grid).
   2. Among all the items with a [definite column position](#definite-grid-position) (explicitly positioned items, items positioned in the previous step, and items not yet positioned but with a definite column) add columns to the beginning and end of the [implicit grid](#implicit-grid) as necessary to accommodate those items.
   3. If the largest [column span](#grid-span) among all the items *without* a [definite column position](#definite-grid-position) is larger than the width of the [implicit grid](#implicit-grid), add columns to the end of the implicit grid to accommodate that column span.
   
   [](#example-236efe03)For example, in the following style fragment:
   
   ```
   #grid {
     display: grid;
     grid-template-columns: repeat(5, 100px);
     grid-auto-flow: row;
   }
   #grid-item {
     grid-column: 4 / span 3;
   }
   ```
   
   The number of columns needed is 6. The [explicit grid](#explicit-grid) provides 5 columns (from [grid-template-columns](#propdef-grid-template-columns)) with lines number 1 through 6, but `#grid-item`’s column position means it ends on line 7, which requires an additional column added to the end of the [implicit grid](#implicit-grid).
4. **Position the remaining grid items.**
   
   The auto-placement cursor defines the current “insertion point” in the grid, specified as a pair of row and column [grid lines](#grid-line). Initially the [auto-placement cursor](#auto-placement-cursor) is set to the start-most row and column lines in the [implicit grid](#implicit-grid).
   
   The [grid-auto-flow](#propdef-grid-auto-flow) value in use determines how to position the items:
   
   “sparse” packing (default behavior)
   
   For each [grid item](#grid-item) that hasn’t been positioned by the previous steps, in [order-modified document order](https://www.w3.org/TR/css-flexbox-1/#order-modified-document-order):
   
   If the item has a [definite column position](#definite-grid-position):
   
   1. Set the column position of the [cursor](#auto-placement-cursor) to the [grid item’s](#grid-item) column-start line. If this is less than the previous column position of the cursor, increment the row position by 1.
   2. Increment the [cursor](#auto-placement-cursor)’s row position until a value is found where the [grid item](#grid-item) does not overlap any [occupied](#occupied) grid cells (creating new rows in the [implicit grid](#implicit-grid) as necessary).
   3. Set the item’s row-start line to the [cursor’s](#auto-placement-cursor) row position, and set the item’s row-end line according to its span from that position.
   
   If the item has an [automatic grid position](#automatic-grid-position) in both axes:
   
   1. Increment the column position of the [auto-placement cursor](#auto-placement-cursor) until either this item’s [grid area](#grid-area) does not overlap any [occupied](#occupied) grid cells, or the cursor’s column position, plus the item’s column span, overflow the number of columns in the implicit grid, as determined earlier in this algorithm.
   2. If a non-overlapping position was found in the previous step, set the item’s row-start and column-start lines to the [cursor’s](#auto-placement-cursor) position. Otherwise, increment the auto-placement cursor’s row position (creating new rows in the [implicit grid](#implicit-grid) as necessary), set its column position to the start-most column line in the implicit grid, and return to the previous step.
   
   “dense” packing ([dense](#valdef-grid-auto-flow-dense) specified)
   
   For each [grid item](#grid-item) that hasn’t been positioned by the previous steps, in [order-modified document order](https://www.w3.org/TR/css-flexbox-1/#order-modified-document-order):
   
   If the item has a [definite column position](#definite-grid-position):
   
   1. Set the row position of the cursor to the start-most row line in the [implicit grid](#implicit-grid). Set the column position of the cursor to the [grid item’s](#grid-item) column-start line.
   2. Increment the [auto-placement cursor](#auto-placement-cursor)’s row position until a value is found where the [grid item](#grid-item) does not overlap any [occupied](#occupied) grid cells (creating new rows in the [implicit grid](#implicit-grid) as necessary).
   3. Set the item’s row-start line index to the [cursor’s](#auto-placement-cursor) row position. (Implicitly setting the item’s row-end line according to its span, as well.)
   
   If the item has an [automatic grid position](#automatic-grid-position) in both axes:
   
   1. Set the cursor’s row and column positions to start-most row and column lines in the [implicit grid](#implicit-grid).
   2. Increment the column position of the [auto-placement cursor](#auto-placement-cursor) until either this item’s [grid area](#grid-area) does not overlap any [occupied](#occupied) grid cells, or the cursor’s column position, plus the item’s column span, overflow the number of columns in the implicit grid, as determined earlier in this algorithm.
   3. If a non-overlapping position was found in the previous step, set the item’s row-start and column-start lines to the [cursor’s](#auto-placement-cursor) position. Otherwise, increment the auto-placement cursor’s row position (creating new rows in the [implicit grid](#implicit-grid) as necessary), reset its column position to the start-most column line in the implicit grid, and return to the previous step.

## 9. Subgrids[](#subgrids)

A [subgrid](#subgrid) behaves just like a normal [grid container](#grid-container) except that:

- [](#subgrid-tracks)Placing the [subgrid](#subgrid) creates a correspondence between its [subgridded](#subgridded-axis) tracks and those that it spans in its [parent grid](#parent-grid). The grid lines thus shared between the subgrid and its parent form the subgrid’s [explicit grid](#explicit-grid), and its track sizes are governed by the parent grid.
- [](#subgrid-span)The number of explicit tracks in the [subgrid](#subgrid) in a [subgridded](#subgridded-axis) dimension always corresponds to the number of [grid tracks](#grid-track) that it spans in its parent [grid](#grid):
  
  - If the [subgrid](#subgrid)’s [grid span](#grid-span) in the subgridded dimension is [explicit](#explicit-grid-span) or [implicit](#implicit-grid-span), then the number of explicit tracks in each subgridded dimension is taken from its used grid span in that dimension (regardless of its grid-template-* properties).
  - If it has an [automatic grid span](#automatic-grid-span), then its used [grid span](#grid-span) is taken from the number of explicit tracks specified for that axis by its grid-template-* properties, floored at one.
  
  Note: The explicit grid determined here can be further truncated if the placement of the [subgrid](#subgrid) is clamped by its parent grid. See [the "no implicit tracks" bullet point](#subgrid-implicit).
  
  If the grid-template-* properties specify a [&lt;line-name-list&gt;](#typedef-line-name-list) in a [subgridded axis](#subgridded-axis), the used value is truncated to match the used number of explicit tracks.
- [](#subgrid-indexing)The [grid-placement properties](#grid-placement-property) of the [subgrid](#subgrid)’s [grid items](#grid-item) and the line numbers they use are scoped to the lines covered by the subgrid, exactly consistent with the lines outside the subgrid being excluded from its [explicit grid](#explicit-grid). E.g. numeric indices count starting from the first line of the subgrid rather than the first line of the [parent grid](#parent-grid).
  
  Line numbering and placement rules obey the [subgrid](#subgrid)’s own [writing mode](https://www.w3.org/TR/css-writing-modes-4/#writing-mode), just as they would for a nested independent grid.
- [](#subgrid-line-name-inheritance)Since [subgrids](#subgrid) can be placed before their contents are placed, the [subgridded](#subgridded-axis) lines automatically receive the [explicitly-assigned line names](#explicitly-assigned-line-name) specified on the corresponding lines of the parent [grid](#grid).
  
  These names are in *addition* to any [line names](#line-name) specified locally on the [subgrid](#subgrid).
- [](#subgrid-area-inheritance)When a [subgrid](#subgrid) overlaps a [named grid area](#named-grid-area) in its parent that was created by a [grid-template-areas](#propdef-grid-template-areas) property declaration, [implicitly-assigned line names](#implicitly-assigned-line-name) are assigned to represent the parent’s named grid area within the subgrid.
  
  Note: If a [named grid area](#named-grid-area) only partially overlaps the [subgrid](#subgrid), its [implicitly-assigned line names](#implicitly-assigned-line-name) will be assigned to the first and/or last line of the subgrid such that a named grid area exists representing that partially overlapped area of the subgrid; thus the [line name](#line-name) assignments of the subgrid might not always correspond exactly to the line name assignments of the parent [grid](#grid).
  
  These names are also in *addition* to any [line names](#line-name) specified locally on the [subgrid](#subgrid).
  
  [](#example-fffff4da)In the following example, the 4-column grand-parent grid has both explicit line names and implicit ones generated by [grid-template-areas](#propdef-grid-template-areas):
  
  ```
  <style type="css">
    .outer {
      display: grid;
      grid-template-columns:
        [outer-edge] 20px [main-start] 1fr [center] 1fr max-content [main-end];
      grid-template-areas:
        "gutter info info photos";
    }
    .middle {
      grid-column: main-start / main-end;
      display: grid;
      grid: subgrid / subgrid;
    }
    .inner {
      grid-column: center / -1;
      display: grid;
      grid: subgrid / subgrid;
    }
  </style>
  
  <div class="outer">
    <div class="middle">
      <div class="inner">&hellip;</div>
    </div>
  </div>
  ```
  
  After all types of name resolution, the names for each grid will be:
  
  ```
  .outer = [outer-edge gutter-start] [gutter-end info-start main-start] [center] [info-end photos-start] [main-end photos-end]
  .middle = [info-start main-start] [center] [info-end photos-start] [main-end photos-end]
  .inner = [center info-start] [info-end photos-start] [main-end photos-end]
  ```
  
  Notice that all the [explicitly-assigned line names](#explicitly-assigned-line-name) inherit straight through to .inner, but the [implicitly-assigned line names](#implicitly-assigned-line-name) are calculated based on each [subgrid](#subgrid)’s overlap of the original [named grid area](#named-grid-area).
- [](#subgrid-implicit)The [subgrid](#subgrid) does not have any [implicit grid tracks](#implicit-grid-track) in the [subgridded](#subgridded-axis) dimension(s). Hypothetical [implicit grid lines](#implicit-grid-lines) are used to resolve placement as usual when the [explicit grid](#explicit-grid) does not have enough lines; however each [grid item](#grid-item)’s [grid area](#grid-area) is [clamped](#clamp-a-grid-area) to the subgrid’s explicit grid (using the same procedure as for clamping placement in an overly-large grid).
  
  [](#example-f40fdc9d)For example, if a span 1 subgrid has a [grid item](#grid-item) with [grid-column: 2 / span 3;](#propdef-grid-column), then that item is instead forced into (and limited to) the first (only) track in the subgrid.
  
  Note: This means that a subgrid might have fewer tracks than it expected, if its parent is also a subgrid and therefore has a fixed number of tracks. (A subgrid might likewise have fewer tracks than expected because its parent is hitting the [UA limit on grid tracks](#overlarge-grids).)
- [](#subgrid-size-contribution)The [subgrid](#subgrid) itself lays out as an ordinary [grid item](#grid-item) in its [parent grid](#parent-grid), but acts as if it was completely empty for track sizing purposes in the [subgridded](#subgridded-axis) dimension.
- [](#subgrid-item-contribution)The [subgrid](#subgrid)’s own [grid items](#grid-item) participate in the sizing of its [parent grid](#parent-grid) in the [subgridded](#subgridded-axis) dimension(s) and are aligned to it in those dimensions.
  
  In this process, the sum of the [subgrid](#subgrid)’s margin, padding, [scrollbar gutter](https://www.w3.org/TR/css-overflow-3/#scrollbar-gutter), and border at each edge are applied as an extra layer of (potentially negative) margin to the items at those edges. This extra layer of “margin” accumulates through multiple levels of subgrids.
  
  [](#example-edd2713b)For example, if we have a 3×3 grid with the following tracks:
  
  ```
  #parent-grid { grid-template-columns: 300px auto 300px; }
  ```
  
  If a subgrid covers the last two tracks, its first two columns correspond to the parent grid’s last two columns, and any items positioned into those tracks participate in sizing the parent grid. Specifically, an item positioned in the first track of the subgrid influences the auto-sizing of the parent grid’s middle track.
  
  ```
  #subgrid { grid-column: 2 / span 2; } /* cover parent’s 2nd and 3rd tracks */
  #subgrid > :first-child { grid-column: 1; } /* subgrid’s 1st track, parent grid’s 2nd track */
  ```
  
  If the subgrid has margins/borders/padding, the size of those margins/borders/padding also influences sizing. For example, if the subgrid has 100px padding:
  
  ```
  #subgrid { padding: 100px; }
  ```
  
  Then a [grid item](#grid-item) in the [subgrid’s](#subgrid) first track acts as if it has an additional 100px of top, left, and bottom margin, influencing the sizing of the parent grid’s tracks and the grid item’s own position.
  
  Meanwhile, half the size of the difference between the [subgrid](#subgrid)’s [gutters](https://www.w3.org/TR/css-align-3/#gutter) ([row-gap](https://www.w3.org/TR/css-align-3/#propdef-row-gap)/[column-gap](https://www.w3.org/TR/css-align-3/#propdef-column-gap)) and its [parent grid](#parent-grid)’s gutters is applied as an extra layer of (potentially negative) margin to the items not at those edges. This extra layer of “margin” also accumulates through multiple levels of subgrids. A value of [normal](https://www.w3.org/TR/css-align-3/#valdef-row-gap-normal) indicates that the subgrid has the same size gutters as its parent grid, i.e. the applied difference is zero.
  
  Note: The end result will be that the parent’s grid tracks will be sized as specified, and that the [subgrid](#subgrid)’s [gutters](https://www.w3.org/TR/css-align-3/#gutter) will visually center-align with the [parent grid](#parent-grid)’s gutters.
  
  [](#example-4627a772)
  
  For example, suppose we have a 300px-wide outer grid with 50px gaps and its columns specified as 100px 1fr. A subgrid spanning both tracks would have…
  
  … if its [column-gap](https://www.w3.org/TR/css-align-3/#propdef-column-gap) were [normal](https://www.w3.org/TR/css-align-3/#valdef-row-gap-normal) (or 50px):
  
  - A grid item in its left column sized and laid out (and contributing its size to the parent grid’s sizing calculations) without any special adjustment, thus stretching to 100px wide while remaining aligned to the subgrid’s left edge.
  - A grid item in its right column sized and laid out (and contributing its size to the parent grid’s sizing calculations) without any special adjustment, thus stretching to 150px wide, while remaining aligned to the subgrid’s right edge.
  - An effective visual [gutter](https://www.w3.org/TR/css-align-3/#gutter) between the items of 50px, exactly matching its parent grid.
  
  ![](images/subgrid-gap-normal.png)
  
  … if its [column-gap](https://www.w3.org/TR/css-align-3/#propdef-column-gap) were 0:
  
  - A grid item in its left column sized and laid out (and contributing its size to the parent grid’s sizing calculations) as if it had a -25px right margin, thus stretching to 125px wide while remaining aligned to the subgrid’s left edge.
  - A grid item in its right column sized and laid out (and contributing its size to the parent grid’s sizing calculations) as if it had a -25px left margin, thus stretching to 175px wide, while remaining aligned to the subgrid’s right edge.
  - An effective visual [gutter](https://www.w3.org/TR/css-align-3/#gutter) between the items of zero, as specified by its [column-gap](https://www.w3.org/TR/css-align-3/#propdef-column-gap).
  
  ![](images/subgrid-gap-0px.png)
  
  … if its [column-gap](https://www.w3.org/TR/css-align-3/#propdef-column-gap) were 25px:
  
  - A grid item in its left column sized and laid out (and contributing its size to the parent grid’s sizing calculations) as if it had a -12.5px right margin, thus stretching to 112.5px wide while remaining aligned to the subgrid’s left edge.
  - A grid item in its right column sized and laid out (and contributing its size to the parent grid’s sizing calculations) as if it had a -12.5px left margin, thus stretching to 162.5px wide, while remaining aligned to the subgrid’s right edge.
  - An effective visual [gutter](https://www.w3.org/TR/css-align-3/#gutter) between the items of 25px, as specified by its [column-gap](https://www.w3.org/TR/css-align-3/#propdef-column-gap).
  
  ![](images/subgrid-gap-25px.png)
  
  … if its [column-gap](https://www.w3.org/TR/css-align-3/#propdef-column-gap) were 75px:
  
  - A grid item in its left column sized and laid out (and contributing its size to the parent grid’s sizing calculations) as if it had a 12.5px right margin, thus stretching to 87.5px wide while remaining aligned to the subgrid’s left edge.
  - A grid item in its right column sized and laid out (and contributing its size to the parent grid’s sizing calculations) as if it had a 12.5px left margin, thus stretching to 137.5px wide, while remaining aligned to the subgrid’s right edge.
  - An effective visual [gutter](https://www.w3.org/TR/css-align-3/#gutter) between the items of 75px, as specified by its [column-gap](https://www.w3.org/TR/css-align-3/#propdef-column-gap).
  
  ![](images/subgrid-gap-75px.png)
- [](#subgrid-edge-placeholders)For each edge of a non-empty [subgrid](#subgrid), to account for the subgrid’s margin/border/padding (and any scrollbar gutter) at that edge, a hypothetical item is contributed to the track sizing algorithm for each span size in the set of items spanning into the occupied track closest to that edge of the subgrid. The hypothetical item’s sizes are taken from the sizes of the largest such item of each span size, and are additionally inflated by the subgrid’s own margin/border/padding/gutter at that edge. Correspondingly, the hypothetical item’s span is taken from that same real item’s span, and inflated by the number of empty tracks between it and the relevant subgrid’s edge(s).
  
  Note: This step can be shortcut if the tracks closest to the [subgrid](#subgrid)’s edges contain real items, which would have already [accounted for the subgrid’s margin/border/padding](#subgrid-item-contribution) as described above.
  
  [](#example-97fd1d9b)For example, in the following subgrid layout:
  
  ```
  5px auto auto 5px
  .   aaaaaaaaa .
  .   bbbb cccc .
  ```
  
  Assuming subgrid items `a`, `b`, and `c` occupying their corresponding grid areas and a subgrid padding of 25px, two hypothetical grid items would be contributed to the track sizing algorithm for the purpose of handling the subgrid’s inline-start padding: one with the size of `b` plus 25px, spanning the first two columns; and one with the size of `a` plus 25px, spanning the first three columns.
- [](#subgrid-box-alignment)The [subgrid](#subgrid) is always stretched in its [subgridded](#subgridded-axis) dimension(s): the [align-self](https://www.w3.org/TR/css-align-3/#propdef-align-self)/[justify-self](https://www.w3.org/TR/css-align-3/#propdef-justify-self) properties on it are ignored, as are any specified width/height constraints.
- [](#subgrid-grid-alignment)Layoutwise, the [subgrid](#subgrid)’s [grid](#grid) is always aligned with the corresponding section of the parent grid; the [align-content](https://www.w3.org/TR/css-align-3/#propdef-align-content)/[justify-content](https://www.w3.org/TR/css-align-3/#propdef-justify-content) properties on it are also ignored in the [subgridded](#subgridded-axis) dimension.
- [](#subgrid-overflow)The [overflow](https://www.w3.org/TR/css-overflow-3/#propdef-overflow) property does apply to [subgrids](#subgrid), so that overflowing contents of the subgrid can be scrolled into view. (Note: the act of scrolling does not affect layout.)
- [](#subgrid-relpos)[Relative positioning](https://www.w3.org/TR/CSS2/visuren.html#x34) applies to [subgrids](#subgrid) as normal, and shifts the box and its content together as usual. (Note: Relative positioning takes place after alignment, and does not affect track sizing.)

## 10. Absolute Positioning[](#abspos)

### 10.1. With a Grid Container as Containing Block[](#abspos-items)

If an absolutely positioned element’s [containing block](https://www.w3.org/TR/css-display-4/#containing-block) is generated by a [grid container](#grid-container), the containing block corresponds to the [grid area](#grid-area) determined by its [grid-placement properties](#grid-placement-property). The offset properties ([top](https://www.w3.org/TR/css-position-3/#propdef-top)/[right](https://www.w3.org/TR/css-position-3/#propdef-right)/[bottom](https://www.w3.org/TR/css-position-3/#propdef-bottom)/[left](https://www.w3.org/TR/css-position-3/#propdef-left)) then indicate offsets inwards from the corresponding edges of this containing block, as normal.

Note: While absolutely-positioning an element to a [grid container](#grid-container) does allow it to align to that container’s [grid lines](#grid-line), such elements do not take up space or otherwise participate in the layout of the grid.

[](#example-8b8bc36e)

```
.grid {
  grid: 1fr 1fr 1fr 1fr / 10rem 10rem 10rem 10rem;
  /* 4 equal-height rows filling the grid container,
     4 columns of ''10rem'' each */
  justify-content: center;
  /* center the grid horizontally within the grid container */
  position: relative;
  /* Establish abspos containing block */
}

.abspos {
  grid-row-start: 1;     /* 1st grid row line = top of grid container */
  grid-row-end: span 2;  /* 3rd grid row line */
  grid-column-start: 3;  /* 3rd grid col line */
  grid-column-end: auto; /* right padding edge */
  /* Containing block covers the top right quadrant of the grid container */

  position: absolute;
  top: 70px;
  bottom: 40px;
  left: 100px;
  right: 30px;
}
```

![](images/abspos-grid.svg)

Note: Grids and the [grid-placement properties](#grid-placement-property) are [flow-relative](https://www.w3.org/TR/css-writing-modes-4/#flow-relative), while the offset properties ([left](https://www.w3.org/TR/css-position-3/#propdef-left), [right](https://www.w3.org/TR/css-position-3/#propdef-right), [top](https://www.w3.org/TR/css-position-3/#propdef-top), and [bottom](https://www.w3.org/TR/css-position-3/#propdef-bottom)) are [physical](https://www.w3.org/TR/css-writing-modes-4/#physical), so if the [direction](https://www.w3.org/TR/css-writing-modes-3/#propdef-direction) or [writing-mode](https://www.w3.org/TR/css-writing-modes-4/#propdef-writing-mode) properties change, the grid will transform to match, but the offsets won’t.

Instead of auto-placement, an [auto](#grid-placement-auto) value for a [grid-placement property](#grid-placement-property) contributes a special line to the [placement](#grid-placement) whose position is that of the corresponding padding edge of the [grid container](#grid-container) (the padding edge of the scrollable area, if the grid container overflows). These lines become the first and last lines (0th and -0th) of the augmented grid used for positioning absolutely-positioned items.

Note: Thus, by default, the absolutely-positioned box’s [containing block](https://www.w3.org/TR/css-display-4/#containing-block) will correspond to the padding edges of the [grid container](#grid-container), as it does for [block containers](https://www.w3.org/TR/css-display-4/#block-container).

Absolute positioning occurs after layout of the [grid](#grid) and its [in-flow](https://www.w3.org/TR/css-display-4/#in-flow) contents, and does not contribute to the sizing of any grid tracks or affect the size/configuration of the grid in any way. If a [grid-placement property](#grid-placement-property) refers to a non-existent line either by explicitly specifying such a line or by spanning outside of the existing [implicit grid](#implicit-grid), it is instead treated as specifying [auto](#grid-placement-auto) (instead of creating new [implicit grid lines](#implicit-grid-lines)).

Note: Remember that implicit lines are assumed to have all line names, so a referenced line might exist even though it is not explicitly named.

If the [placement](#grid-placement) only contains a [grid span](#grid-span), replace it with the two [auto](#grid-placement-auto) lines in that axis. (This happens when both [grid-placement properties](#grid-placement-property) in an axis contributed a span originally, and [§ 8.3.1 Grid Placement Conflict Handling](#grid-placement-errors) caused the second span to be ignored.)

### 10.2. With a Grid Container as Parent[](#static-position)

An absolutely-positioned child of a [grid container](#grid-container) is [out-of-flow](https://www.w3.org/TR/css-display-4/#out-of-flow) and not a [grid item](#grid-item), and so does not affect the placement of other items or the sizing of the grid.

The [static position](https://www.w3.org/TR/CSS2/visudet.html#abs-non-replaced-width) [\[CSS2\]](#biblio-css2 "Cascading Style Sheets Level 2 Revision 1 (CSS 2.1) Specification") of an absolutely-positioned child of a [grid container](#grid-container) is determined as if it were the sole grid item in a [grid area](#grid-area) whose edges coincide with the content edges of the grid container.

Note: Note that this position is affected by the values of [justify-self](https://www.w3.org/TR/css-align-3/#propdef-justify-self) and [align-self](https://www.w3.org/TR/css-align-3/#propdef-align-self) on the child, and that, as in most other layout models, the absolutely-positioned child has no effect on the size of the containing block or layout of its contents.

## 11. Alignment and Spacing[](#alignment)

After a [grid container](#grid-container)’s [grid tracks](#grid-track) have been sized, and the dimensions of all [grid items](#grid-item) are finalized, grid items can be aligned within their [grid areas](#grid-area).

Note: The [grid items](#grid-item) of [subgrids](#subgrid) participate in alignment, including [baseline alignment](https://www.w3.org/TR/css-align-3/#baseline-alignment), together with their [parent grid](#parent-grid)’s items; see [Subgrids (h)](#subgrid-item-contribution).

The [margin](https://www.w3.org/TR/CSS2/box.html#propdef-margin) properties can be used to align items in a manner similar to what margins can do in block layout. [Grid items](#grid-item) also respect the [box alignment properties](https://www.w3.org/TR/css-align-3/#box-alignment-properties) from the [CSS Box Alignment Module](https://www.w3.org/TR/css-align/) [\[CSS-ALIGN-3\]](#biblio-css-align-3 "CSS Box Alignment Module Level 3"), which allow easy keyword-based alignment of items in both the rows and columns.

By default, [grid items](#grid-item) stretch to fill their [grid area](#grid-area). However, if [justify-self](https://www.w3.org/TR/css-align-3/#propdef-justify-self) or [align-self](https://www.w3.org/TR/css-align-3/#propdef-align-self) compute to a value other than [stretch](https://www.w3.org/TR/css-align-3/#valdef-justify-self-stretch) or margins are [auto](), grid items will auto-size to fit their contents.

### 11.1. Gutters: the [row-gap](https://www.w3.org/TR/css-align-3/#propdef-row-gap), [column-gap](https://www.w3.org/TR/css-align-3/#propdef-column-gap), and [gap](https://www.w3.org/TR/css-align-3/#propdef-gap) properties[](#gutters)

The [row-gap](https://www.w3.org/TR/css-align-3/#propdef-row-gap) and [column-gap](https://www.w3.org/TR/css-align-3/#propdef-column-gap) properties (and their [gap](https://www.w3.org/TR/css-align-3/#propdef-gap) shorthand), when specified on a [grid container](#grid-container), define the [gutters](https://www.w3.org/TR/css-align-3/#gutter) between [grid rows](#grid-row) and [grid columns](#grid-column). Their syntax is defined in [CSS Box Alignment 3 § 8 Gaps Between Boxes](https://www.w3.org/TR/css-align-3/#gaps).

The effect of these properties is as though the affected [grid lines](#grid-line) acquired thickness: the [grid track](#grid-track) between two grid lines is the space between the [gutters](https://www.w3.org/TR/css-align-3/#gutter) that represent them. For the purpose of [track sizing](#algo-track-sizing), each gutter is treated as an extra, empty, fixed-size track of the specified size, which is spanned by any [grid items](#grid-item) that span across its corresponding grid line.

Note: Additional spacing may be added between tracks due to [justify-content](https://www.w3.org/TR/css-align-3/#propdef-justify-content)/[align-content](https://www.w3.org/TR/css-align-3/#propdef-align-content). See [§ 12.1 Grid Sizing Algorithm](#algo-grid-sizing). This space effectively increases the size of the [gutters](https://www.w3.org/TR/css-align-3/#gutter).

If a [grid](#grid) is [fragmented](https://www.w3.org/TR/css-break-3/#fragment) between tracks, the [gutter](https://www.w3.org/TR/css-align-3/#gutter) spacing between those tracks must be suppressed. Note that gutters are suppressed even after forced breaks, [unlike margins](https://www.w3.org/TR/css-break-3/#break-margins).

[Gutters](https://www.w3.org/TR/css-align-3/#gutter) only appear *between* tracks of the [implicit grid](#implicit-grid); there is no gutter before the first track or after the last track. (In particular, there is no gutter between the first/last track of the implicit grid and the “auto” lines in the [augmented grid](#augmented-grid).)

When a [collapsed track](#collapsed-grid-track)’s gutters collapse, they coincide exactly—​the two gutters overlap so that their start and end edges coincide. If one side of a collapsed track does not have a gutter (e.g. if it is the first or last track of the [implicit grid](#implicit-grid)), then collapsing its gutters results in no gutter on either “side” of the collapsed track.

### 11.2. Aligning with [auto]() margins[](#auto-margins)

Auto [margins](https://www.w3.org/TR/css-box-4/#margin) on [grid items](#grid-item) have an effect very similar to auto margins in [block layout](https://www.w3.org/TR/css-display-4/#block-layout):

- During calculations of [grid track](#grid-track) sizes, auto margins are treated as 0.
- As defined for the [inline axis](https://www.w3.org/TR/css-writing-modes-4/#inline-axis) of [block layout](https://www.w3.org/TR/css-display-4/#block-layout) (see [CSS2§10.3.3](https://www.w3.org/TR/CSS2/visudet.html#blockwidth)), auto margins in either axis absorb positive free space prior to alignment via the [box alignment properties](https://www.w3.org/TR/css-align-3/#box-alignment-properties), thereby disabling the effects of any [self-alignment properties](https://www.w3.org/TR/css-align-3/#self-alignment-properties) in that axis.
- Overflowing [grid items](#grid-item) resolve their auto margins to zero and overflow as specified by their [box alignment properties](https://www.w3.org/TR/css-align-3/#box-alignment-properties).

### 11.3. Inline-axis Alignment: the [justify-self](https://www.w3.org/TR/css-align-3/#propdef-justify-self) and [justify-items](https://www.w3.org/TR/css-align-3/#propdef-justify-items) properties[](#row-align)

[Grid items](#grid-item) can be aligned in the inline dimension by using the [justify-self](https://www.w3.org/TR/css-align-3/#propdef-justify-self) property on the grid item or [justify-items](https://www.w3.org/TR/css-align-3/#propdef-justify-items) property on the [grid container](#grid-container), as defined in [\[CSS-ALIGN-3\]](#biblio-css-align-3 "CSS Box Alignment Module Level 3").

[](#example-e0479e1b)For example, for an English document, the inline axis is horizontal, and so the justify-* properties align the [grid items](#grid-item) horizontally.

If [baseline alignment](https://www.w3.org/TR/css-align-3/#baseline-alignment) is specified on a [grid item](#grid-item) whose size in that axis depends on the size of an intrinsically-sized track (whose size is therefore dependent on both the item’s size and baseline alignment, creating a cyclic dependency), that item does not participate in baseline alignment, and instead uses its [fallback alignment](https://www.w3.org/TR/css-align-3/#fallback-alignment) as if that were originally specified. For this purpose, [&lt;flex&gt;](#typedef-flex) track sizes count as “intrinsically-sized” when the [grid container](#grid-container) has an [indefinite](https://www.w3.org/TR/css-sizing-3/#indefinite) size in the relevant axis.

Note: Whether the fallback alignment is used or not does not change over the course of layout: if a cycle exists, it exists.

### 11.4. Block-axis Alignment: the [align-self](https://www.w3.org/TR/css-align-3/#propdef-align-self) and [align-items](https://www.w3.org/TR/css-align-3/#propdef-align-items) properties[](#column-align)

[Grid items](#grid-item) can also be aligned in the block dimension (perpendicular to the inline dimension) by using the [align-self](https://www.w3.org/TR/css-align-3/#propdef-align-self) property on the grid item or [align-items](https://www.w3.org/TR/css-align-3/#propdef-align-items) property on the [grid container](#grid-container), as defined in [\[CSS-ALIGN-3\]](#biblio-css-align-3 "CSS Box Alignment Module Level 3").

If [baseline alignment](https://www.w3.org/TR/css-align-3/#baseline-alignment) is specified on a [grid item](#grid-item) whose size in that axis depends on the size of an intrinsically-sized track (whose size is therefore dependent on both the item’s size and baseline alignment, creating a cyclic dependency), that item does not participate in baseline alignment, and instead uses its [fallback alignment](https://www.w3.org/TR/css-align-3/#fallback-alignment) as if that were originally specified. For this purpose, [&lt;flex&gt;](#typedef-flex) track sizes count as “intrinsically-sized” when the [grid container](#grid-container) has an [indefinite](https://www.w3.org/TR/css-sizing-3/#indefinite) size in the relevant axis.

### 11.5. Aligning the Grid: the [justify-content](https://www.w3.org/TR/css-align-3/#propdef-justify-content) and [align-content](https://www.w3.org/TR/css-align-3/#propdef-align-content) properties[](#grid-align)

If the [grid](#grid)’s outer edges do not correspond to the [grid container](#grid-container)’s content edges (for example, if no columns are flex-sized), the [grid tracks](#grid-track) are aligned within the content box according to the [justify-content](https://www.w3.org/TR/css-align-3/#propdef-justify-content) and [align-content](https://www.w3.org/TR/css-align-3/#propdef-align-content) properties on the grid container.

[](#example-2790843a)For example, the following grid is centered vertically, and aligned to the right edge of its [grid container](#grid-container):

```
.grid {
  display: grid;
  grid: 12rem 12rem 12rem 12rem / 10rem 10rem 10rem 10rem;
  justify-content: end;
  align-content: center;
  min-height: 60rem;
}
```

![](images/align-justify-content.svg)

If there are no [grid tracks](#grid-track) (the [explicit grid](#explicit-grid) is empty, and no tracks were created in the [implicit grid](#implicit-grid)), the sole [grid line](#grid-line) in each axis is aligned with the start edge of the [grid container](#grid-container).

Note that certain values of [justify-content](https://www.w3.org/TR/css-align-3/#propdef-justify-content) and [align-content](https://www.w3.org/TR/css-align-3/#propdef-align-content) can cause the tracks to be spaced apart ([space-around](https://www.w3.org/TR/css-align-3/#valdef-align-content-space-around), [space-between](https://www.w3.org/TR/css-align-3/#valdef-align-content-space-between), [space-evenly](https://www.w3.org/TR/css-align-3/#valdef-align-content-space-evenly)) or to be resized ([stretch](https://www.w3.org/TR/css-align-3/#valdef-align-content-stretch)). If the [grid](#grid) is [fragmented](https://www.w3.org/TR/css-break-3/#fragment) between tracks, any such additional spacing between those tracks must be suppressed.

[](#example-aafda37f)For example, in the following grid, the spanning item’s grid area is increased to accommodate the extra space assigned to the gutters due to alignment:

```
.wrapper {
  display: grid;
  /* 3-row / 4-column grid container */
  grid: repeat(3, auto) / repeat(4, auto);
  gap: 10px;
  align-content: space-around;
  justify-content: space-between;
}

.item1 { grid-column: 1 / 5; }
.item2 { grid-column: 1 / 3; grid-row: 2 / 4; }
.item3 { grid-column: 3 / 5; }
/* last two items auto-place into the last two grid cells */
```

![Grid with 10px gap and an element spanning all columns. 			          The sum of the columns is less than the width of the grid container.](images/spanned-gap.svg)

Grid before alignment

![Same grid with increased gaps absorbing the excess grid container width. 			          The spanning element has grown to accommodate the extra space assigned to the gap it crosses.](images/spanned-gap-align.svg)

Grid after alignment

Note that alignment (unlike [gap](https://www.w3.org/TR/css-align-3/#propdef-gap) spacing) happens after the grid tracks are sized, so if the track sizes are determined by the contents of the spanned item, it will gain excess space in the alignment stage to accommodate the alignment spacing.

### 11.6. Grid Container Baselines[](#grid-baselines)

The first (last) baselines of a [grid container](#grid-container) are determined as follows:

1. Find the first (last) row of the [grid container](#grid-container) containing at least one [grid item](#grid-item).
   
   If any of the [grid items](#grid-item) intersecting this row participate in [baseline alignment](https://www.w3.org/TR/css-align-3/#baseline-alignment) in that row, the grid container’s [baseline set](https://www.w3.org/TR/css-align-3/#baseline-set) is [generated](https://www.w3.org/TR/css-align-3/#generate-baselines) from the shared [alignment baseline](https://www.w3.org/TR/css-align-3/#alignment-baseline) of those grid items.
   
   Otherwise, the grid container’s first (last) baseline set is [generated](https://www.w3.org/TR/css-align-3/#generate-baselines) from the [alignment baseline](https://www.w3.org/TR/css-align-3/#alignment-baseline) of the first (last) [grid item](#grid-item) in row-major [grid order](#grid-order) (according to the [writing mode](https://www.w3.org/TR/css-writing-modes-4/#writing-mode) of the [grid container](#grid-container)). If the grid item has no alignment baseline in the grid’s inline axis, then one is first [synthesized](https://www.w3.org/TR/css-align-3/#synthesize-baseline) from its border edges.
2. If the [grid container](#grid-container) does not contain any [grid items](#grid-item), the grid container has no first (last) [baseline set](https://www.w3.org/TR/css-align-3/#baseline-set), and one is [synthesized](https://www.w3.org/TR/css-align-3/#synthesize-baseline) if needed according to the rules of its [alignment context](https://www.w3.org/TR/css-align-3/#shared-alignment-context). Exit from this algorithm.

Grid-modified document order (grid order) is the order in which [grid items](#grid-item) are encountered when traversing the grid’s [grid cells](#grid-cell). If two items are encountered at the same time, they are taken in [order-modified document order](https://www.w3.org/TR/css-flexbox-1/#order-modified-document-order).

When calculating the baseline according to the above rules, if the box contributing a baseline has an [overflow](https://www.w3.org/TR/css-overflow-3/#propdef-overflow) value that allows scrolling, the box must be treated as being in its initial scroll position for the purpose of determining its baseline.

When [determining the baseline of a table cell](https://www.w3.org/TR/CSS2/tables.html#height-layout), a grid container provides a baseline just as a line box or table-row does. [\[CSS2\]](#biblio-css2 "Cascading Style Sheets Level 2 Revision 1 (CSS 2.1) Specification")

See [CSS Writing Modes 3 § 4.1 Introduction to Baselines](https://www.w3.org/TR/css-writing-modes-3/#intro-baselines) and [CSS Box Alignment 3 § 9 Baseline Alignment Details](https://www.w3.org/TR/css-align-3/#baseline-rules) for more information on baselines.

## 12. Grid Layout Algorithm[](#layout-algorithm)

This section defines the **grid layout algorithm**, which sizes the [grid container](#grid-container), sizes and positions all the [grid tracks](#grid-track), and lays out the [grid items](#grid-item) which have been [placed](#grid-item-placement-algorithm) into its [grid areas](#grid-area).

1. Run the [Grid Item Placement Algorithm](#grid-item-placement-algorithm) to resolve the placement of all [grid items](#grid-item) (including [subgrids](#subgrid) and their sub-items) in the [grid](#grid).
2. Find the size of the [grid container](#grid-container), per [§ 5.2 Sizing Grid Containers](#intrinsic-sizes).
   
   Note: During this phase, cyclic [&lt;percentage&gt;](https://www.w3.org/TR/css-values-4/#percentage-value)s in track sizes are treated as [auto](#valdef-grid-template-columns-auto).
3. Given the resulting [grid container](#grid-container) size, run the [Grid Sizing Algorithm](#algo-grid-sizing) to size the [grid](#grid).
   
   Note: During this phase, [&lt;percentage&gt;](https://www.w3.org/TR/css-values-4/#percentage-value)s in track sizes are resolved against the [grid container](#grid-container) size.
4. Lay out the [grid items](#grid-item) into their respective containing blocks. Each [grid area’s](#grid-area) width and height are considered [definite](https://www.w3.org/TR/css-sizing-3/#definite) for this purpose.
   
   Note: Since formulas calculated using only definite sizes, such as the [stretch fit](https://www.w3.org/TR/css-sizing-3/#stretch-fit) formula, are also definite, the size of a grid item which is stretched is also considered definite.

### 12.1. Grid Sizing Algorithm[](#algo-grid-sizing)

This section defines the **grid sizing algorithm**, which determines the size of all [grid tracks](#grid-track) and, by extension, the entire grid.

Each track has specified [minimum](#min-track-sizing-function) and [maximum](#max-track-sizing-function) [sizing functions](#grid-template-rows-track-sizing-function) (which may be the same). Each sizing function is either:

- A fixed sizing function ([&lt;length&gt;](https://www.w3.org/TR/css-values-4/#length-value) or resolvable [&lt;percentage&gt;](https://www.w3.org/TR/css-values-4/#percentage-value)).
- An intrinsic sizing function ([min-content](#valdef-grid-template-columns-min-content), [max-content](#valdef-grid-template-columns-max-content), [auto](#valdef-grid-template-columns-auto), [fit-content()](#funcdef-grid-template-columns-fit-content)).
- A flexible sizing function ([&lt;flex&gt;](#typedef-flex)).

The [grid sizing algorithm](#algo-grid-sizing) defines how to resolve these sizing constraints into used track sizes.

1. First, the [track sizing algorithm](#track-sizing-algorithm) is used to resolve the sizes of the [grid columns](#grid-column).
   
   In this process, any [grid item](#grid-item) which is subgridded in the [grid container](#grid-container)’s [inline axis](https://www.w3.org/TR/css-writing-modes-4/#inline-axis) is treated as empty and its grid items (the grandchildren) are treated as direct children of the grid container (their grandparent). This introspection is recursive.
   
   Items which are subgridded only in the [block axis](https://www.w3.org/TR/css-writing-modes-4/#block-axis), and whose [grid container](#grid-container) size in the [inline axis](https://www.w3.org/TR/css-writing-modes-4/#inline-axis) depends on the size of its contents are also introspected: since the size of the item in this dimension can be dependent on the sizing of its subgridded tracks in the other, the size contribution of any such item to this grid’s column sizing (see [Resolve Intrinsic Track Sizes](https://www.w3.org/TR/css-grid-1/#algo-content)) is taken under the provision of having determined its track sizing only up to the same point in the Grid Sizing Algorithm as this itself. E.g. for the first pass through this step, the item will have its tracks sized only through this first step; if a second pass of this step is triggered then the item will have completed a first pass through steps 1-3 as well as the second pass of this step prior to returning its size for consideration in this grid’s column sizing. Again, this introspection is recursive.
   
   If calculating the layout of a [grid item](#grid-item) in this step depends on the [available space](https://www.w3.org/TR/css-sizing-3/#available) in the [block axis](https://www.w3.org/TR/css-writing-modes-4/#block-axis), assume the available space that it would have if any row with a [definite](https://www.w3.org/TR/css-sizing-3/#definite) [max track sizing function](#max-track-sizing-function) had that size and all other rows were infinite. If both the [grid container](#grid-container) and all tracks have definite sizes, also apply [align-content](https://www.w3.org/TR/css-align-3/#propdef-align-content) to find the final effective size of any gaps spanned by such items; otherwise ignore the effects of track alignment in this estimation.
2. Next, the [track sizing algorithm](#track-sizing-algorithm) resolves the sizes of the [grid rows](#grid-row).
   
   In this process, any [grid item](#grid-item) which is subgridded in the [grid container](#grid-container)’s [block axis](https://www.w3.org/TR/css-writing-modes-4/#block-axis) is treated as empty and its grid items (the grandchildren) are treated as direct children of the grid container (their grandparent). This introspection is recursive.
   
   As with sizing columns, items which are subgridded only in the [inline axis](https://www.w3.org/TR/css-writing-modes-4/#inline-axis), and whose [grid container](#grid-container) size in the [block axis](https://www.w3.org/TR/css-writing-modes-4/#block-axis) depends on the size of its contents are also introspected. (As with sizing columns, the size contribution to this grid’s row sizing is taken under the provision of having determined its track sizing only up to this corresponding point in the algorithm; and again, this introspection is recursive.)
   
   To find the [inline-axis](https://www.w3.org/TR/css-writing-modes-4/#inline-axis) [available space](https://www.w3.org/TR/css-sizing-3/#available) for any items whose [block-axis](https://www.w3.org/TR/css-writing-modes-4/#block-axis) size contributions require it, use the [grid column](#grid-column) sizes calculated in the previous step. If the [grid container](#grid-container)’s [inline size](https://www.w3.org/TR/css-writing-modes-4/#inline-size) is [definite](https://www.w3.org/TR/css-sizing-3/#definite), also apply [justify-content](https://www.w3.org/TR/css-align-3/#propdef-justify-content) to account for the effective column gap sizes.
3. Then, if the [min-content contribution](https://www.w3.org/TR/css-sizing-3/#min-content-contribution) of any grid item has changed based on the row sizes and alignment calculated in step 2, re-resolve the sizes of the [grid columns](#grid-column) with the new min-content and [max-content contributions](https://www.w3.org/TR/css-sizing-3/#max-content-contribution) (once only).
   
   To find the [block-axis](https://www.w3.org/TR/css-writing-modes-4/#block-axis) [available space](https://www.w3.org/TR/css-sizing-3/#available) for any items whose [inline-axis](https://www.w3.org/TR/css-writing-modes-4/#inline-axis) size contributions require it, use the [grid row](#grid-row) sizes calculated in the previous step. If the [grid container](#grid-container)’s [block size](https://www.w3.org/TR/css-writing-modes-4/#block-size) is [definite](https://www.w3.org/TR/css-sizing-3/#definite), also apply [align-content](https://www.w3.org/TR/css-align-3/#propdef-align-content) to account for the effective row gap sizes.
   
   This repetition is necessary for cases where the [inline size](https://www.w3.org/TR/css-writing-modes-4/#inline-size) of a [grid item](#grid-item) depends on the [block size](https://www.w3.org/TR/css-writing-modes-4/#block-size) of its [grid area](#grid-area). Examples include wrapped column [flex containers](https://www.w3.org/TR/css-flexbox-1/#flex-container) ([flex-flow: column wrap](https://www.w3.org/TR/css-flexbox-1/#propdef-flex-flow)), [orthogonal flows](https://www.w3.org/TR/css-writing-modes-4/#establish-an-orthogonal-flow) ([writing-mode](https://www.w3.org/TR/css-writing-modes-4/#propdef-writing-mode)), [multi-column containers](https://www.w3.org/TR/css-multicol-2/#multi-column-container), and items with an aspect-ratio (or with a child with an aspect ratio) whose size depends on the size of the row.
4. Next, if the [min-content contribution](https://www.w3.org/TR/css-sizing-3/#min-content-contribution) of any grid item has changed based on the column sizes and alignment calculated in step 3, re-resolve the sizes of the [grid rows](#grid-row) with the new min-content and [max-content contributions](https://www.w3.org/TR/css-sizing-3/#max-content-contribution) (once only).
   
   To find the [inline-axis](https://www.w3.org/TR/css-writing-modes-4/#inline-axis) [available space](https://www.w3.org/TR/css-sizing-3/#available) for any items whose [block-axis](https://www.w3.org/TR/css-writing-modes-4/#block-axis) size contributions require it, use the [grid column](#grid-column) sizes calculated in the previous step. If the [grid container](#grid-container)’s [inline size](https://www.w3.org/TR/css-writing-modes-4/#inline-size) is [definite](https://www.w3.org/TR/css-sizing-3/#definite), also apply [justify-content](https://www.w3.org/TR/css-align-3/#propdef-justify-content) to account for the effective column gap sizes.
5. Finally, align the tracks within the [grid container](#grid-container) according to the [align-content](https://www.w3.org/TR/css-align-3/#propdef-align-content) and [justify-content](https://www.w3.org/TR/css-align-3/#propdef-justify-content) properties.
   
   Note: This can introduce extra space between tracks, potentially enlarging the grid area of any grid items spanning the gaps beyond the space allotted to during track sizing.

Note: Track sizing in a [subgridded](#subgridded-axis) dimension treats each item in a given track in that axis as members of the [parent grid](#parent-grid). This interlacing requires that grid sizing drill down per axis into [subgrids](#subgrid), rather than completing both axes as it recurses. Note this means that a subgrid establishing an [orthogonal flow](https://www.w3.org/TR/css-writing-modes-4/#establish-an-orthogonal-flow) would have the order of its track sizing inverted compared to a nested grid.

[](#example-da309425)The following example illustrates how per-axis subgrids are sized:

Suppose we have a parent grid container `A` which contains an item `B` that has subgridded columns and contains a grandchild `B` that has subgridded rows and grandchild `D` that is simply a nested grid.

```
<grid-A>
  <grid-B subgrid=columns>
    <grid-C subgrid=rows></grid-C>
    <grid-D></grid-D>
  </grid-B>
<grid-A>
```

When `A` sizes its columns it treats `B`’s items as slotted into to `A`’s corresponding columns, but when `A` sizes its rows it treats `B` as a single item (a grid container with its own rows and some items including items `C` and `D`). Similarly when `B` sizes its rows, it treats `C`’s items as slotted into `B`’s rows, but when `B` sizes its columns, it treats `C` as a single item, just as it does with `D`. There is no relationship between `C`’s rows and `A`’s rows, because the rows in `B` are nested, not subgridded.

At a high level, the grid algorithm is:

1. Size the columns
2. Size the rows
3. Adjust the columns (if needed based on final row sizes)

The grid sizing algorithm in this example would thus look like this:

1. **Resolve sizes of `A`’s grid columns, using the sizes of `A`’s grid items, treating `B` as empty but treating its children (including `C` and `D`) as items in grid `A`.**
   
   The grid algorithm simply recurses into `D`. For `C`, it’s more complicated:
   
   1. Size `C`’s columns.
   2. Size `C`’s rows by sizing `B`’s rows.
   3. Adjust `C`’s columns.
   4. Return `C`’s final column sizes.
   
   A correct size for `B`’s rows requires `C`’s final column sizes, because the row size depends on the column size, and thus `B`’s rows could very well depend on `C`’s final column sizes. To break this cyclic dependency, we need to split the algorithm to depend on the initial approximation of `C`’s final column sizes, and do the adjustment pass later. So for `C`, we need to recurse into column sizing only, and pass that initial size up to `A` for its initial column sizing.
   
   When we size `B`’s rows later on, we will size `C`’s rows (which are subgridded), and finish up `C`’s sizing by finalizing its columns. If this resulted in a change, we have the opportunity to trigger an adjustment pass for `A`’s columns during its adjustment pass.
2. **Next, resolve sizes of `A`’s rows, using the sizes of `A`’s grid items, treating `B` as a single item.**
   
   Since `B`, as a subgrid, has its sizing is split out into the multiple passes, the grid algorithm issues only a row-sizing recursion into `B`: Size `B`’s rows, treating D as a single item, requesting its final size, and treating `C` as an empty item and hoisting its children as items into grid `B`.
   
   `B` returns its final row size, which factors into `A`’s row sizing pass.
3. **Last, finalize `A`’s column sizes.** If `C`’s final size changes as a result of the row-sizing pass through `B`, this should trigger a resizing of `B`’s columns, which should trigger a resizing pass on `A`’s column.

### 12.2. Track Sizing Terminology[](#algo-terms)

min track sizing function

If the track was sized with a [minmax()](#funcdef-grid-template-columns-minmax) function, this is the first argument to that function. If the track was sized with a [&lt;flex&gt;](#typedef-flex) value or [fit-content()](#funcdef-grid-template-columns-fit-content) function, [auto](#valdef-grid-template-columns-auto). Otherwise, the track’s sizing function.

max track sizing function

If the track was sized with a [minmax()](#funcdef-grid-template-columns-minmax) function, this is the second argument to that function. Otherwise, the track’s sizing function. In all cases, treat [auto](#valdef-grid-template-columns-auto) and [fit-content()](#funcdef-grid-template-columns-fit-content) as [max-content](#valdef-grid-template-columns-max-content), except where specified otherwise for fit-content().

available grid space

Independently in each dimension, the [available grid space](#available-grid-space) is:

- If the [grid container’s](#grid-container) size is definite, then use the size of its content box.
- If the [grid container](#grid-container) is being sized under a [min-content constraint](https://www.w3.org/TR/css-sizing-3/#min-content-constraint) or [max-content constraint](https://www.w3.org/TR/css-sizing-3/#max-content-constraint) then the [available grid space](#available-grid-space) is that constraint (and is indefinite).

Note: [auto](#grid-placement-auto) sizes that indicate content-based sizing (e.g. the height of a block-level box in horizontal writing modes) are equivalent to [max-content](#valdef-grid-template-columns-max-content).

In all cases, clamp the [available grid space](#available-grid-space) according to the [grid container’s](#grid-container) min/max-width/height properties, if they are definite.

free space

Equal to the [available grid space](#available-grid-space) minus the sum of the [base sizes](#base-size) of all the grid tracks (including gutters), floored at zero. If available grid space is [indefinite](https://www.w3.org/TR/css-sizing-3/#indefinite), the [free space](#free-space) is indefinite as well.

span count

The number of [grid tracks](#grid-track) crossed by a [grid item](#grid-item) in the applicable dimension.

Note: Remember that [gutters](#gutters) are treated as fixed-size tracks—​tracks with their min and max sizing functions both set to the gutter’s used size—​for the purpose of the grid sizing algorithm. Their widths need to be incorporated into the [track sizing algorithm](#track-sizing-algorithm)’s calculations accordingly.

### 12.3. Track Sizing Algorithm[](#algo-track-sizing)

The remainder of this section is the track sizing algorithm, which calculates from the [min](#min-track-sizing-function) and [max track sizing functions](#max-track-sizing-function) the used track size. Each track has a base size, a [&lt;length&gt;](https://www.w3.org/TR/css-values-4/#length-value) which grows throughout the algorithm and which will eventually be the track’s final size, and a growth limit, a &lt;length&gt; which provides a desired maximum size for the [base size](#base-size). There are 5 steps:

1. [Initialize Track Sizes](#algo-init)
2. [Resolve Intrinsic Track Sizes](#algo-content)
3. [Maximize Tracks](#algo-grow-tracks)
4. [Expand Flexible Tracks](#algo-flex-tracks)
5. [Expand Stretched auto Tracks](#algo-stretch)

### 12.4. Initialize Track Sizes[](#algo-init)

**Initialize each track’s base size and growth limit.** For each track, if the track’s [min track sizing function](#min-track-sizing-function) is:

A [fixed sizing function](#fixed-sizing-function)

Resolve to an absolute length and use that size as the track’s initial [base size](#base-size).

Note: [Indefinite](https://www.w3.org/TR/css-sizing-3/#indefinite) lengths cannot occur, as they’re treated as [auto](#valdef-grid-template-columns-auto).

An [intrinsic sizing function](#intrinsic-sizing-function)

Use an initial [base size](#base-size) of zero.

For each track, if the track’s [max track sizing function](#max-track-sizing-function) is:

A [fixed sizing function](#fixed-sizing-function)

Resolve to an absolute length and use that size as the track’s initial [growth limit](#growth-limit).

An [intrinsic sizing function](#intrinsic-sizing-function)

A [flexible sizing function](#flexible-sizing-function)

Use an initial [growth limit](#growth-limit) of infinity.

In all cases, if the [growth limit](#growth-limit) is less than the [base size](#base-size), increase the growth limit to match the base size.

Note: [Gutters](https://www.w3.org/TR/css-align-3/#gutter) are treated as empty fixed-size tracks for the purpose of the [track sizing algorithm](#track-sizing-algorithm).

### 12.5. Resolve Intrinsic Track Sizes[](#algo-content)

This step resolves intrinsic track [sizing functions](#grid-template-rows-track-sizing-function) to absolute lengths. First it resolves those sizes based on items that are contained wholly within a single track. Then it gradually adds in the space requirements of items that span multiple tracks, evenly distributing the extra space across those tracks insofar as possible.

Note: When this step is complete, all intrinsic [base sizes](#base-size) and [growth limits](#growth-limit) will have been resolved to absolute lengths.

Note: [Remember that](#algo-terms) [fit-content()](#funcdef-grid-template-columns-fit-content) and [auto](#valdef-grid-template-columns-auto) [max track sizing functions](#max-track-sizing-function) are treated the same as [max-content](#valdef-grid-template-columns-max-content) except where explicitly specified otherwise.

1. [](#algo-baseline-shims)**Shim baseline-aligned items so their intrinsic size contributions reflect their baseline alignment.** For the items in each [baseline-sharing group](https://www.w3.org/TR/css-align-3/#baseline-sharing-group), add a “shim” (effectively, additional margin) on the start/end side (for first/last-baseline alignment) of each item so that, when start/end-aligned together their [baselines align as specified](https://www.w3.org/TR/css-align-3/#baseline-values).
   
   Consider these “shims” as part of the items’ intrinsic size contribution for the purpose of track sizing, below. If an item uses multiple intrinsic size contributions, it can have different shims for each one.
   
   [](#example-497433d9)For example, when the [grid container](#grid-container) has an [indefinite](https://www.w3.org/TR/css-sizing-3/#indefinite) size, it is first laid out under min/max-content constraints to find the size, then laid out "for real" with that size (which can affect things like percentage tracks). The "shims" added for each phase are independent, and only affect the layout during that phase.
   
   Note: Note that both [baseline self-aligned](https://www.w3.org/TR/css-align-3/#baseline-align-self) and [baseline content-aligned](https://www.w3.org/TR/css-align-3/#baseline-align-content) items are considered in this step.
   
   Note: Since [grid items](#grid-item) whose own size depends on the size of an intrinsically-sized track [do not participate in baseline alignment](#row-align), they are not shimmed.
2. [](#algo-single-span-items)**Size tracks to fit non-spanning items:** For each track with an intrinsic [track sizing function](#grid-template-rows-track-sizing-function) and not a [flexible sizing function](#flexible-sizing-function), consider the items in it with a span of 1:
   
   For min-content minimums:
   
   If the track has a [min-content](#valdef-grid-template-columns-min-content) [min track sizing function](#min-track-sizing-function), set its [base size](#base-size) to the maximum of the items’ [min-content contributions](https://www.w3.org/TR/css-sizing-3/#min-content-contribution), floored at zero.
   
   For max-content minimums:
   
   If the track has a [max-content](#valdef-grid-template-columns-max-content) [min track sizing function](#min-track-sizing-function), set its [base size](#base-size) to the maximum of the items’ [max-content contributions](https://www.w3.org/TR/css-sizing-3/#max-content-contribution), floored at zero.
   
   For auto minimums:
   
   If the track has an [auto](#grid-placement-auto) [min track sizing function](#min-track-sizing-function) and the [grid container](#grid-container) is being sized under a [min-](https://www.w3.org/TR/css-sizing-3/#min-content-constraint)/[max-content constraint](https://www.w3.org/TR/css-sizing-3/#max-content-constraint), set the track’s [base size](#base-size) to the maximum of its items’ [limited min-content contributions](#limited-contribution), floored at zero. The limited min-/max-content contribution of an item is (for this purpose) its [min-](https://www.w3.org/TR/css-sizing-3/#min-content-contribution)/[max-content contribution](https://www.w3.org/TR/css-sizing-3/#max-content-contribution) (accordingly), limited by the [max track sizing function](#max-track-sizing-function) (which could be the argument to a [fit-content()](#funcdef-grid-template-columns-fit-content) track sizing function) if that is [fixed](#fixed-sizing-function) and ultimately floored by its [minimum contribution](#minimum-contribution) (defined below).
   
   Otherwise, set the track’s [base size](#base-size) to the maximum of its items’ [minimum contributions](#minimum-contribution), floored at zero. The minimum contribution of an item is the smallest [outer size](https://www.w3.org/TR/css-sizing-3/#outer-size) it can have. Specifically, if the item’s computed [preferred size](https://www.w3.org/TR/css-sizing-3/#preferred-size) [behaves as auto](https://www.w3.org/TR/css-sizing-3/#behave-as-auto) or depends on the size of its [containing block](https://www.w3.org/TR/css-display-4/#containing-block) in the relevant axis, its minimum contribution is the outer size that would result from assuming the item’s used [minimum size](https://www.w3.org/TR/css-sizing-3/#min-width) as its preferred size; else the item’s minimum contribution is its [min-content contribution](https://www.w3.org/TR/css-sizing-3/#min-content-contribution). Because the minimum contribution often depends on the size of the item’s content, it is considered a type of [intrinsic size contribution](https://www.w3.org/TR/css-sizing-3/#intrinsic-size-contribution).
   
   Note: For items with a specified minimum size of [auto](https://www.w3.org/TR/css-sizing-3/#valdef-width-auto) (the initial value), the [minimum contribution](#minimum-contribution) is usually equivalent to the [min-content contribution](https://www.w3.org/TR/css-sizing-3/#min-content-contribution)—​but can differ in some cases, see [§ 6.6 Automatic Minimum Size of Grid Items](#min-size-auto). Also, minimum contribution ≤ min-content contribution ≤ [max-content contribution](https://www.w3.org/TR/css-sizing-3/#max-content-contribution).
   
   For min-content maximums:
   
   If the track has a [min-content](#valdef-grid-template-columns-min-content) [max track sizing function](#max-track-sizing-function), set its [growth limit](#growth-limit) to the maximum of the items’ [min-content contributions](https://www.w3.org/TR/css-sizing-3/#min-content-contribution).
   
   For max-content maximums:
   
   If the track has a [max-content](#valdef-grid-template-columns-max-content) [max track sizing function](#max-track-sizing-function), set its [growth limit](#growth-limit) to the maximum of the items’ [max-content contributions](https://www.w3.org/TR/css-sizing-3/#max-content-contribution). For [fit-content()](#funcdef-grid-template-columns-fit-content) maximums, furthermore clamp this growth limit by the fit-content() argument.
   
   In all cases, if a track’s [growth limit](#growth-limit) is now less than its [base size](#base-size), increase the growth limit to match the base size.
   
   Note: This step is a simplification of the steps below for handling spanning items, and should yield the same behavior as running those instructions on items with a span of 1.
3. [](#algo-spanning-items)**Increase sizes to accommodate spanning items crossing content-sized tracks:** Next, consider the items with a span of 2 that do not span a track with a [flexible sizing function](#flexible-sizing-function).
   
   1. [](#track-size-intrinsic-min)**For intrinsic minimums:** First [distribute extra space](#distribute-extra-space) to [base sizes](#base-size) of tracks with an [intrinsic](#intrinsic-sizing-function) [min track sizing function](#min-track-sizing-function), to accommodate these items’ [minimum contributions](#minimum-contribution).
      
      If the grid container is being sized under a [min-](https://www.w3.org/TR/css-sizing-3/#min-content-constraint) or [max-content constraint](https://www.w3.org/TR/css-sizing-3/#max-content-constraint), use the items’ [limited min-content contributions](#limited-contribution) in place of their [minimum contributions](#minimum-contribution) here. (For an item spanning multiple tracks, the upper limit used to calculate its limited min-/max-content contribution is the *sum* of the [fixed](#fixed-sizing-function) [max track sizing functions](#max-track-sizing-function) of any tracks it spans, and is applied if it only spans such tracks.)
   2. [](#track-size-content-min)**For content-based minimums:** Next continue to [distribute extra space](#distribute-extra-space) to the [base sizes](#base-size) of tracks with a [min track sizing function](#min-track-sizing-function) of [min-content](#valdef-grid-template-columns-min-content) or [max-content](#valdef-grid-template-columns-max-content), to accommodate these items' [min-content contributions](https://www.w3.org/TR/css-sizing-3/#min-content-contribution).
   3. [](#track-size-max-content-min)**For max-content minimums:** Next, if the grid container is being sized under a [max-content constraint](https://www.w3.org/TR/css-sizing-3/#max-content-constraint), continue to [distribute extra space](#distribute-extra-space) to the [base sizes](#base-size) of tracks with a [min track sizing function](#min-track-sizing-function) of [auto](#valdef-grid-template-columns-auto) or [max-content](#valdef-grid-template-columns-max-content), to accommodate these items' [limited max-content contributions](#limited-contribution).
      
      In all cases, continue to [distribute extra space](#distribute-extra-space) to the [base sizes](#base-size) of tracks with a [min track sizing function](#min-track-sizing-function) of [max-content](#valdef-grid-template-columns-max-content), to accommodate these items' [max-content contributions](https://www.w3.org/TR/css-sizing-3/#max-content-contribution).
   4. If at this point any track’s [growth limit](#growth-limit) is now less than its [base size](#base-size), increase its growth limit to match its base size.
   5. **For intrinsic maximums:** Next [distribute extra space](#distribute-extra-space) to the [growth limits](#growth-limit) of tracks with [intrinsic](#intrinsic-sizing-function) [max track sizing function](#max-track-sizing-function), to accommodate these items' [min-content contributions](https://www.w3.org/TR/css-sizing-3/#min-content-contribution). Mark any tracks whose growth limit changed from infinite to finite in this step as infinitely growable for the next step.
      
      Why does the [infinitely growable](#infinitely-growable) flag exist?
      
      [Peter Salas explains](https://lists.w3.org/Archives/Public/www-style/2014Mar/0500.html):
      
      > ```
      > Consider the following case:
      
      Two "auto" tracks (i.e. ''minmax(min-content, max-content) minmax(min-content, max-content)'').
      Item 1 is in track 1, and has min-content = max-content = 10.
      Item 2 spans tracks 1 and 2, and has min-content = 30, max-content = 100.
      
      After resolving min-content/max-content for the first item, we have this.
      
      track 1: base size = 10 growth limit = 10
      
      track 2: base size = 0 growth limit = infinity
      
      Then we resolve min-content/max-content for the second item.
      
      Phase 1 sets the base size of track 2 to 20 so that the two tracks' base sizes sum to 30.
      Phase 2 does nothing because there are no relevant tracks.
      Phase 3 sets the growth limit of track 2 to 20 so that the two tracks' growth limits sum to 30.
      In phase 4, we need to grow the sum of the growth limits by 70 to accommodate item 2.
      Two options are:
      
      1. Grow each track’s growth limit equally,
        and end up with growth limits = [45, 55].
      2. Grow only the second track’s growth limit,
        and end up with growth limits = [10, 90].
      
      By not considering the just-set growth limit as a constraint during space distribution
      (i.e. by treating it as infinity),
      we get the second result,
      which we considered a better result because the first track remains sized exactly to the first item.
      > ```
   6. **For max-content maximums:** Lastly continue to [distribute extra space](#distribute-extra-space) to the [growth limits](#growth-limit) of tracks with a [max track sizing function](#max-track-sizing-function) of [max-content](#valdef-grid-template-columns-max-content), to accommodate these items' [max-content contributions](https://www.w3.org/TR/css-sizing-3/#max-content-contribution).
   
   Repeat incrementally for items with greater spans until all items have been considered.
4. [](#algo-spanning-flex-items)**Increase sizes to accommodate spanning items crossing [flexible tracks](#flexible-tracks):** Next, repeat the previous step instead considering (together, rather than grouped by span size) all items that *do* span a track with a [flexible sizing function](#flexible-sizing-function) while
   
   - distributing space *only* to [flexible tracks](#flexible-tracks) (i.e. treating all other tracks as having a [fixed sizing function](#fixed-sizing-function))
   - if the sum of the [flexible sizing functions](#flexible-sizing-function) of all [flexible tracks](#flexible-tracks) spanned by the item is greater than or equal to one, distributing space to such tracks according to the ratios of their flexible sizing functions rather than distributing space equally; and if the sum is less than one, distributing that proportion of space according to the ratios of their flexible sizing functions and the rest equally
5. [](#algo-finite-growth)If any track still has an infinite [growth limit](#growth-limit) (because, for example, it had no items placed in it or it is a [flexible track](#flexible-tracks)), set its growth limit to its [base size](#base-size).

Note: There is no single way to satisfy intrinsic sizing constraints when items span across multiple tracks. This algorithm embodies a number of heuristics which have been seen to deliver good results on real-world use-cases, such as the “game” examples earlier in this specification. This algorithm may be updated in the future to take into account more advanced heuristics as they are identified.

#### 12.5.1. Distributing Extra Space Across Spanned Tracks[](#extra-space)

To distribute extra space, perform the following steps, with these inputs:

- whether to affect [base sizes](#base-size) or [growth limits](#growth-limit) (the `affected size`s).
- which tracks to affect (the `affected track`s).
- what intrinsic size contributions are being accommodated (the `size contribution`s) of which grid items spanning those tracks (the `item`s).

<!--THE END-->

1. Maintain separately for each `affected track` a `planned increase`, initially set to 0. (This prevents the size increases from becoming order-dependent.)
2. [For each](https://infra.spec.whatwg.org/#list-iterate) accommodated `item`, considering only tracks the item spans:
   
   1. **Find the space to distribute:** Subtract the `affected size` of every spanned track (not just the `affected track`s) from the item’s `size contribution`, flooring it at zero. (For infinite [growth limits](#growth-limit), substitute the track’s [base size](#base-size).) This remaining size contribution is the `space` to distribute.
      
      ```
      space = max(0, size contribution - ∑track-sizes)
      ```
   2. **Distribute `space` up to limits:**
      
      Find the `item-incurred increase` for each `affected track` by: distributing the `space` equally among these tracks, freezing a track’s `item-incurred increase` as its `affected size` + `item-incurred increase` reaches its `limit` (and continuing to grow the unfrozen tracks as needed).
      
      For [base sizes](#base-size), the `limit` is its [growth limit](#growth-limit), capped by its [fit-content()](#funcdef-grid-template-columns-fit-content) argument if any. For growth limits, the `limit` is the growth limit if the growth limit is finite and the track is not [infinitely growable](#infinitely-growable), otherwise its fit-content() argument if it has a fit-content() [track sizing function](#grid-template-rows-track-sizing-function), and infinity otherwise.
      
      Note: If the `affected size` was a [growth limit](#growth-limit) and the track is not marked [infinitely growable](#infinitely-growable), then each `item-incurred increase` will be zero.
   3. **Distribute `space` to non-affected tracks:**
      
      If extra `space` remains at this point, and the item spans both `affected tracks` and non-`affected tracks`, distribute space as for the previous step, but into the non-`affected tracks` instead.
      
      Note: This distributes any remaining space into tracks that have not yet reached their growth limits, instead of violating the growth limits of the `affected tracks`.
   4. **Distribute `space` beyond limits:**
      
      If extra `space` remains at this point, unfreeze and continue to distribute `space` to the `item-incurred increase` of…
      
      - when [accommodating minimum contributions](#track-size-intrinsic-min) or [accommodating min-content contributions](#track-size-content-min) into [base sizes](#base-size): any `affected track` that happens to also have an intrinsic [max track sizing function](#max-track-sizing-function); if there are no such tracks, then all `affected track`s.
      - when [accommodating max-content contributions](#track-size-max-content-min) into [base sizes](#base-size): any `affected track` that happens to also have a [max-content](#valdef-grid-template-columns-max-content) [max track sizing function](#max-track-sizing-function); if there are no such tracks, then all `affected track`s.
      - when accommodating any contribution into [growth limits](#growth-limit): any `affected track` that has an intrinsic [max track sizing function](#max-track-sizing-function).
      
      For this purpose, the [max track sizing function](#max-track-sizing-function) of a [fit-content()](#funcdef-grid-template-columns-fit-content) track is treated as [max-content](#valdef-grid-template-columns-max-content) until the track reaches the limit specified as the fit-content() argument, after which its max track sizing function is treated as being a [fixed sizing function](#fixed-sizing-function) of that argument (which can change which tracks continue to receive space in this step).
      
      Note: This step prioritizes the distribution of space for accommodating `size contribution`s beyond the tracks' current growth limits based on the types of their [max track sizing functions](#max-track-sizing-function).
   5. For each `affected track`, if the track’s `item-incurred increase` is larger than the track’s `planned increase` set the track’s `planned increase` to that value.
3. **Update the tracks' `affected size`s** by adding in the `planned increase`, so that the next round of space distribution will account for the increase. (If the affected size is an infinite [growth limit](#growth-limit), set it to the track’s [base size](#base-size) plus the `planned increase`.)

### 12.6. Maximize Tracks[](#algo-grow-tracks)

If the [free space](#free-space) is positive, distribute it equally to the [base sizes](#base-size) of all tracks, freezing tracks as they reach their [growth limits](#growth-limit) (and continuing to grow the unfrozen tracks as needed).

For the purpose of this step: if sizing the [grid container](#grid-container) under a [max-content constraint](https://www.w3.org/TR/css-sizing-3/#max-content-constraint), the [free space](#free-space) is infinite; if sizing under a [min-content constraint](https://www.w3.org/TR/css-sizing-3/#min-content-constraint), the free space is zero.

If this would cause the grid to be larger than the [grid container’s](#grid-container) [inner size](https://www.w3.org/TR/css-sizing-3/#inner-size) as limited by its [max-width/height](https://www.w3.org/TR/CSS2/visudet.html#propdef-max-width), then redo this step, treating the [available grid space](#available-grid-space) as equal to the grid container’s inner size when it’s sized to its max-width/height.

### 12.7. Expand Flexible Tracks[](#algo-flex-tracks)

This step sizes [flexible tracks](#flexible-tracks) using the largest value it can assign to an [fr](#valdef-flex-fr) without exceeding the [available space](https://www.w3.org/TR/css-sizing-3/#available).

First, find the grid’s used [flex fraction](#flex-fraction):

If the [free space](#free-space) is zero or if sizing the [grid container](#grid-container) under a [min-content constraint](https://www.w3.org/TR/css-sizing-3/#min-content-constraint):

The used [flex fraction](#flex-fraction) is zero.

Otherwise, if the [free space](#free-space) is a [definite](https://www.w3.org/TR/css-sizing-3/#definite) length:

The used [flex fraction](#flex-fraction) is the result of [finding the size of an fr](#algo-find-fr-size) using all of the [grid tracks](#grid-track) and a [space to fill](#space-to-fill) of the [available grid space](#available-grid-space).

Otherwise, if the [free space](#free-space) is an [indefinite](https://www.w3.org/TR/css-sizing-3/#indefinite) length:

The used [flex fraction](#flex-fraction) is the maximum of:

- For each flexible track, if the flexible track’s [flex factor](#grid-template-columns-flex-factor) is greater than one, the result of dividing the track’s [base size](#base-size) by its flex factor; otherwise, the track’s base size.
- For each [grid item](#grid-item) that crosses a flexible track, the result of [finding the size of an fr](#algo-find-fr-size) using all the grid tracks that the item crosses and a [space to fill](#space-to-fill) of the item’s [max-content contribution](https://www.w3.org/TR/css-sizing-3/#max-content-contribution).

If using this [flex fraction](#flex-fraction) would cause the [grid](#grid) to be smaller than the [grid container’s](#grid-container) [min-width/height](https://www.w3.org/TR/CSS2/visudet.html#propdef-min-width) (or larger than the grid container’s [max-width/height](https://www.w3.org/TR/CSS2/visudet.html#propdef-max-width)), then redo this step, treating the [free space](#free-space) as definite and the [available grid space](#available-grid-space) as equal to the grid container’s [inner size](https://www.w3.org/TR/css-sizing-3/#inner-size) when it’s sized to its min-width/height (max-width/height).

For each [flexible track](#flexible-tracks), if the product of the used [flex fraction](#flex-fraction) and the track’s [flex factor](#grid-template-columns-flex-factor) is greater than the track’s [base size](#base-size), set its base size to that product.

#### 12.7.1. Find the Size of an [fr](#valdef-flex-fr)[](#algo-find-fr-size)

This algorithm finds the largest size that an [fr](#valdef-flex-fr) unit can be without exceeding the target size. It must be called with a set of [grid tracks](#grid-track) and some quantity of space to fill.

1. Let leftover space be the [space to fill](#space-to-fill) minus the [base sizes](#base-size) of the non-flexible [grid tracks](#grid-track).
2. Let flex factor sum be the sum of the [flex factors](#grid-template-columns-flex-factor) of the [flexible tracks](#flexible-tracks). If this value is less than 1, set it to 1 instead.
3. Let the hypothetical fr size be the [leftover space](#leftover-space) divided by the [flex factor sum](#flex-factor-sum).
4. If the product of the [hypothetical fr size](#hypothetical-fr-size) and a [flexible track](#flexible-tracks)’s [flex factor](#grid-template-columns-flex-factor) is less than the track’s base size, restart this algorithm treating all such tracks as inflexible.
5. Return the [hypothetical fr size](#hypothetical-fr-size).

### 12.8. Stretch auto Tracks[](#algo-stretch)

When the [content-distribution property](https://www.w3.org/TR/css-align-3/#content-distribution-properties) of the [grid container](#grid-container) is [normal](https://www.w3.org/TR/css-align-3/#valdef-justify-content-normal) or [stretch](https://www.w3.org/TR/css-align-3/#valdef-align-content-stretch) in this axis, this step expands tracks that have an [auto](#valdef-grid-template-columns-auto) [max track sizing function](#max-track-sizing-function) by dividing any remaining positive, [definite](https://www.w3.org/TR/css-sizing-3/#definite) [free space](#free-space) equally amongst them. If the free space is [indefinite](https://www.w3.org/TR/css-sizing-3/#indefinite), but the grid container has a definite [min-width/height](https://www.w3.org/TR/CSS2/visudet.html#propdef-min-width), use that size to calculate the free space for this step instead.

## 13. Fragmenting Grid Layout[](#pagination)

[Grid containers](#grid-container) can break across pages between rows or columns and inside items. The [break-\*](https://www.w3.org/TR/css-break-3/#propdef-break-before) properties apply to grid containers as normal for the formatting context in which they participate. This section defines how they apply to grid items and the contents of grid items.

The following breaking rules refer to the [fragmentation container](https://www.w3.org/TR/css-break-4/#fragmentation-container) as the “page”. The same rules apply in any other [fragmentation context](https://www.w3.org/TR/css-break-4/#fragmentation-context). (Substitute “page” with the appropriate fragmentation container type as needed.) See the [CSS Fragmentation Module](https://www.w3.org/TR/css-break/) [\[CSS3-BREAK\]](#biblio-css3-break "CSS Fragmentation Module Level 3").

The exact layout of a fragmented grid container is not defined in this level of Grid Layout. However, breaks inside a grid container are subject to the following rules:

- The [break-before](https://www.w3.org/TR/css-break-3/#propdef-break-before) and [break-after](https://www.w3.org/TR/css-break-3/#propdef-break-after) properties on [grid items](#grid-item) are propagated to their grid row. The break-before property on the first row and the break-after property on the last row are propagated to the grid container.
- A forced break inside a grid item effectively increases the size of its contents; it does not trigger a forced break inside sibling items.
- [Class A break opportunities](https://www.w3.org/TR/css3-break/#btw-blocks) occur between rows or columns (whichever is in the appropriate axis), and [Class C break opportunities](https://www.w3.org/TR/css3-break/#end-block) occur between the first/last row (column) and the grid container’s content edges. [\[CSS3-BREAK\]](#biblio-css3-break "CSS Fragmentation Module Level 3")
- When a grid container is continued after a break, the space available to its [grid items](#grid-item) (in the block flow direction of the fragmentation context) is reduced by the space consumed by grid container fragments on previous pages. The space consumed by a grid container fragment is the size of its content box on that page. If as a result of this adjustment the available space becomes negative, it is set to zero.
- Aside from the rearrangement of items imposed by the previous point, UAs should attempt to minimize distortion of the grid container with respect to unfragmented flow.

### 13.1. Sample Fragmentation Algorithm[](#fragmentation-alg)

*This section is non-normative.*

This is a rough draft of one possible fragmentation algorithm, and still needs to be severely cross-checked with the [\[CSS-FLEXBOX-1\]](#biblio-css-flexbox-1 "CSS Flexible Box Layout Module Level 1") algorithm for consistency. Feedback is welcome; please reference the rules above instead as implementation guidance.

1. Layout the grid following the [§ 12 Grid Layout Algorithm](#layout-algorithm) by using the [fragmentation container](https://www.w3.org/TR/css-break-4/#fragmentation-container)’s inline size and assume unlimited block size. During this step all [grid-row](#propdef-grid-row) [auto](#grid-placement-auto) and [fr](#valdef-flex-fr) values must be resolved.
2. Layout the grid container using the values resolved in the previous step.
3. If a [grid area](#grid-area)’s size changes due to fragmentation (do not include items that span rows in this decision), increase the grid row size as necessary for rows that either:
   
   - have a content min track sizing function.
   - are in a grid that does not have an explicit height and the grid row is flexible.
4. If the grid height is [auto](#grid-placement-auto), the height of the grid should be the sum of the final row sizes.
5. If a grid area overflows the grid container due to margins being collapsed during fragmentation, extend the grid container to contain this grid area (this step is necessary in order to avoid circular layout dependencies due to fragmentation).

If the grid’s height is specified, steps three and four may cause the grid rows to overflow the grid.
