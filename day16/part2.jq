include "lib";

def parse:
  map(
    capture("Valve (?<valve>..) .* rate=(?<rate>.*); .* valves? (?<neighbor_valves>.*)")
    | .rate |= tonumber
    | .neighbor_valves |= split(", ")
    | {(.valve): (del(.valve))}
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

parse
| . as $input
| 26 as $total_time
| find_distances_between_valves as $distances
| map_values(.rate) as $valve_rates
| (to_entries | map(select(.value.rate > 0) | .key))
| . as $valves
| map(select($input[.].rate > 0) | {
    head: .,
    all_valves: [.],
    total_rate: $input[.].rate,
    accumulated_pressure: 0,
    time: 1,
  })
| reduce range(0; $valves | length - 1) as $group_index ([.];
    . + [[$valves, last] | [combinations] | map(
        . as [$next, $leaf]
        | select($leaf.all_valves | contains([$next]) | not)
        | $leaf
        | .accumulated_pressure += $input[$next].rate * (.time + $distances[$next][$leaf.head])
        | .time += $distances[$next][$leaf.head] + 1
        | .total_rate += $input[$next].rate
        | .head = $next
        | .all_valves += [$next]
        | .all_valves |= sort
      )
      | map(select(.time + $distances.AA[.head] < $total_time))
      | group_by({head, all_valves})
      | map(max_by(.accumulated_pressure + (.total_rate * ($total_time - .time))))
      | . as $foo | map(.time) | count_by_key(.) | debug | $foo
    ]
  )
| map(select(length > 0))
| .[-3:]
| flatten
| . as $foo | length | debug | $foo
| map(
    .time += $distances.AA[.head]
    | select(.time <= $total_time)
    | .total_pressure = .accumulated_pressure + .total_rate * ($total_time - .time)
  )
| . as $foo | length | debug | $foo
| [., .] | [combinations]
| . as $foo | length | debug | $foo
| map(select(.[0].all_valves - (.[0].all_valves - .[1].all_valves) | length == 0)) # disjoint sets
| max_by(.[0].total_pressure + .[1].total_pressure)
| .[0].total_pressure + .[1].total_pressure
