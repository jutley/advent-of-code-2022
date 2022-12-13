include "lib";

def surrounding_squares($this_square; $rows; $cols):
  [[1,0],[0,1],[-1,0],[0,-1]]
  | map(
      [., $this_square] | transpose | map(add)
      | select(min >= 0)
      | select(.[0] < $rows)
      | select(.[1] < $cols)
    )
;

map(
  split("") | map(
    if inside("SE") then .
    else to_ascii_code(.) - to_ascii_code("a")
    end
  )
)
| {
    topology: .,
    shortest_paths: map(map(null)),
    start: (to_entries | map(select(.key as $i | .value | any(. == "S")))[0] | [.key, (.value | to_entries[] | select(.value == "S").key)]),
    target: (to_entries | map(select(.key as $i | .value | any(. == "E")))[0] | [.key, (.value | to_entries[] | select(.value == "E").key)])
  }
| .topology[.start[0]][.start[1]] = 0
| .topology[.target[0]][.target[1]] = 25
| .shortest_paths[.start[0]][.start[1]] = 0
| .next_squares = [.start]
| until(.shortest_paths[.target[0]][.target[1]] != null;
    .next_squares[0] as $this_square
    | del(.next_squares[0])
    | reduce surrounding_squares($this_square; (.topology | length); (.topology[0] | length))[] as $next_square (.;
        if (.topology[$next_square[0]][$next_square[1]] <= .topology[$this_square[0]][$this_square[1]] + 1)
          and (.shortest_paths[$next_square[0]][$next_square[1]] == null)
        then
          .shortest_paths[$next_square[0]][$next_square[1]] = .shortest_paths[$this_square[0]][$this_square[1]] + 1
          | .next_squares += [$next_square]
        else
          .
        end
      )
    | .shortest_paths as $shortest_paths
    | .next_squares |= sort_by($shortest_paths[.[0]][.[1]])
  )
| .shortest_paths[.target[0]][.target[1]]
