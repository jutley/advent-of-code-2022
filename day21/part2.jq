include "lib";

def nest_monkeys($monkey; $monkeys):
  if $monkeys[$monkey] | type == "number" or . == "var" then $monkeys[$monkey]
  else
    {
      op: $monkeys[$monkey].op,
      left: nest_monkeys($monkeys[$monkey].left; $monkeys),
      right: nest_monkeys($monkeys[$monkey].right; $monkeys)
    }
  end
;

def determine_var($tree; $value):
  if $tree == "var" then $value
  else
    [$tree, $value] | $tree
    | ((.left, .right) | numbers) as $num
    | (if .left == $num then .right else .left end) as $subtree
    | if .op == "+" then determine_var($subtree; $value - $num)
      elif .op == "-" and .left == $num then determine_var($subtree; $num - $value)
      elif .op == "-" and .right == $num then determine_var($subtree; $value + $num)
      elif .op == "*" then determine_var($subtree; $value / $num)
      elif .op == "/" and .left == $num then determine_var($subtree; $num / $value)
      elif .op == "/" and .right == $num then determine_var($subtree; $value * $num)
      elif .op == "=" then determine_var($subtree; $num)
      else error("unknown op: \(.op)")
      end
  end
;

map(
  capture("(?<monkey>\\w+): ((?<number>\\d+)|(?<left>\\w+) (?<op>.) (?<right>\\w+))")
  | .number |= if . then tonumber else . end
  | {(.monkey): (.number // del(.monkey))}
)
| add
| .root.op = "="
| .humn = "var"
| . as $monkeys
| nest_monkeys("root"; $monkeys)
| walk(
    if type == "number" or type == "string" then .
    elif (.left | type != "number") or (.right | type != "number") then .
    else
      if .op == "+" then .left + .right
      elif .op == "-" then .left - .right
      elif .op == "*" then .left * .right
      elif .op == "/" then .left / .right
      elif .op == "=" then .left == .right
      else error("unknown operation \(.op)")
      end
    end
  )
| determine_var(.; null)


