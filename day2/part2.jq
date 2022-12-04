include "lib";

def letter_to_throw(letter):
  {
    "A": "rock",
    "B": "paper",
    "C": "scissors"
  }[letter]
;

def letter_to_outcome(letter):
  {
    "X": "lose",
    "Y": "draw",
    "Z": "win"
  }[letter]
;

def this_players_throw(that_players_throw; outcome):
  def winning_throw_to_losing_throw: {
    "rock": "scissors",
    "scissors": "paper",
    "paper": "rock"
  };
  def losing_throw_to_winning_throw: winning_throw_to_losing_throw | to_entries | map({(.value): .key}) | add;

  if outcome == "win" then losing_throw_to_winning_throw[that_players_throw]
  elif outcome == "lose" then winning_throw_to_losing_throw[that_players_throw]
  else that_players_throw
  end
;

def points_for_outcome(outcome):
  {
    "win": 6,
    "draw": 3,
    "lose": 0
  }[outcome]
;

def points_for_throw(throw):
  {
    rock: 1,
    paper: 2,
    scissors: 3
  }[throw]
;

map(
  split(" ") |
  {
    points_for_outcome: points_for_outcome(letter_to_outcome(.[1])),
    points_for_throw: points_for_throw(this_players_throw(letter_to_throw(.[0]); letter_to_outcome(.[1])))
  } |
  add
) |
add
