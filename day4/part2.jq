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
    intersection($pair[0]; $pair[1]) |
    length > 0
  )
) | length
