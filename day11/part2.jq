include "lib";

def update_worry($monkey; $max_worry):
  $monkey
  | .items[0] |= (
    if $monkey.operand == "old"
    then . * .
    elif $monkey.operator == "*"
    then . * $monkey.operand
    else . + $monkey.operand
    end
    | . % $max_worry
  )
;

def pass_item($current_monkey_idx):
  .[$current_monkey_idx] as $current_monkey
  | if ($current_monkey.items[0] | (. % $current_monkey.divisor == 0))
    then .[$current_monkey.true_idx].items += [$current_monkey.items[0]]
    else .[$current_monkey.false_idx].items += [$current_monkey.items[0]]
    end
  | del(.[$current_monkey_idx].items[0])
;

join("\n")
| split("\n\n")
| map(
    capture(".*Starting items: (?<items>.*)\n.*= old (?<operator>.) (?<operand>.+)\n.* by (?<divisor>.*)\n.*monkey (?<true_idx>.)\n.*monkey (?<false_idx>.)")
    | .items |= (split(", ") | map(tonumber))
    | .divisor |= tonumber
    | .true_idx |= tonumber
    | .false_idx |= tonumber
    | .operand |= if . == "old" then . else tonumber end
    | .total_inspections = 0
)
| (reduce .[].divisor as $n (1; . * $n)) as $max_worry
| reduce range(10000) as $round (.;
    reduce range(length) as $current_monkey_idx (.;
        reduce .[$current_monkey_idx].items[] as $_ (.;
            .[$current_monkey_idx].total_inspections += 1
            | .[$current_monkey_idx] |= update_worry(.; $max_worry)
            | pass_item($current_monkey_idx)
        )
    )
)
| map(.total_inspections)
| sort
| .[-2:]
| .[0] * .[1]
