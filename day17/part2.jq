include "lib";

def height_of_rock($rock): {
  hline: 1,
  cross: 3,
  right: 3,
  vline: 4,
  square: 2
}[$rock];

def relative_points_for_rock($rock): {
  hline: [[0,0], [0,1], [0,2], [0,3]],
  cross: [[0,1], [1,0], [1,1], [1,2], [2,1]],
  right: [[0,0], [0,1], [0,2], [1,2], [2,2]],
  vline: [[0,0], [1,0], [2,0], [3,0]],
  square: [[0,0], [0,1], [1,0], [1,1]]
}[$rock];

def points_for_rock($rock; $rock_point):
  relative_points_for_rock($rock) | map([., $rock_point] | transpose | map(add));

def rock_position_is_clear($grid; $rock; $rock_point):
  points_for_rock($rock; $rock_point) | all(
    .[0] >= 0 and .[1] >= 0 and .[1] < 7 and $grid[.[0]][.[1]] == "."
  );

def rock_can_move_left($rock; $rock_point; $grid):
  rock_position_is_clear($grid; $rock; [$rock_point[0], $rock_point[1] - 1]);

def rock_can_move_right($rock; $rock_point; $grid):
  rock_position_is_clear($grid; $rock; [$rock_point[0], $rock_point[1] + 1]);

def rock_can_move_down($rock; $rock_point; $grid):
  rock_position_is_clear($grid; $rock; [$rock_point[0] - 1, $rock_point[1]]);

def jet_points_left($jets): $jets[.tick_count % ($jets | length)] == "<";
def jet_points_right($jets): $jets[.tick_count % ($jets | length)] == ">";
def process_jet($jets):
  if jet_points_left($jets) and rock_can_move_left(.rock; .rock_point; .grid)
  then .rock_point[1] -= 1
  elif jet_points_right($jets) and rock_can_move_right(.rock; .rock_point; .grid)
  then .rock_point[1] += 1
  else .
  end
;

def rest_rock($symbol):
  reduce points_for_rock(.rock; .rock_point)[] as $point (.;
    .grid[$point[0]][$point[1]] = $symbol
  )
;

def queue_next_rock($rocks; $empty_row):
  .rocks_count += 1
  | .rock = $rocks[.rocks_count % ($rocks | length)]
  | .height = (.grid | . as $grid | length - 1 | until($grid[.] | any(. == "#"); . - 1) + 1)
  | (.height + 3 + height_of_rock(.rock)) as $required_height
  | .grid += [range([0, $required_height - (.grid | length)] | max) | $empty_row]
  | .rock_point = [.height + 3, 2]
  | .ticks_for_shape = 0
;

def drop_until($rocks; $jets; $empty_row; $state; condition):
  $state | until(condition;
    process_jet($jets)
    | if rock_can_move_down(.rock; .rock_point; .grid)
      then .rock_point[0] -= 1
      else . as $root | {rocks_count} | $root | rest_rock("#") | queue_next_rock($rocks; $empty_row)
      end
    | .tick_count += 1
    | .ticks_for_shape += 1
  )
;

.[0] | split("") as $jets
| ["hline", "cross", "right", "vline", "square"] as $rocks
| [range(7) | "."] as $empty_row
| {
    grid: [range(4) | $empty_row],
    rocks_count: 0,
    tick_count: 0,
    height: 0,
    rock: $rocks[0],
    rock_point: [3, 2], # row from bottom, col from left
    ticks_for_shape: 0,
    states_after_full_jet_loops: []
  } as $start_state
| $start_state
# | drop_until($rocks; $jets; $empty_row; $start_state; .tick_count == ($jets | length * 2))
| until(.states_after_full_jet_loops | map({rock, ticks_for_shape}) | group_by(.) | map(length) | max == 2;
    .tick_count as $tc
    | drop_until($rocks; $jets; $empty_row; .; (.tick_count > $tc) and (.tick_count % ($jets | length) == 0))
    | .states_after_full_jet_loops += [{rock, ticks_for_shape, height, tick_count, rocks_count}]
  )
| . as $state_checkpoint
| .states_after_full_jet_loops
| last as $cycle_identifier
| to_entries | map(select(.value.rock == $cycle_identifier.rock and .value.ticks_for_shape == $cycle_identifier.ticks_for_shape))
| (last.value.rocks_count - first.value.rocks_count) as $cycle_rocks
| (last.value.height - first.value.height) as $cycle_height
| first.value.rocks_count as $pre_cycle_rocks
| first.value.height as $pre_cycle_height
| 1000000000000 as $total_rocks
| (($total_rocks - $pre_cycle_rocks) % $cycle_rocks) as $post_cycle_rocks
| (last.value.rocks_count + $post_cycle_rocks) as $cycle_rocks_target

| drop_until($rocks; $jets; $empty_row; $state_checkpoint; .rocks_count == $cycle_rocks_target)
| (.height - $pre_cycle_height - $cycle_height) as $post_cycle_height
| $pre_cycle_height + $post_cycle_height + $cycle_height * (($total_rocks - $pre_cycle_rocks - $post_cycle_rocks) / $cycle_rocks)
