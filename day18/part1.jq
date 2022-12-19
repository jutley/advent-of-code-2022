include "lib";

def parse: map(split(",") | map(tonumber) as [$x, $y, $z] | {$x, $y, $z});

parse
| [
  (group_by({x, y}) | map(map(.z) | sort)),
  (group_by({y, z}) | map(map(.x) | sort)),
  (group_by({x, z}) | map(map(.y) | sort))
]
# 20 22 22
| map(map(
    if length > 1
    then [.[:-1], .[1:]] | transpose | map(if .[0] + 1 == .[1] then 0 else 2 end) | add
    else 0
    end
    | . + 2
  ))
| flatten | add
