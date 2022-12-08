include "lib";

def tree_is_visisble(trees; row; col):
  trees[row] as $full_row |
  (trees | map(.[col])) as $full_col |

  ($full_row[:col]     | max) < trees[row][col] or
  ($full_row[col + 1:] | max) < trees[row][col] or
  ($full_col[:row]     | max) < trees[row][col] or
  ($full_col[row + 1:] | max) < trees[row][col]
;

map(split("")) as $trees |
[
  range(1; $trees | length - 1) |
  . as $row |
  range(1; $trees[0] | length - 1) |
  . as $col |
  if tree_is_visisble($trees; $row; $col) then [$row, $col] else empty end
] as $visible_interior_trees |

($trees | length * 2) + ($trees[0] | (length - 2) * 2) + ($visible_interior_trees | length)
