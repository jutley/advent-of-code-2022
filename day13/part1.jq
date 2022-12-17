include "lib";

def in_order($left; $right):
  # {$left, $right} | debug | map_values(type) | debug |
  if [($left | type), ($right | type)] == ["array", "number"] then
    in_order($left; [$right])
  elif [($left | type), ($right | type)] == ["number", "array"] then
    in_order([$left]; $right)
  elif [($left | type), ($right | type)] == ["number", "number"] then
    $right - $left
  elif ($left | type) == "null" then
    1
  elif ($right | type) == "null" then
    -1
  elif ($left | length) == 0 and ($right | length) == 0 then
    0
  elif ($left | length) > 0 and ($right | length) == 0 then
    -1
  else
    in_order($left[0]; $right[0])
    | if . != 0 then .
      else in_order($left[1:]; $right[1:])
      end
  end
;

join("\n") | split("\n\n") | map(split("\n") | map(fromjson) | {left: .[0], right: .[1]})
| to_entries | map(
    select(.value | in_order(.left; .right) >= 0)
    | .key + 1
  )
| add
