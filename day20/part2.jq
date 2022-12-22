include "lib";

map(tonumber * 811589153)
| length as $len
| to_entries # if there are dupes, we can differentiate them
| reduce range(10) as $_ (.;
    reduce range(length) as $original_index (.;
      (to_entries | map(select(.value.key == $original_index) | .key)[0]) as $current_index
      | (.[$current_index]) as $original_entry
      | (if $original_entry.value >= 0
        then ($current_index + $original_entry.value) % ($len - 1)
        else -((-$current_index - $original_entry.value) % ($len - 1))
        end) as $new_index
      | . as $x | [$original_entry, $current_index, $new_index] | debug | $x
      | del(.[$current_index])
      | .[$new_index:$new_index] = [$original_entry]
    )
  )
| map(.value)
# | . as $final_values
# | index(0) as $index_for_zero
# | [1000, 2000, 3000] | map((. + $index_for_zero) % $len | $final_values[.])
# | add
