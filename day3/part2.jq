def ascii(char): char | explode[0];

def intersection(set1; set2): set1 - (set1 - set2);

def item_priority(item): if ("a" <= item and item <= "z") then (ascii(item) - ascii("a") + 1) else (ascii(item) - ascii("A") + 27) end;

def group_rucksacks_per_elf_group: to_entries | group_by(.key / 3 | floor) | map(map(.value));

def all_items: [range(26) + (ascii("a"), ascii("A"))] | map([.] | implode);

group_rucksacks_per_elf_group | map(
  map(split("") | sort | unique) |
  reduce .[] as $elf (all_items; intersection(.; $elf)) |
  map(item_priority(.)) |
  add
) | add
