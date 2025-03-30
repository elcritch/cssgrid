12. Grid Layout Algorithm
This section defines the grid layout algorithm, which sizes the grid container, sizes and positions all the grid tracks, and lays out the grid items which have been placed into its grid areas.

Run the Grid Item Placement Algorithm to resolve the placement of all grid items (including subgrids and their sub-items) in the grid.

Find the size of the grid container, per § 5.2 Sizing Grid Containers.

Note: During this phase, cyclic <percentage>s in track sizes are treated as auto.

Given the resulting grid container size, run the Grid Sizing Algorithm to size the grid.

Note: During this phase, <percentage>s in track sizes are resolved against the grid container size.

Lay out the grid items into their respective containing blocks. Each grid area’s width and height are considered definite for this purpose.

Note: Since formulas calculated using only definite sizes, such as the stretch fit formula, are also definite, the size of a grid item which is stretched is also considered definite.

12.1. Grid Sizing Algorithm
This section defines the grid sizing algorithm, which determines the size of all grid tracks and, by extension, the entire grid.

Each track has specified minimum and maximum sizing functions (which may be the same). Each sizing function is either:

A fixed sizing function (<length> or resolvable <percentage>).
An intrinsic sizing function (min-content, max-content, auto, fit-content()).
A flexible sizing function (<flex>).
The grid sizing algorithm defines how to resolve these sizing constraints into used track sizes.

First, the track sizing algorithm is used to resolve the sizes of the grid columns.
In this process, any grid item which is subgridded in the grid container’s inline axis is treated as empty and its grid items (the grandchildren) are treated as direct children of the grid container (their grandparent). This introspection is recursive.

Items which are subgridded only in the block axis, and whose grid container size in the inline axis depends on the size of its contents are also introspected: since the size of the item in this dimension can be dependent on the sizing of its subgridded tracks in the other, the size contribution of any such item to this grid’s column sizing (see Resolve Intrinsic Track Sizes) is taken under the provision of having determined its track sizing only up to the same point in the Grid Sizing Algorithm as this itself. E.g. for the first pass through this step, the item will have its tracks sized only through this first step; if a second pass of this step is triggered then the item will have completed a first pass through steps 1-3 as well as the second pass of this step prior to returning its size for consideration in this grid’s column sizing. Again, this introspection is recursive.

If calculating the layout of a grid item in this step depends on the available space in the block axis, assume the available space that it would have if any row with a definite max track sizing function had that size and all other rows were infinite. If both the grid container and all tracks have definite sizes, also apply align-content to find the final effective size of any gaps spanned by such items; otherwise ignore the effects of track alignment in this estimation.

Next, the track sizing algorithm resolves the sizes of the grid rows.
In this process, any grid item which is subgridded in the grid container’s block axis is treated as empty and its grid items (the grandchildren) are treated as direct children of the grid container (their grandparent). This introspection is recursive.

As with sizing columns, items which are subgridded only in the inline axis, and whose grid container size in the block axis depends on the size of its contents are also introspected. (As with sizing columns, the size contribution to this grid’s row sizing is taken under the provision of having determined its track sizing only up to this corresponding point in the algorithm; and again, this introspection is recursive.)

To find the inline-axis available space for any items whose block-axis size contributions require it, use the grid column sizes calculated in the previous step. If the grid container’s inline size is definite, also apply justify-content to account for the effective column gap sizes.

Then, if the min-content contribution of any grid item has changed based on the row sizes and alignment calculated in step 2, re-resolve the sizes of the grid columns with the new min-content and max-content contributions (once only).
To find the block-axis available space for any items whose inline-axis size contributions require it, use the grid row sizes calculated in the previous step. If the grid container’s block size is definite, also apply align-content to account for the effective row gap sizes.

This repetition is necessary for cases where the inline size of a grid item depends on the block size of its grid area. Examples include wrapped column flex containers (flex-flow: column wrap), orthogonal flows (writing-mode), multi-column containers, and items with an aspect-ratio (or with a child with an aspect ratio) whose size depends on the size of the row.
Next, if the min-content contribution of any grid item has changed based on the column sizes and alignment calculated in step 3, re-resolve the sizes of the grid rows with the new min-content and max-content contributions (once only).
To find the inline-axis available space for any items whose block-axis size contributions require it, use the grid column sizes calculated in the previous step. If the grid container’s inline size is definite, also apply justify-content to account for the effective column gap sizes.

Finally, align the tracks within the grid container according to the align-content and justify-content properties.
Note: This can introduce extra space between tracks, potentially enlarging the grid area of any grid items spanning the gaps beyond the space allotted to during track sizing.

Note: Track sizing in a subgridded dimension treats each item in a given track in that axis as members of the parent grid. This interlacing requires that grid sizing drill down per axis into subgrids, rather than completing both axes as it recurses. Note this means that a subgrid establishing an orthogonal flow would have the order of its track sizing inverted compared to a nested grid.

The following example illustrates how per-axis subgrids are sized:
Suppose we have a parent grid container A which contains an item B that has subgridded columns and contains a grandchild B that has subgridded rows and grandchild D that is simply a nested grid.

<grid-A>
  <grid-B subgrid=columns>
    <grid-C subgrid=rows></grid-C>
    <grid-D></grid-D>
  </grid-B>
<grid-A>
When A sizes its columns it treats B’s items as slotted into to A’s corresponding columns, but when A sizes its rows it treats B as a single item (a grid container with its own rows and some items including items C and D). Similarly when B sizes its rows, it treats C’s items as slotted into B’s rows, but when B sizes its columns, it treats C as a single item, just as it does with D. There is no relationship between C’s rows and A’s rows, because the rows in B are nested, not subgridded.

At a high level, the grid algorithm is:

Size the columns
Size the rows
Adjust the columns (if needed based on final row sizes)
The grid sizing algorithm in this example would thus look like this:

Resolve sizes of A’s grid columns, using the sizes of A’s grid items, treating B as empty but treating its children (including C and D) as items in grid A.
The grid algorithm simply recurses into D. For C, it’s more complicated:

Size C’s columns.
Size C’s rows by sizing B’s rows.
Adjust C’s columns.
Return C’s final column sizes.
A correct size for B’s rows requires C’s final column sizes, because the row size depends on the column size, and thus B’s rows could very well depend on C’s final column sizes. To break this cyclic dependency, we need to split the algorithm to depend on the initial approximation of C’s final column sizes, and do the adjustment pass later. So for C, we need to recurse into column sizing only, and pass that initial size up to A for its initial column sizing.

When we size B’s rows later on, we will size C’s rows (which are subgridded), and finish up C’s sizing by finalizing its columns. If this resulted in a change, we have the opportunity to trigger an adjustment pass for A’s columns during its adjustment pass.

Next, resolve sizes of A’s rows, using the sizes of A’s grid items, treating B as a single item.
Since B, as a subgrid, has its sizing is split out into the multiple passes, the grid algorithm issues only a row-sizing recursion into B: Size B’s rows, treating D as a single item, requesting its final size, and treating C as an empty item and hoisting its children as items into grid B.

B returns its final row size, which factors into A’s row sizing pass.

Last, finalize A’s column sizes. If C’s final size changes as a result of the row-sizing pass through B, this should trigger a resizing of B’s columns, which should trigger a resizing pass on A’s column.
12.2. Track Sizing Terminology
min track sizing function
If the track was sized with a minmax() function, this is the first argument to that function. If the track was sized with a <flex> value or fit-content() function, auto. Otherwise, the track’s sizing function.
max track sizing function
If the track was sized with a minmax() function, this is the second argument to that function. Otherwise, the track’s sizing function. In all cases, treat auto and fit-content() as max-content, except where specified otherwise for fit-content().
available grid space
Independently in each dimension, the available grid space is:
If the grid container’s size is definite, then use the size of its content box.

If the grid container is being sized under a min-content constraint or max-content constraint then the available grid space is that constraint (and is indefinite).

Note: auto sizes that indicate content-based sizing (e.g. the height of a block-level box in horizontal writing modes) are equivalent to max-content.

In all cases, clamp the available grid space according to the grid container’s min/max-width/height properties, if they are definite.

free space
Equal to the available grid space minus the sum of the base sizes of all the grid tracks (including gutters), floored at zero. If available grid space is indefinite, the free space is indefinite as well.
span count
The number of grid tracks crossed by a grid item in the applicable dimension.
Note: Remember that gutters are treated as fixed-size tracks—​tracks with their min and max sizing functions both set to the gutter’s used size—​for the purpose of the grid sizing algorithm. Their widths need to be incorporated into the track sizing algorithm’s calculations accordingly.

12.3. Track Sizing Algorithm
The remainder of this section is the track sizing algorithm, which calculates from the min and max track sizing functions the used track size. Each track has a base size, a <length> which grows throughout the algorithm and which will eventually be the track’s final size, and a growth limit, a <length> which provides a desired maximum size for the base size. There are 5 steps:

Initialize Track Sizes
Resolve Intrinsic Track Sizes
Maximize Tracks
Expand Flexible Tracks
Expand Stretched auto Tracks
12.4. Initialize Track Sizes
Initialize each track’s base size and growth limit. For each track, if the track’s min track sizing function is:

A fixed sizing function
Resolve to an absolute length and use that size as the track’s initial base size.
Note: Indefinite lengths cannot occur, as they’re treated as auto.

An intrinsic sizing function
Use an initial base size of zero.
For each track, if the track’s max track sizing function is:

A fixed sizing function
Resolve to an absolute length and use that size as the track’s initial growth limit.
An intrinsic sizing function
A flexible sizing function
Use an initial growth limit of infinity.
In all cases, if the growth limit is less than the base size, increase the growth limit to match the base size.

Note: Gutters are treated as empty fixed-size tracks for the purpose of the track sizing algorithm.

12.5. Resolve Intrinsic Track Sizes
This step resolves intrinsic track sizing functions to absolute lengths. First it resolves those sizes based on items that are contained wholly within a single track. Then it gradually adds in the space requirements of items that span multiple tracks, evenly distributing the extra space across those tracks insofar as possible.

Note: When this step is complete, all intrinsic base sizes and growth limits will have been resolved to absolute lengths.

Note: Remember that fit-content() and auto max track sizing functions are treated the same as max-content except where explicitly specified otherwise.

Shim baseline-aligned items so their intrinsic size contributions reflect their baseline alignment. For the items in each baseline-sharing group, add a “shim” (effectively, additional margin) on the start/end side (for first/last-baseline alignment) of each item so that, when start/end-aligned together their baselines align as specified.
Consider these “shims” as part of the items’ intrinsic size contribution for the purpose of track sizing, below. If an item uses multiple intrinsic size contributions, it can have different shims for each one.

For example, when the grid container has an indefinite size, it is first laid out under min/max-content constraints to find the size, then laid out "for real" with that size (which can affect things like percentage tracks). The "shims" added for each phase are independent, and only affect the layout during that phase.
Note: Note that both baseline self-aligned and baseline content-aligned items are considered in this step.

Note: Since grid items whose own size depends on the size of an intrinsically-sized track do not participate in baseline alignment, they are not shimmed.

Size tracks to fit non-spanning items: For each track with an intrinsic track sizing function and not a flexible sizing function, consider the items in it with a span of 1:
For min-content minimums:
If the track has a min-content min track sizing function, set its base size to the maximum of the items’ min-content contributions, floored at zero.
For max-content minimums:
If the track has a max-content min track sizing function, set its base size to the maximum of the items’ max-content contributions, floored at zero.
For auto minimums:
If the track has an auto min track sizing function and the grid container is being sized under a min-/max-content constraint, set the track’s base size to the maximum of its items’ limited min-content contributions, floored at zero. The limited min-/max-content contribution of an item is (for this purpose) its min-/max-content contribution (accordingly), limited by the max track sizing function (which could be the argument to a fit-content() track sizing function) if that is fixed and ultimately floored by its minimum contribution (defined below).
Otherwise, set the track’s base size to the maximum of its items’ minimum contributions, floored at zero. The minimum contribution of an item is the smallest outer size it can have. Specifically, if the item’s computed preferred size behaves as auto or depends on the size of its containing block in the relevant axis, its minimum contribution is the outer size that would result from assuming the item’s used minimum size as its preferred size; else the item’s minimum contribution is its min-content contribution. Because the minimum contribution often depends on the size of the item’s content, it is considered a type of intrinsic size contribution.

Note: For items with a specified minimum size of auto (the initial value), the minimum contribution is usually equivalent to the min-content contribution—​but can differ in some cases, see § 6.6 Automatic Minimum Size of Grid Items. Also, minimum contribution ≤ min-content contribution ≤ max-content contribution.

For min-content maximums:
If the track has a min-content max track sizing function, set its growth limit to the maximum of the items’ min-content contributions.
For max-content maximums:
If the track has a max-content max track sizing function, set its growth limit to the maximum of the items’ max-content contributions. For fit-content() maximums, furthermore clamp this growth limit by the fit-content() argument.
In all cases, if a track’s growth limit is now less than its base size, increase the growth limit to match the base size.

Note: This step is a simplification of the steps below for handling spanning items, and should yield the same behavior as running those instructions on items with a span of 1.

Increase sizes to accommodate spanning items crossing content-sized tracks: Next, consider the items with a span of 2 that do not span a track with a flexible sizing function.
For intrinsic minimums: First distribute extra space to base sizes of tracks with an intrinsic min track sizing function, to accommodate these items’ minimum contributions.
If the grid container is being sized under a min- or max-content constraint, use the items’ limited min-content contributions in place of their minimum contributions here. (For an item spanning multiple tracks, the upper limit used to calculate its limited min-/max-content contribution is the sum of the fixed max track sizing functions of any tracks it spans, and is applied if it only spans such tracks.)

For content-based minimums: Next continue to distribute extra space to the base sizes of tracks with a min track sizing function of min-content or max-content, to accommodate these items' min-content contributions.
For max-content minimums: Next, if the grid container is being sized under a max-content constraint, continue to distribute extra space to the base sizes of tracks with a min track sizing function of auto or max-content, to accommodate these items' limited max-content contributions.
In all cases, continue to distribute extra space to the base sizes of tracks with a min track sizing function of max-content, to accommodate these items' max-content contributions.

If at this point any track’s growth limit is now less than its base size, increase its growth limit to match its base size.
For intrinsic maximums: Next distribute extra space to the growth limits of tracks with intrinsic max track sizing function, to accommodate these items' min-content contributions. Mark any tracks whose growth limit changed from infinite to finite in this step as infinitely growable for the next step.
Why does the infinitely growable flag exist?
For max-content maximums: Lastly continue to distribute extra space to the growth limits of tracks with a max track sizing function of max-content, to accommodate these items' max-content contributions.
Repeat incrementally for items with greater spans until all items have been considered.

Increase sizes to accommodate spanning items crossing flexible tracks: Next, repeat the previous step instead considering (together, rather than grouped by span size) all items that do span a track with a flexible sizing function while
distributing space only to flexible tracks (i.e. treating all other tracks as having a fixed sizing function)
if the sum of the flexible sizing functions of all flexible tracks spanned by the item is greater than or equal to one, distributing space to such tracks according to the ratios of their flexible sizing functions rather than distributing space equally; and if the sum is less than one, distributing that proportion of space according to the ratios of their flexible sizing functions and the rest equally
If any track still has an infinite growth limit (because, for example, it had no items placed in it or it is a flexible track), set its growth limit to its base size.
Note: There is no single way to satisfy intrinsic sizing constraints when items span across multiple tracks. This algorithm embodies a number of heuristics which have been seen to deliver good results on real-world use-cases, such as the “game” examples earlier in this specification. This algorithm may be updated in the future to take into account more advanced heuristics as they are identified.

12.5.1. Distributing Extra Space Across Spanned Tracks
To distribute extra space, perform the following steps, with these inputs:
whether to affect base sizes or growth limits (the affected sizes).

which tracks to affect (the affected tracks).

what intrinsic size contributions are being accommodated (the size contributions) of which grid items spanning those tracks (the items).

Maintain separately for each affected track a planned increase, initially set to 0. (This prevents the size increases from becoming order-dependent.)
For each accommodated item, considering only tracks the item spans:
Find the space to distribute: Subtract the affected size of every spanned track (not just the affected tracks) from the item’s size contribution, flooring it at zero. (For infinite growth limits, substitute the track’s base size.) This remaining size contribution is the space to distribute.
space = max(0, size contribution - ∑track-sizes)
Distribute space up to limits:
Find the item-incurred increase for each affected track by: distributing the space equally among these tracks, freezing a track’s item-incurred increase as its affected size + item-incurred increase reaches its limit (and continuing to grow the unfrozen tracks as needed).

For base sizes, the limit is its growth limit, capped by its fit-content() argument if any. For growth limits, the limit is the growth limit if the growth limit is finite and the track is not infinitely growable, otherwise its fit-content() argument if it has a fit-content() track sizing function, and infinity otherwise.

Note: If the affected size was a growth limit and the track is not marked infinitely growable, then each item-incurred increase will be zero.

Distribute space to non-affected tracks:
If extra space remains at this point, and the item spans both affected tracks and non-affected tracks, distribute space as for the previous step, but into the non-affected tracks instead.

Note: This distributes any remaining space into tracks that have not yet reached their growth limits, instead of violating the growth limits of the affected tracks.

Distribute space beyond limits:
If extra space remains at this point, unfreeze and continue to distribute space to the item-incurred increase of…

when accommodating minimum contributions or accommodating min-content contributions into base sizes: any affected track that happens to also have an intrinsic max track sizing function; if there are no such tracks, then all affected tracks.
when accommodating max-content contributions into base sizes: any affected track that happens to also have a max-content max track sizing function; if there are no such tracks, then all affected tracks.
when accommodating any contribution into growth limits: any affected track that has an intrinsic max track sizing function.
For this purpose, the max track sizing function of a fit-content() track is treated as max-content until the track reaches the limit specified as the fit-content() argument, after which its max track sizing function is treated as being a fixed sizing function of that argument (which can change which tracks continue to receive space in this step).

Note: This step prioritizes the distribution of space for accommodating size contributions beyond the tracks' current growth limits based on the types of their max track sizing functions.

For each affected track, if the track’s item-incurred increase is larger than the track’s planned increase set the track’s planned increase to that value.
Update the tracks' affected sizes by adding in the planned increase, so that the next round of space distribution will account for the increase. (If the affected size is an infinite growth limit, set it to the track’s base size plus the planned increase.)
12.6. Maximize Tracks
If the free space is positive, distribute it equally to the base sizes of all tracks, freezing tracks as they reach their growth limits (and continuing to grow the unfrozen tracks as needed).

For the purpose of this step: if sizing the grid container under a max-content constraint, the free space is infinite; if sizing under a min-content constraint, the free space is zero.

If this would cause the grid to be larger than the grid container’s inner size as limited by its max-width/height, then redo this step, treating the available grid space as equal to the grid container’s inner size when it’s sized to its max-width/height.

12.7. Expand Flexible Tracks
This step sizes flexible tracks using the largest value it can assign to an fr without exceeding the available space.

First, find the grid’s used flex fraction:

If the free space is zero or if sizing the grid container under a min-content constraint:
The used flex fraction is zero.
Otherwise, if the free space is a definite length:
The used flex fraction is the result of finding the size of an fr using all of the grid tracks and a space to fill of the available grid space.
Otherwise, if the free space is an indefinite length:
The used flex fraction is the maximum of:
For each flexible track, if the flexible track’s flex factor is greater than one, the result of dividing the track’s base size by its flex factor; otherwise, the track’s base size.
For each grid item that crosses a flexible track, the result of finding the size of an fr using all the grid tracks that the item crosses and a space to fill of the item’s max-content contribution.
If using this flex fraction would cause the grid to be smaller than the grid container’s min-width/height (or larger than the grid container’s max-width/height), then redo this step, treating the free space as definite and the available grid space as equal to the grid container’s inner size when it’s sized to its min-width/height (max-width/height).

For each flexible track, if the product of the used flex fraction and the track’s flex factor is greater than the track’s base size, set its base size to that product.

12.7.1. Find the Size of an fr
This algorithm finds the largest size that an fr unit can be without exceeding the target size. It must be called with a set of grid tracks and some quantity of space to fill.

Let leftover space be the space to fill minus the base sizes of the non-flexible grid tracks.
Let flex factor sum be the sum of the flex factors of the flexible tracks. If this value is less than 1, set it to 1 instead.
Let the hypothetical fr size be the leftover space divided by the flex factor sum.
If the product of the hypothetical fr size and a flexible track’s flex factor is less than the track’s base size, restart this algorithm treating all such tracks as inflexible.
Return the hypothetical fr size.
12.8. Stretch auto Tracks
When the content-distribution property of the grid container is normal or stretch in this axis, this step expands tracks that have an auto max track sizing function by dividing any remaining positive, definite free space equally amongst them. If the free space is indefinite, but the grid container has a definite min-width/height, use that size to calculate the free space for this step instead.

