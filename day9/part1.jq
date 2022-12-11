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

map(
  capture("(?<direction>.) (?<count>\\d+)")
  | .count |= tonumber
  | .direction as $direction
  | range(.count)
  | $direction
)
| reduce .[] as $step ({head: [0, 0], tail: [0, 0], all_tail_positions: [[0, 0]]};
    update_head(.head; $step) as $new_head
    | update_tail(.tail; $new_head) as $new_tail
    | {
      head: $new_head,
      tail: $new_tail,
      all_tail_positions: ((.all_tail_positions + [$new_tail]))
    }
  )
| .all_tail_positions
| sort
| unique
| length
