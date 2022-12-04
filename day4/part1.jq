include "lib";

map(
  split(",") |
  map(
    split("-") |
    map(tonumber) |
    [range(.[0]; .[1] + 1)]
  ) |
  . as $pair |
  select(
    ($pair[0] | contains($pair[1]))
    or
    ($pair[1] | contains ($pair[0]))
  )
) | length
