# Hint 2

Split the 48-bit VA into **`[L4 9][L3 9][L2 9][L1 9][OFFSET 12]`** — the top
group is Level 4, exactly as in the page-table document.

Walk the floor L1 → L4 (row → bay → shelf → sub), then let the offset pick the
exact box. :)
