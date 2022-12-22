include "lib";

def parse:
  map(
    split(": ")
    | (.[0] | split(" ")[1] | tonumber) as $blueprint_number
    | .[1] | split(".") | map(
        ltrimstr(" ")
        | select(length > 0)
        | capture("Each (?<robot>.*) robot costs (?<costs>.*)")
        | .costs |= (
            split(" and ")
            | map(capture("(?<quantity>.*) (?<resource>.*)") | {(.resource): (.quantity | tonumber)})
            | add
          )
        | {(.robot): .costs}
      )
    | {costs: add, blueprint_number: $blueprint_number}
  )
;

def harvest:
  . as $root
  | .resources |= with_entries(.value += $root.rates[.key])
  | .minute += 1
;

def buy($resource):
  . as $root
  | reduce (.costs[$resource] | to_entries[]) as $cost (.;
      .resources[$cost.key] -= $cost.value
    )
  | .rates[$resource] += 1
;

def process_option($wait_time; $resource):
  . as $root
  # | ([range(.minute) | " "] | join("") + "wait \($wait_time) for \($resource) (minute \($root.minute))") | debug | $root
  | reduce range($wait_time) as $_ (.; harvest)
  | buy($resource)
  | .options += [$wait_time, $resource]
;

def resource_will_last_for_duration_at_rate($resource; $minutes; $rate):
  (.resources[$resource] - $minutes * ($rate - .rates[$resource])) >= 0;

def geode_robots_at_current_rates:
  (.total_minutes - .minute - 1) as $days_for_buying
  | [
      ((.resources["ore"] + .rates["ore"] * $days_for_buying) / .costs.geode.ore | floor),
      ((.resources["obsidian"] + .rates["obsidian"] * $days_for_buying) / .costs.geode.obsidian | floor)
    ]
  | min
;

def max_geodes_with_only_new_geode_robots:
  . as $root
  | reduce range($root.total_minutes - $root.minute) as $_ ($root;
    if .resources.ore >= .costs.geode.ore and .resources.obsidian >= .costs.geode.obsidian
    then process_option(1; "geode")
    else harvest
    end
  )
  | .resources.geode
;

def determine_options($max_rates):
  if .minute == .total_minutes then {}
  else
    . as $root
    | ["ore", "clay", "obsidian", "geode"] as $all_resources
    | (.total_minutes - 1 - .minute) as $days_for_buying
    | (if geode_robots_at_current_rates >= $days_for_buying - 2
      then ["geode"]
      else
        if $root.rates.geode > 0 then ["geode", "obsidian"]
        elif $root.rates.obsidian > 0 then ["geode", "obsidian", "clay"]
        elif $root.rates.clay > 0 then ["obsidian", "clay", "ore"]
        else ["clay", "ore"]
        end
        | map(select(. as $resource |
            $resource == "geode"
            or ($root | resource_will_last_for_duration_at_rate($resource; (.total_minutes - .minute); $max_rates[$resource])) < 0
          ))
      end) as $resources_to_consider

    | (.rates | to_entries | map(select(.value > 0) | .key)) as $harvesting_resources

    | ($resources_to_consider | map(
        . as $resource
        | $root.costs[.]
        | select(keys | inside($harvesting_resources))
        | (to_entries | map(
            (.value - $root.resources[.key]) / $root.rates[.key] | ceil + 1
          ) | . + [1] | max) as $wait_time
        | select(($wait_time + $root.minute) < $root.total_minutes)
        | {($resource): $wait_time}
      ) | add // {}) as $wait_times

    | $wait_times
  end
;

def get_unopinionated_options($max_rates):
  if .minute >= .total_minutes - 1 then {}
  else
    . as $root
    | (.total_minutes - 1 - .minute) as $days_for_buying
    | (if geode_robots_at_current_rates >= $days_for_buying - 1
      then ["geode"]
      else
        if $root.rates.obsidian == 0 then ["obsidian", "clay", "ore"]
        elif $root.rates.clay == 0 then ["clay", "ore"]
        else ["geode", "obsidian", "clay", "ore"]
        end
          | map(select(. as $resource |
            $resource == "geode"
            or ($root | resource_will_last_for_duration_at_rate($resource; (.total_minutes - .minute); $max_rates[$resource]) | not)
          ))
      end) as $resources_to_consider

    | (.rates | to_entries | map(select(.value > 0) | .key)) as $harvesting_resources

    | ($resources_to_consider | map(
        . as $resource
        | $root.costs[.]
        | select(keys | inside($harvesting_resources))
        | (to_entries | map(
            (.value - $root.resources[.key]) / $root.rates[.key] | ceil + 1
          ) | . + [1] | max) as $wait_time
        | select(($wait_time + $root.minute) < $root.total_minutes)
        | {($resource): $wait_time}
      ) | add // {}) as $wait_times

    | $wait_times
  end
;

def get_all_possibilties_after_n_steps($n; $max_rates):
  if .minute == .total_minutes or $n == 0 then [.n = $n]
  else
    . as $root
    | get_unopinionated_options($max_rates)
    | if length == 0 then
        [$root | .n = $n]
      else
        to_entries
        | map(
            . as {key: $resource, value: $wait_time}
            | $root
            | process_option($wait_time; $resource)
            | get_all_possibilties_after_n_steps($n - 1; $max_rates)
          )
        | flatten
      end
  end
;

# filter resources where buying a different resource can lead to buying the original resources at the same minute of sooner

def simulate_options_one_extra_step($options; $max_rates):
  . as $root
  | $options | with_entries(select(
      . as {key: $resource_under_consideration, value: $original_wait_time}
      | $root.costs[$resource_under_consideration] | to_entries | any(
          .key as $intermediate_resource
          | $options[$intermediate_resource] as $intermediate_wait_time
          | $intermediate_wait_time != null and (
              $root
              | process_option($intermediate_wait_time; $intermediate_resource)
              | determine_options($max_rates) as $new_options
              | $new_options[$resource_under_consideration] != null
                and $intermediate_wait_time + $new_options[$resource_under_consideration] < $original_wait_time
            )
        )
      | not
  ))
;

def get_recommended_option_via_partial_simulation($max_rates):
  (.options | length / 2) as $steps_so_far
  | get_all_possibilties_after_n_steps(10; $max_rates)
  | max_by(max_geodes_with_only_new_geode_robots)
  | .options[$steps_so_far * 2:] | debug
  | {(.[1]): .[0]}
;

def simulate($max_rates):
  if .minute == .total_minutes then .
  else
    . as $root
    | simulate_options_one_extra_step(determine_options($max_rates); $max_rates)
    # | determine_options($max_rates)
    | if ($root.rates.geode > 0 and .geode == null) then
        reduce range($root.total_minutes - $root.minute) as $_ ($root; harvest)
        | .total_scenarios = 1
      else
        to_entries | map(
          . as {key: $resource, value: $wait_time}
          | $root
          | process_option($wait_time; $resource)
          | simulate($max_rates)
        )
        | (map(.total_scenarios) | add) as $total_scenarios
        | max_by(.resources.geode)
        | .total_scenarios = $total_scenarios
      end
  end
;

parse[:3]
| map( # .)[0] |
    {
      minute: 0,
      total_minutes: 32,
      blueprint_number: .blueprint_number,
      costs: .costs,
      rates: {ore: 1, clay: 0, obsidian: 0, geode: 0},
      resources: {ore: 0, clay: 0, obsidian: 0, geode: 0},
      options: [],
      total_scenarios: 0
    }
    | . as $root | .blueprint_number | debug | $root
    | {
        ore: ([$root.costs.clay.ore, $root.costs.obsidian.ore, $root.costs.geode.ore] | max),
        clay: $root.costs.obsidian.clay,
        obsidian: $root.costs.geode.obsidian
      } as $max_rates
    | simulate($max_rates)

    # | until(.rates.ore == (.costs | del(.ore) | map(.ore) | min | 3);
    #     process_option(get_unopinionated_options($max_rates)["ore"]; "ore")
    #   )

    # | until(simulate_options_one_extra_step(get_unopinionated_options($max_rates); $max_rates).obsidian != null;
    #     process_option(get_unopinionated_options($max_rates)["clay"]; "clay")
    #   )
    # | debug | halt
    # | process_option(5; "ore")
    # | process_option(2; "clay")
    # | process_option(1; "clay")
    # | process_option(1; "clay")
    # | process_option(1; "clay")
    # | process_option(1; "clay")
    # | process_option(1; "clay")
    # | process_option(1; "clay")
    # | process_option(1; "obsidian")
    # | process_option(2; "obsidian")
    # | process_option(1; "obsidian")
    # | process_option(2; "obsidian")
    # | process_option(1; "geode")
    # | process_option(1; "obsidian")
    # | process_option(1; "geode")
    # | process_option(1; "geode")
    # | process_option(1; "geode")

    # | process_option(1; "clay")
    # | process_option(1; "geode")
    # | process_option(1; "geode")
    # | process_option(2; "geode")
    # | process_option(1; "geode")
    # | process_option(1; "geode")
    # | harvest

    # | process_option(3; "ore")
    # | process_option(2; "ore")
    # | process_option(1; "clay")
    # | process_option(1; "clay")
    # | process_option(1; "clay")
    # | process_option(1; "clay")
    # | process_option(1; "clay")
    # | process_option(1; "clay")
    # | process_option(1; "obsidian")
    # | process_option(1; "obsidian")
    # | process_option(1; "obsidian")
    # | process_option(1; "obsidian")
    # | process_option(1; "clay")
    # | process_option(1; "obsidian")
    # | process_option(1; "geode")
    # | process_option(1; "obsidian")
    # | process_option(1; "geode")
    # | process_option(1; "obsidian")
    # | process_option(1; "geode")
    # | process_option(1; "obsidian")
    # | process_option(1; "geode")
    # | process_option(1; "obsidian")
    # | process_option(1; "geode")
    # | process_option(1; "geode")
    # | process_option(1; "geode")
    # | process_option(2; "geode")
    # | process_option(1; "geode")
    # | harvest

    # | . as $root | get_unopinionated_options($max_rates) | debug | $root
    # | simulate_options_one_extra_step(get_unopinionated_options($max_rates); $max_rates)

    # | .rates

    # | . as $root | [.minute, .resources.geode] | debug | $root
    # | get_unopinionated_options($max_rates) | debug
    # | $root
    # | get_recommended_option_via_partial_simulation($max_rates)
    # | .cache = get_all_possibilties_after_n_steps(15; $max_rates)
    # | until(.minute == .total_minutes - 1;
    #     . as $root
    #     | (.options | length / 2) as $steps_so_far
    #     | .cache | max_by(max_geodes_with_only_new_geode_robots)
    #     | .options[$steps_so_far * 2:][:2]
    #     | if length == 2 then
    #         . as [$wait_time, $resource]
    #         | [., $root.minute]
    #         | debug
    #         | $root
    #         | process_option($wait_time; $resource)
    #         | . as $root
    #         # | debug
    #         | .cache |= (map(
    #             select(.options[:($steps_so_far + 1) * 2] == $root.options)
    #             | get_all_possibilties_after_n_steps(1; $max_rates)
    #           ) | flatten)
    #       else
    #         $root | get_unopinionated_options($max_rates) | debug | $root | harvest
    #       end
    #   )
    # | harvest

    # | .resources.geode



    # | process_option(2; "geode")
    # | process_option(1; "geode")
    # | process_option(2; "geode")
    # | process_option(1; "geode")
    # | max_geodes_with_only_new_geode_robots

    # | get_unopinionated_options($max_rates)
    # | simulate($max_rates)
    # | . as $root | determine_options($max_rates) | debug | $root
    # | simulate_options_one_extra_step(determine_options($max_rates); $max_rates)
  )
| map(.resources.geode)
| debug
| reduce .[] as $i (1; . * $i)
