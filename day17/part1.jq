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
    rock_point: [3, 2] # row from bottom, col from left
  }

| until(.rocks_count == 2022;
    process_jet($jets)
    | if rock_can_move_down(.rock; .rock_point; .grid)
      then .rock_point[0] -= 1
      else rest_rock("#") | queue_next_rock($rocks; $empty_row)
      end
    | .tick_count += 1
  )

| .