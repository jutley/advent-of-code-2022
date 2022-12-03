def ascii(char): char | explode[0];

def item_priority(item): if ("a" <= item and item <= "z") then (ascii(item) - ascii("a") + 1) else (ascii(item) - ascii("A") + 27) end;

def split_rucksack(sack): [sack[:(sack | length / 2)], sack[(sack | length / 2):]];

def common_items_across_compartments(sack): split_rucksack(sack) | map(split("") | sort | unique) | .[0] - (.[0] - .[1]);

map(
  common_items_across_compartments(.) |
  map(item_priority(.))
) |
flatten | add
