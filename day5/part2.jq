include "lib";

(to_entries[] | select(.value == "") | .key) as $empty_line_idx |
.[:$empty_line_idx - 1] as $raw_crate_input |
.[$empty_line_idx + 1:] as $raw_instructions |
(.[$empty_line_idx - 1] | split(" ") | map(select(length > 0)) | last | tonumber) as $stacks |

[range($stacks)] | map(
  . as $stack_idx |
  $raw_crate_input | reverse | map(
    .[$stack_idx * 4 + 1:$stack_idx * 4 + 2] |
    select(. != " ")
  )
) as $parsed_stacks |

$raw_instructions | map(
  capture("move (?<move_count>\\d+) from (?<start_stack>\\d+) to (?<end_stack>\\d+)") |
  map_values(tonumber) |
  .start_stack |= . - 1 |
  .end_stack |= . - 1
)
as $parsed_instructions |

reduce $parsed_instructions[] as $instruction ($parsed_stacks;
  (.[$instruction.start_stack][-$instruction.move_count:]) as $cargo |
  del(.[$instruction.start_stack][-$instruction.move_count:]) |
  .[$instruction.end_stack] += $cargo
) |

map(last) | join("")
