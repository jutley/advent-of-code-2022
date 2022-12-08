include "lib";

def tree_is_visisble(trees; row; col):
  trees[row] as $full_row |
  (trees | map(.[col])) as $full_col |

  ($full_row[:col]     | max) < trees[row][col] or
  ($full_row[col + 1:] | max) < trees[row][col] or
  ($full_col[:row]     | max) < trees[row][col] or
  ($full_col[row + 1:] | max) < trees[row][col]
;

def tree_scenic_score(trees; row; col):
  trees[row] as $full_row |
  (trees | map(.[col])) as $full_col |

  ($full_row[:col] | reverse) as $trees_left |
  ($full_row[col + 1:]) as $trees_right |
  ($full_col[:row] | reverse) as $trees_top |
  ($full_col[row + 1:]) as $trees_bottom |
  [$trees_left, $trees_right, $trees_top, $trees_bottom] | map(
    reduce .[] as $current_tree ({acc: 0, stop: false};
      if .stop == false and $current_tree < trees[row][col] then {acc: (.acc + 1), stop: false}
      elif .stop == false and $current_tree >= trees[row][col] then {acc: (.acc + 1), stop: true}
      else .
      end
    ) |
    .acc
  ) |
  reduce .[] as $partial (1; . * $partial)
;

map(split("")) as $trees |
[
  range(1; $trees | length - 1) |
  . as $row |
  range(1; $trees[0] | length - 1) |
  . as $col |
  tree_scenic_score($trees; $row; $col)
] |
max
