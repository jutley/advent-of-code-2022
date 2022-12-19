include "lib";

def parse: map(split(",") | map(tonumber) as [$x, $y, $z] | {$x, $y, $z});

def cube_adjacent_to_face($x; $y; $z; $face):
  {
    "x-": [-1,  0,  0],
    "x+": [ 1,  0,  0],
    "y-": [ 0, -1,  0],
    "y+": [ 0,  1,  0],
    "z-": [ 0,  0, -1],
    "z+": [ 0,  0,  1]
  }[face]
  | [[$x, $y, $z], .]
  | transpose | map(add)
;

def set_cube_face_visibility($cube_face_visibility):
  to_entries | map(
    .key as $x | .value | to_entries | map(
      .key as $y | .value | to_entries | map(
        .key as $z | .value
        | if . then with_entries(
            .key as $face
            | cube_adjacent_to_face($x; $y; $z; $face) as [$nx, $ny, $nz]
            | .value = (
                [$nx, $ny, $nz]
                | min < 0
                  or max >= ($cube_face_visibility | length)
                  or $cube_face_visibility[$nx][$ny][$nz] == false
              )
          ) else . end
  )))
;

def edges_for_face($x; $y; $z; $face; $cube_face_visibility):
  $face | split("") as [$dim, $dir_sign]
  | {"+": 1, "-": -1}[$dir_sign] as $dir_num
  | [[-1, 0], [1, 0], [0, -1], [0, 1]] as $start
  | ["x", "y", "z"] | index($dim) as $i

  | $start | map(.[$i:$i] = [0] | . + [$face]) as $first_part

  | $start | map(.[$i:$i] = [$dir_num]) as $second_part_cube
  | ["x", "y", "z"] | del(.[$i]) | [.,.] | transpose | flatten as $dim_overlay
  | ["+", "-"] | (. + .) as $dir_overlay
  | [$dim_overlay, $dir_overlay] | transpose | map(add) as $face_overlay
  | [$second_part_cube, $face_overlay] | transpose | map(.[0] + [.[1]]) as $second_part

  # TODO these should only be included if there isn't a cube kitty corner
  | ($face_overlay | map([0, 0, 0, .]))
  | map(select(last as $adj_face |
      [$face, $adj_face] | map({
        "x-": [-1, 0, 0], "x+": [1, 0, 0],
        "y-": [0, -1, 0], "y+": [0, 1, 0],
        "z-": [0, 0, -1], "z+": [0, 0, 1]
      }[.]) | transpose | map(add)
      | [., [$x, $y, $z]] | transpose | map(add)
      | min < 0 or max >= ($cube_face_visibility | length)
        or $cube_face_visibility[.[0]][.[1]][.[2]] == false
    )) as $third_part

  | $first_part + $second_part + $third_part

  | map(.[:3] |= ([., [$x, $y, $z]] | transpose | map(add)))
  | map(
      . as [$nx, $ny, $nz, $nf]
      | select((.[:3] | min) >= 0)
      | select((.[:3] | max) < ($cube_face_visibility | length))
      | select($cube_face_visibility[$nx][$ny][$nz] and $cube_face_visibility[$nx][$ny][$nz][$nf])
    )
  | map(tojson)
;

parse
| . as $input
| [range(map(.[]) | max + 1) | false] as $empty_segment
| ($empty_segment | map($empty_segment | map($empty_segment))) as $space
| . as $tmp | "space" | debug | $tmp
| ([["x", "y", "z"], ["+", "-"]] | [combinations | join("") | {(.): true}] | add) as $default_face_visible
| reduce .[] as $cube ($space; .[$cube.x][$cube.y][$cube.z] = $default_face_visible)
| . as $initial_cube_face_visibility
| set_cube_face_visibility($initial_cube_face_visibility)
| . as $tmp | "face visibility" | debug | $tmp
| . as $cube_face_visibility
| to_entries | map(
    .key as $x | .value | to_entries | map(
      .key as $y | .value | to_entries | map(
        .key as $z | .value
        | if . then with_entries(
            .key as $face
            | cube_adjacent_to_face($x; $y; $z; $face) as [$nx, $ny, $nz]
            | .value |= if . then edges_for_face($x; $y; $z; $face; $cube_face_visibility) else . end
          ) else . end
  )))
| . as $tmp | "edges" | debug | $tmp

| to_entries | map(
    .key as $x | .value | to_entries | map(
      .key as $y | .value | to_entries | map(
        .key as $z | .value
        | select(.)
        | with_entries(select(. and length > 0) | .key=([$x, $y, $z, .key] | tojson))
  )))
| flatten | add | map_values(select(. and length > 0))
| . as $tmp | "flattened edges" | debug | $tmp

| . as $graph
| $input | group_by({y, z}) | first | sort_by(.x) | first | [.x, .y, .z, "x-"] | tojson
| . as $initial_face

| {
    visited_faces: [],
    seen_faces: [$initial_face],
    queue: [$initial_face]
  }
| until(.queue | length == 0;
    .queue[0] as $face
    | . as $tmp | .queue | length | debug | $tmp
    | .visited_faces += [$face]
    | del(.queue[0])
    | .seen_faces as $seen_faces
    | .queue += ($graph[$face] | map(select([.] | inside($seen_faces) | not)))
    | .seen_faces |= (. + $graph[$face] | sort | unique)
  )
| .visited_faces | length


# reduce $graph[.][] as $adj_face ([$initial_face];)

# edges_for_face(0; 0; 0; "x+"; {})
