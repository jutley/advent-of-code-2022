def letter_to_throw(letter):
  if letter == "A" then "rock"
  elif letter == "B" then "paper"
  else "scissors"
  end
;

def letter_to_outcome(letter):
  if letter == "X" then "lose"
  elif letter == "Y" then "draw"
  else "win"
  end
;

def this_players_throw(that_players_throw; outcome):
  if outcome == "win" then (
    if that_players_throw == "rock" then "paper"
    elif that_players_throw == "paper" then "scissors"
    else "rock"
    end
  )
  elif outcome == "lose" then (
    if that_players_throw == "rock" then "scissors"
    elif that_players_throw == "paper" then "rock"
    else "paper"
    end
  )
  else that_players_throw
  end
;

def points_for_outcome(outcome):
  if outcome == "win" then 6
  elif outcome == "draw" then 3
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
    points_for_outcome(letter_to_outcome(.[1]))
    +
    points_for_throw(this_players_throw(letter_to_throw(.[0]); letter_to_outcome(.[1])))
  )
) |
add
