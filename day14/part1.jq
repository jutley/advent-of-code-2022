include "lib";

def get_line_points_for_extremities($p1; $p2):
  if $p1[0] == $p2[0]
  then
    [$p1[0]] +
    (range(([$p1[1], $p2[1]] | min); ([$p1[1], $p2[1]] | max + 1)) | [.])
  else
    (range(([$p1[0], $p2[0]] | min); ([$p1[0], $p2[0]] | max + 1)) | [.]) +
    [$p1[1]]
  end
;

def drop_sand($environment; $col; $row):
  if $environment[$col][$row + 1] == "."
  then drop_sand($environment; $col; $row + 1)
  elif $environment[$col - 1][$row + 1] == "."
  then drop_sand($environment; $col - 1; $row + 1)
  elif $environment[$col + 1][$row + 1] == "."
  then drop_sand($environment; $col + 1; $row + 1)
  else $environment[$col][$row] = "o"
  end
;

map(split(" -> ") | map(split(",") | map(tonumber)))
| map(
  [.] + [.[1:]] | transpose | map(
      map(select(. != null))
      | select(length == 2)
      | get_line_points_for_extremities(.[0]; .[1])
    )
)
| flatten(1)
| unique
| (map(.[0]) | [min - 1, max + 1]) as [$min_col, $max_col]
| (map(.[1]) | max) as $max_row
| [range($max_col - $min_col + 1) | [range($max_row + 1) | "."]] as $empty_grid
| reduce .[] as $point ($empty_grid; .[$point[0] - $min_col][$point[1]] = "#")

| until(transpose | last | contains(["o"]); drop_sand(.; 500 - $min_col; 0))

| map(map(select(. == "o")) | length) | add - 1

# | transpose
# | map(join(""))
# | join("\n")
