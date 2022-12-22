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

def determine_options($max_rates):
  if .minute == .total_minutes then {}
  else
    . as $root
    | (.costs | to_entries | map(
        select(.value | to_entries | all($root.resources[.key] >= .value))
        | select($root.rates[.key] < $max_rates[.key] or .key == "geode")
        | .key)
      ) as $buyable_resources
    | (.rates | to_entries | map(select(.value > 0) | .key)) as $harvesting_resources
    | (.costs | with_entries(
        select([.key] | inside($buyable_resources) | not)
        | select(.value | keys | inside($harvesting_resources))
        | .value |= (to_entries | map(
            (.value - $root.resources[.key]) / $root.rates[.key] | ceil + 1
          ) | max)
        | select((.value + $root.minute) <= $root.total_minutes)
        | select($root.rates[.key] < $max_rates[.key] or .key == "geode")
      )) as $wait_times
    | ($buyable_resources | map({(.): 1}) | add) + $wait_times
    # | if .geode == 1 then {geode} else . end
    # | if $root.rates.geode > 0 and .geode == null then [] else . end
    # | if ($root.options | length > 0 and last != "ore") then del(.ore) else . end
    | if $root.rates.obsidian >= $root.costs.geode.obsidian and $root.rates.ore >= $root.costs.geode.ore
      then {geode}
      # elif $root.rates.obsidian >= $root.costs.geode.obsidian and .ore
      # then {ore}
      # elif $root.rates.ore >= $root.costs.geode.ore and .obsidian
      # then {obsidian}
      else .
      end
  end
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

def simulate($max_rates):
  if .minute == .total_minutes then .
  else
    . as $root
    | determine_options($max_rates)
    | if ($root.rates.geode > 0 and .geode == null) then
        reduce range($root.total_minutes - $root.minute) as $_ ($root; harvest)
      else
        to_entries | map(
          . as {key: $resource, value: $wait_time}
          | $root
          | process_option($wait_time; $resource)
          | simulate($max_rates)
        )
        | max_by(.resources.geode)
      end
  end
;

parse
| map(
    {
      minute: 0,
      total_minutes: 24,
      blueprint_number: .blueprint_number,
      costs: .costs,
      rates: {ore: 1, clay: 0, obsidian: 0, geode: 0},
      resources: {ore: 0, clay: 0, obsidian: 0, geode: 0},
      options: []
    }
    | . as $root | .blueprint_number | debug | $root
    | (.costs | map(to_entries[]) | group_by_key(.key) | map_values(map(.value) | max)) as $max_rates
    | simulate($max_rates)
  )
| map(.resources.geode * .blueprint_number)
| add

  # | .[0]
  # | {
  #     minute: 0,
  #     total_minutes: 24,
  #     blueprint_number: .blueprint_number,
  #     costs: .costs,
  #     rates: {ore: 1, clay: 0, obsidian: 0, geode: 0},
  #     resources: {ore: 0, clay: 0, obsidian: 0, geode: 0},
  #     options: []
  #   }
  # | (.costs | map(to_entries[]) | group_by_key(.key) | map_values(map(.value) | max)) as $max_rates
  # # | process_option(3; "ore")
  # # | process_option(2; "ore")
  # # | process_option(1; "clay")
  # # | process_option(1; "clay")
  # # | process_option(1; "clay")
  # # | process_option(1; "clay")
  # # | process_option(1; "clay")
  # # | process_option(1; "obsidian")
  # # | process_option(2; "obsidian")
  # # | process_option(1; "obsidian")
  # # | process_option(2; "obsidian")
  # # | process_option(1; "obsidian")
  # # | process_option(1; "geode")
  # # | process_option(1; "obsidian")
  # # | process_option(1; "geode")
  # # | process_option(2; "geode")
  # # | process_option(2; "geode")

  # # | process_option(2; "clay")
  # # | process_option(2; "clay")
  # # | process_option(1; "clay")
  # # | process_option(2; "clay")
  # # | process_option(1; "obsidian")
  # # | process_option(2; "obsidian")
  # # | process_option(2; "obsidian")
  # # | process_option(1; "geode")
  # # | process_option(1; "obsidian")
  # # | process_option(2; "obsidian")
  # # | process_option(2; "geode")
  # # | process_option(3; "geode")
  # # | {options: determine_options($max_rates), resources, rates}
  # | simulate($max_rates)
