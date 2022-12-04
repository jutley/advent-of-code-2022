include "lib";

def letter_to_throw(letter):
  (
    ["rock", "paper", "scissors"] |
    with_entries(.key = from_ascii_code(.key + to_ascii_code("A", "X")))
  )[letter]
;

def points_for_outcome(that_player; this_player):
  def winning_throw_to_losing_throw: {
    "rock": "scissors",
    "scissors": "paper",
    "paper": "rock"
  };
  if winning_throw_to_losing_throw[this_player] == that_player then 6
  elif this_player == that_player then 3
  else 0
  end
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
  map(letter_to_throw(.)) |
  {
    points_for_outcome: points_for_outcome(.[0]; .[1]),
    points_for_throw: points_for_throw(.[1])
  } |
  add
) |
add
