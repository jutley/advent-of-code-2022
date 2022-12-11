include "lib";

def update_head(head; direction):
  head
  | zip({
    "U": [1, 0],
    "D": [-1, 0],
    "L": [0, -1],
    "R": [0, 1]
  }[direction])
  | map(add)
;

def update_tail(tail; head):
  tail
  | . as $tail
  | zip(head)
  | map(.[1] - .[0])
  | . as $vector
  | map(fabs)
  | if max < 2 then [0,0]
    else ($vector | map(. / 2 | round))
    end
  | zip($tail)
  | map(add)
;

# def rope_to_string($rope_to_print):
#   $rope_to_print | map(join(",")) | join(",,,") | stderr | $rope_to_print
#   | (map(.[1], 0) | max) as $max_x
#   | (map(.[0], 0) | max) as $max_y
#   | (map(.[1], 0) | min) as $min_x
#   | (map(.[0], 0) | min) as $min_y
#   | ($max_x - $min_x + 1) as $width
#   | ($max_y - $min_y + 1) as $height
#   | ([0, $min_x] | min | fabs) as $x_offset
#   | ([0, $min_y] | min | fabs) as $y_offset
#   | [range($height)] | map(
#     [range($width)] | map(".")
#   ) as $grid
#   | $rope_to_print | to_entries | reverse | reduce .[] as $next ($grid;
#     .[$height - 1 - $next.value[0] - $y_offset][$next.value[1] + $x_offset] = $next.key
#   )
#   | .[$height - 1 - $y_offset][$x_offset] = "s" | map(join("")) | (join("\n") + "\n\n")
# ;

map(
  capture("(?<direction>.) (?<count>\\d+)")
  | .count |= tonumber
  | .direction as $direction
  | range(.count)
  | $direction
)
| reduce .[] as $step ({rope: ([range(10)] | map([0, 0])), all_tail_positions: [[0, 0]]};
    .rope |= (
      reduce .[1:][] as $old_curr_knot ([update_head(first; $step)];
        . as $rope
        | last as $new_prev_knot
        | update_tail($old_curr_knot; $new_prev_knot) as $new_curr_knot
        | $rope + [$new_curr_knot]
      )
    )
    | .all_tail_positions += (.rope | [last])
  )
| .all_tail_positions
| sort
| unique
| length
