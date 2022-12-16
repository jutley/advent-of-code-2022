include "lib";

def manhatten_distance($x1; $y1; $x2; $y2): ($x1 - $x2 | fabs) + ($y1 - $y2 | fabs);

map(
  capture("Sensor at x=(?<sensor_x>.*), y=(?<sensor_y>.*): closest beacon is at x=(?<beacon_x>.*), y=(?<beacon_y>.*)")
  | map_values(tonumber)
  | .distance = manhatten_distance(.sensor_x; .sensor_y; .beacon_x; .beacon_y)
)
| 2000000 as $y
| map(select(.sensor_y - .distance <= $y and .sensor_y + .distance >= $y))
| . as $sensor_beacon_matches
| (map(select(.beacon_y == $y).beacon_x) | sort) as $beacon_x_if_at_y
| map(
    (.distance - (.sensor_y - $y | fabs)) as $reach
    | [range(.sensor_x - $reach; .sensor_x + $reach + 1)]
  )
| flatten
| sort | unique
| . as $foo | length | debug | $foo
| . - $beacon_x_if_at_y
| length
