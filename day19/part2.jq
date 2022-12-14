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
  | if $resource == "geode"
    then .resources.geode += .total_minutes - .minute
    else .rates[$resource] += 1
    end
;

def process_option($wait_time; $resource):
  . as $root
  | reduce range($wait_time) as $_ (.; harvest)
  | buy($resource)
  | .options += [$wait_time, $resource]
;

def geodes_from_robots_purchased_in_all_final_n_minutes($n): $n * ($n / 2 - 0.5);

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

def determine_options($max_rates):
  if .minute == .total_minutes then {}
  else
    . as $root
    | ["ore", "clay", "obsidian", "geode"] as $all_resources
    | (.total_minutes - 1 - .minute) as $days_for_buying
    | (if geode_robots_at_current_rates >= $days_for_buying - 1
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

def upper_bound_for_geodes:
  .resources.geode + geodes_from_robots_purchased_in_all_final_n_minutes(.total_minutes - .minute);

def simulate($max_rates; $best_scenario_so_far):
  if .minute == .total_minutes then {best_scenario_so_far: ., completed_scenarios: 1, abandoned_scenarioes: 0}
  elif upper_bound_for_geodes <= $best_scenario_so_far.resources.geode then {best_scenario_so_far: null, completed_scenarios: 0, abandoned_scenarioes: 1}
  else
    . as $root
    | get_unopinionated_options($max_rates)
    | if length == 0 then $root | harvest | simulate($max_rates; $best_scenario_so_far)
      else
        reduce to_entries[] as {key: $resource, value: $wait_time} ({$best_scenario_so_far, completed_scenarios: 0, abandoned_scenarioes: 0};
          . as $acc
          | $root
          | process_option($wait_time; $resource)
          | simulate($max_rates; $acc.best_scenario_so_far) as $simulation_result
          | $acc
          | .best_scenario_so_far =
              if $simulation_result.best_scenario_so_far.resources.geode > $acc.best_scenario_so_far.resources.geode
              then $simulation_result.best_scenario_so_far
              else $acc.best_scenario_so_far
              end
          | .completed_scenarios += $simulation_result.completed_scenarios
          | .abandoned_scenarioes += $simulation_result.abandoned_scenarioes
        )
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

    | simulate($max_rates; null)
    | . as $simulation
    | {completed_scenarios, abandoned_scenarioes} | debug
    | $simulation
  )
| map(.best_scenario_so_far.resources.geode)
| debug
| reduce .[] as $i (1; . * $i)
