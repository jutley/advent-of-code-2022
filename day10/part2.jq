include "lib";

map(
  capture("(?<instruction>noop|addx)( (?<value>.*))?")
  | .value |= (select(.) | tonumber)
  | if .instruction == "addx" then 0, .value else 0 end
)
| reduce .[] as $delta ([1]; . + [last + $delta])
| . as $cycle_values
| [range(240) | "."] as $crt
| reduce to_entries[] as $cycle ($crt;
    ($cycle.key) as $crt_idx
    | $cycle.value as $sprite_center
    | if ([$crt_idx % 40] | inside([range(3) - 1 + $sprite_center]))
      then .[$crt_idx] = "#"
      else .
      end
)
| to_entries
| group_by(.key / 40 | floor)
| map(map(.value) | join("")) | join("\n")
