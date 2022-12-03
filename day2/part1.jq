def letter_to_throw(letter):
  if ([letter] | inside(["A", "X"])) then "rock"
  elif ([letter] | inside(["B", "Y"])) then "paper"
  else "scissors"
  end
;

def points_for_outcome(that_player; this_player):
  if (
    (this_player == "rock" and that_player == "scissors") or
    (this_player == "scissors" and that_player == "paper") or
    (this_player == "paper" and that_player == "rock")
  ) then 6
  elif this_player == that_player then 3
  else 0
  end
;

def points_for_throw(throw):
  if throw == "rock" then 1
  elif throw == "paper" then 2
  else 3
  end
;

map(
  split(" ") |
  (
    points_for_outcome(letter_to_throw(.[0]); letter_to_throw(.[1]))
    +
    points_for_throw(letter_to_throw(.[1]))
  )
) |
add
