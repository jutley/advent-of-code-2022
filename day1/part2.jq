reduce .[] as $line (
  [[]];
  if ($line | length > 0)
  then
    .[-1] += [$line | tonumber]
  else
    . += [[]]
  end
) |
map(add) |
sort |
.[-3:] |
add
