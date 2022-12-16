include "lib";

def manhatten_distance($x1; $y1; $x2; $y2): ($x1 - $x2 | fabs) + ($y1 - $y2 | fabs);

def too_close_to_sensor($sensor_beacon; $x; $y):
  manhatten_distance($sensor_beacon.sensor_x; $sensor_beacon.sensor_y; $x; $y) <= $sensor_beacon.distance;

def max_x_within_sensor_range_for_y($sensor_beacon; $y): $sensor_beacon.sensor_x + $sensor_beacon.distance - ($sensor_beacon.sensor_y - $y | fabs);

def expand_possible_half_intersection:
  if ((first | floor) != first)
  then
    [(first | floor), (last | floor)],
    [(first | ceil ), (last | floor)],
    [(first | floor), (last | ceil )],
    [(first | ceil ), (last | ceil )]
  else .
  end
;

def point_is_on_line_segment($line_start; $line_end; $point):
  ($line_start[0] <= $point[0] and $point[0] <= $line_end[0])
  and (
    (($line_start[1] <= $point[1] and $point[1] <= $line_end[1]))
    or
    (($line_start[1] >= $point[1] and $point[1] >= $line_end[1]))
  )
;

def line_segment_intersection($this_line_start; $this_line_end; $that_line_start; $that_line_end):
  if ($this_line_start[1] > $this_line_end[1]) == ($that_line_start[1] > $that_line_end[1])
  then empty # parallel
  else
    (($this_line_end[1] - $this_line_start[1]) / ($this_line_end[0] - $this_line_start[0])) as $this_slope
    | ($this_line_start[1] - $this_slope * $this_line_start[0]) as $this_y_intercept
    | (($that_line_end[1] - $that_line_start[1]) / ($that_line_end[0] - $that_line_start[0])) as $that_slope
    | ($that_line_start[1] - $that_slope * $that_line_start[0]) as $that_y_intercept
    | (($that_y_intercept - $this_y_intercept) / (2 * $this_slope)) as $x
    | [$x, $this_slope * $x + $this_y_intercept] # intersection
    | expand_possible_half_intersection
    | select(point_is_on_line_segment($this_line_start; $this_line_end; .))
    | select(point_is_on_line_segment($that_line_start; $that_line_end; .))
  end
;

def corners_of_beacon_range($sensor_beacon): [
  [.sensor_x - .distance, .sensor_y],
  [.sensor_x, .sensor_y + .distance],
  [.sensor_x + .distance, .sensor_y],
  [.sensor_x, .sensor_y - .distance]
];

def line_segments_of_beacon_range($sensor_beacon):
  corners_of_beacon_range($sensor_beacon)
  | [
      [.[0], .[1]],
      [.[0], .[3]],
      [.[1], .[2]],
      [.[3], .[2]]
    ]
;

def get_intersections_for_sensors($sensors):
  $sensors
  | map(line_segments_of_beacon_range(.)[])
  | [., .] | [combinations] | map(line_segment_intersection(.[0][0]; .[0][1]; .[1][0]; .[1][1]))
  | sort | unique
;

map(
  capture("Sensor at x=(?<sensor_x>.*), y=(?<sensor_y>.*): closest beacon is at x=(?<beacon_x>.*), y=(?<beacon_y>.*)")
  | map_values(tonumber)
  | .distance = manhatten_distance(.sensor_x; .sensor_y; .beacon_x; .beacon_y)
)
| . as $sensor_beacon_matches
| 4000000 as $max

| {x: 0, y: 0, row_sensors: [], found_position: false}
| until(.found_position or .y > $max;
    . as $state
    | $sensor_beacon_matches
    | map(select(too_close_to_sensor(.; $state.x; $state.y)) | {
        sensor: .,
        max_x: max_x_within_sensor_range_for_y(.; $state.y)
      })
    | if length > 0
      then
        (max_by(.max_x).max_x) as $skip_through
        | (max_by(.max_x).sensor) as $sensor
        | $state
        | if $skip_through + 1 <= $max
          then .x = $skip_through + 1 | .row_sensors += [$sensor]
          else
            .x as $x | .y as $y
            | (
                get_intersections_for_sensors(.row_sensors)
                | map(.[1] | select(. > $y))
                | min + 1
            ) as $next_y
            | .x = 0 | .y = $next_y | .row_sensors = []
          end
      else $state | .found_position = true
      end
  )
| .x * $max + .y
