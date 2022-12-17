include "lib";

def parse:
  map(
    capture("Valve (?<valve>..) .* rate=(?<rate>.*); .* valves? (?<neighbor_valves>.*)")
    | .rate |= tonumber
    | .neighbor_valves |= split(", ")
    | {(.valve): (del(.valve) + {open: false})}
  )
  | add
;

def find_distances_between_valves:
  with_entries(.value = (
        {(.key): 0} + (.value | (.neighbor_valves | map({(.): 1}) | add))
  ))
  | . as $distances
  | until(all(length == ($distances | length));
      map_values(
        (
          to_entries
          | map(.value as $distance | $distances[.key] | map_values(. + $distance) | to_entries[])
          | group_by(.key)
          | map({(first.key): (map(.value) | min)}) | add
        ) + .
      )
    )
;

def permutations($distances):
  def aux($current_valve; $remaining):
    if length == 0 then []
    elif remaining <= 0 then []
    else
      . as $arr
      | range(length)
      | $arr[.] as $new_valve
      | [$new_valve] + (
          ($arr[:.] + $arr[. + 1:])
          | aux($new_valve; $remaining - $distances[$current_valve][$new_valve] - 1)
        )
    end
  ;
  aux("AA"; 30)
;

parse
| . as $input
| find_distances_between_valves as $distances
| (to_entries | map(select(.value.rate > 0) | .key) | [permutations($distances)]) as $orders
| $orders
| length
| debug
| $orders
| map(
    {
        pressure_released: 0,
        time: 30,
        current_valve: "AA",
        path: .
    }
    | until((.path | length == 0) or .time <= 0;
        .time -= $distances[.current_valve][.path[0]] + 1
        | .current_valve = .path[0]
        | .path |= del(.[0])
        | if .time > 0
          then .pressure_released += .time * $input[.current_valve].rate
          else .
          end
      )
    | .pressure_released
  )
| max
