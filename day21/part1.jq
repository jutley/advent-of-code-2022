include "lib";

map(
  capture("(?<monkey>\\w+): ((?<number>\\d+)|(?<left_monkey>\\w+) (?<op>.) (?<right_monkey>\\w+))")
  | .number |= if . then tonumber else . end
  | {(.monkey): (.number // del(.monkey))}
)
| add
| until(.root | type == "number";
    . as $monkeys
    | map_values(
        if type == "number" then .
        else
          if ($monkeys[.left_monkey] | type == "number") and ($monkeys[.right_monkey] | type == "number")
          then
            if .op == "+" then   $monkeys[.left_monkey] + $monkeys[.right_monkey]
            elif .op == "-" then $monkeys[.left_monkey] - $monkeys[.right_monkey]
            elif .op == "*" then $monkeys[.left_monkey] * $monkeys[.right_monkey]
            elif .op == "/" then $monkeys[.left_monkey] / $monkeys[.right_monkey]
            else error("unknown operation \(.op)")
            end
          else .
          end
        end
      )
  )
| .root
