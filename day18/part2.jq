include "lib";

def parse: map(split(",") | map(tonumber) as [$x, $y, $z] | {$x, $y, $z});

def add_vectors($v): [., $v] | transpose | map(add);

def flip_face($face): $face | if endswith("+") then sub("\\+"; "-") else sub("-"; "+") end;

def relative_cube_adjacent_to_face($face):
  {
    "x-": [-1,  0,  0],
    "x+": [ 1,  0,  0],
    "y-": [ 0, -1,  0],
    "y+": [ 0,  1,  0],
    "z-": [ 0,  0, -1],
    "z+": [ 0,  0,  1]
  }[face]
;

def cube_adjacent_to_face($x; $y; $z; $face):
  relative_cube_adjacent_to_face($face) | add_vectors([$x, $y, $z]);

def set_cube_face_visibility:
  . as $cube_face_visibility | to_entries | map(
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

def generate_cube_face_visibility($input):
  $input
  | (map(.[]) | max + 1) as $max_idx
  | [range($max_idx) | false] as $empty_segment
  | ($empty_segment | map($empty_segment | map($empty_segment))) as $space
  | ([["x", "y", "z"], ["+", "-"]] | [combinations | join("") | {(.): true}] | add) as $default_face_visibility
  | reduce .[] as $cube ($space; .[$cube.x][$cube.y][$cube.z] = $default_face_visibility)
  | set_cube_face_visibility
;

def cube_exists_at($x; $y; $z; $cube_face_visibility):
  [$x, $y, $z]
  | min >= 0
    and max < ($cube_face_visibility | length)
    and $cube_face_visibility[$x][$y][$z]
;

def face_exists_and_is_uncovered($x; $y; $z; $face; $cube_face_visibility):
  cube_exists_at($x; $y; $z; $cube_face_visibility)
    and (cube_adjacent_to_face($x; $y; $z; $face)
      | cube_exists_at(.[0]; .[1]; .[2]; $cube_face_visibility) == false
    )
;

def surrounding_cubes_with_face_offset($x; $y; $z; $dimension_idx; $face_offset):
  [[-1, 0], [1, 0], [0, -1], [0, 1]] | map(.[$dimension_idx:$dimension_idx] = [$face_offset]);

def planar_edges_for_face($face_context; $cube_face_visibility):
  $face_context as {$face, $adj_cubes}
  | $adj_cubes
  | map(
      . + [$face]
      | select(face_exists_and_is_uncovered(.[0]; .[1]; .[2]; .[3]; $cube_face_visibility))
      | tojson
    )
;

def corner_edges_for_face($face_context; $cube_face_visibility):
  $face_context as {$face, $adj_faces, $adj_cubes}
  | $adj_cubes | map(add_vectors(relative_cube_adjacent_to_face($face))) as $cubes
  | $adj_faces | map(flip_face(.)) as $faces
  | [$cubes, $faces] | transpose | map(
      .[0] + [.[1]]
      | select(face_exists_and_is_uncovered(.[0]; .[1]; .[2]; .[3]; $cube_face_visibility))
      | tojson
    )
;

def self_edges_for_face($face_context; $cube_face_visibility):
  $face_context as {$x, $y, $z, $face, $adj_cubes, $adj_faces}
  | $adj_cubes | map(add_vectors(relative_cube_adjacent_to_face($face)))
  | [., $adj_faces] | transpose | map(
      select(cube_exists_at(.[0][0]; .[0][1]; .[0][2]; $cube_face_visibility) | not)
      | [$x, $y, $z, .[1]]
      | select(face_exists_and_is_uncovered(.[0]; .[1]; .[2]; .[3]; $cube_face_visibility))
      | tojson
    )
;

def edges_for_face($x; $y; $z; $face; $cube_face_visibility):
  if face_exists_and_is_uncovered($x; $y; $z; $face; $cube_face_visibility) | not
  then []
  else
    $face | split("") as [$dimension, $_]
    | ["x", "y", "z"] | index($dimension) as $dimension_idx
    | ["x", "y", "z"] | del(.[$dimension_idx]) | [.,.] | transpose | flatten as $dim_overlay
    | ["+", "-"] | (. + .) as $dir_overlay
    | [$dim_overlay, $dir_overlay] | transpose | map(add) as $adj_faces
    | $adj_faces | map(cube_adjacent_to_face($x; $y; $z; .)) as $adj_cubes

    | {$x, $y, $z, $face, $adj_faces, $adj_cubes} as $face_context

    | planar_edges_for_face($face_context; $cube_face_visibility) as $planar_edges
    | corner_edges_for_face($face_context; $cube_face_visibility) as $corner_edges
    | self_edges_for_face($face_context; $cube_face_visibility) as $self_edges
    | $planar_edges + $corner_edges + $self_edges
  end
;

def generate_graph($cube_face_visibility):
  $cube_face_visibility
  | to_entries | map(
      .key as $x | .value | to_entries | map(
        .key as $y | .value | to_entries | map(
          .key as $z | .value
          | if . then with_entries(
              .key as $face
              | cube_adjacent_to_face($x; $y; $z; $face) as [$nx, $ny, $nz]
              | .value |= if . then edges_for_face($x; $y; $z; $face; $cube_face_visibility) else . end
            ) else . end
          | select(.)
          | with_entries(select(. and length > 0) | .key=([$x, $y, $z, .key] | tojson))
    )))
  | flatten | add | map_values(select(. and length > 0))
;

def get_initial_edge($input):
  $input | group_by({y, z}) | first | sort_by(.x) | first | [.x, .y, .z, "x-"] | tojson;

def accessible_nodes_in_graph($graph; $starting_node):
  {
    visited_nodes: [],
    seen_nodes: [$starting_node],
    queue: [$starting_node]
  }
  | until(.queue | length == 0;
      .queue[0] as $node
      | .visited_nodes += [$node]
      | del(.queue[0])
      | .seen_nodes as $seen_nodes
      | .queue += ($graph[$node] | map(select([.] | inside($seen_nodes) | not)))
      | .seen_nodes |= (. + $graph[$node] | sort | unique)
    )
  | .visited_nodes | length
;

parse as $input
| generate_cube_face_visibility($input) as $cube_face_visibility
| generate_graph($cube_face_visibility) as $graph
| get_initial_edge($input) as $initial_face
| accessible_nodes_in_graph($graph; $initial_face)
