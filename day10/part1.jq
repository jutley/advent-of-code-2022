include "lib";

map(
  capture("(?<instruction>noop|addx)( (?<value>.*))?")
  | .value |= (select(.) | tonumber)
  | if .instruction == "addx" then 0, .value else 0 end
)
| reduce .[] as $delta ([1]; . + [last + $delta])
| . as $cycle_values
| [range(((length - 20) / 40) | floor + 1)]
| map(20 + 40 * .)
| map(. * $cycle_values[. - 1])
| add
