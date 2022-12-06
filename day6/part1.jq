# include "lib";

{
  remaining: (.[0] | split("")),
  currentIndex: 0
} |
until(.remaining[:4] | sort | unique | (length == 4); {
  remaining: .remaining[1:],
  currentIndex: (.currentIndex + 1)
}) |
.currentIndex + 4