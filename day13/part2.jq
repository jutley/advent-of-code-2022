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

def merge_sort:
  def merge($sorted_left; $sorted_right; $acc):
    if $sorted_left | length == 0 then $acc + $sorted_right
    elif $sorted_right | length == 0 then $acc + $sorted_left
    elif in_order($sorted_left; $sorted_right) < 0 then merge($sorted_left[1:]; $sorted_right; $acc + [$sorted_left[0]])
    else merge($sorted_left; $sorted_right[1:]; $acc + [$sorted_right[0]])
    end
  ;

  if length <= 1 then .
  else
    (length / 2 | floor) as $mid
    | (.[:$mid] | merge_sort) as $sorted_left
    | (.[$mid:] | merge_sort) as $sorted_right
    | merge($sorted_left; $sorted_right; [])
  end
;

map(select(length > 0) | fromjson) + [[[2]], [[6]]]
| merge_sort
| reverse
| to_entries
| map(select(.value == [[2]] or .value == [[6]]) | .key + 1)
| .[0] * .[1]
