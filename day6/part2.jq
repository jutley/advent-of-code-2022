# include "lib";

{
  remaining: (.[0] | split("")),
  currentIndex: 0
} |
until(.remaining[:14] | sort | unique | (length == 14); {
  remaining: .remaining[1:],
  currentIndex: (.currentIndex + 1)
}) |
.currentIndex + 14