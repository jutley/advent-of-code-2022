include "lib";

# create tree from command line output
reduce .[] as $line ({tree: {}, pwd: []};
  . as $acc |
  if ($line | startswith("$ ")) then (
    $line | capture("\\$ (?<command>(cd|ls))( (?<dir>.*))?") |
    if .command == "cd" and .dir == "/" then (
      $acc | .pwd = []
    ) elif .command == "cd" and .dir == ".." then (
      $acc | del(.pwd[-1])
    ) elif .command == "cd" then (
      .dir as $dir |
      $acc |
      .pwd += [$dir]
    ) else (
      $acc # do nothing for ls command, the work comes from the output
    ) end
  ) else (
    if ($acc.tree | getpath($acc.pwd) == null) then (
      $acc.tree | setpath($acc.pwd; {})
    ) else (
      $acc
    ) end |
    $line | capture("(?<size>\\w+) (?<path>.*)") as $ls_out |
    $acc |
    if $ls_out.size == "dir" then (
      .tree |= setpath($acc.pwd + [$ls_out.path]; {})
    ) else (
      .tree |= setpath($acc.pwd + [$ls_out.path]; ($ls_out.size | tonumber))
    ) end
  ) end
) |

# get flattened structure for each file, with every directory the file is within
.tree | [tostream] | map(
  select(length == 2) |
  {
    dirs: (.[0][:-1] | reduce .[] as $subdir ([[]]; . + [.[-1] + [$subdir]]) | map(join("."))),
    file: .[0][-1],
    size: .[1]
  }
) |

# get total size for each dir
map({file, size} + {dir: .dirs[]}) |
group_by_key(.dir) |
map_values(map(.size) | add) |

# final processing
(70000000 - .[""]) as $free_space |
(30000000 - $free_space) as $space_to_free |
map_values(select(. >= $space_to_free)) |
to_entries | sort_by(.value)[0].value
