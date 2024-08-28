import gleam/dynamic.{type DecodeError, type Dynamic}
import gleam/result

pub type BodyPart {
  Head
  Shoulders
  Torso
  Legs
  Feet
}

pub const body_parts = [Head, Shoulders, Torso, Legs, Feet]

pub fn to_string(body_part: BodyPart) -> String {
  case body_part {
    Head -> "head"
    Shoulders -> "shoulders"
    Torso -> "torso"
    Legs -> "legs"
    Feet -> "feet"
  }
}

pub fn from_string(string: String) -> Result(BodyPart, Nil) {
  case string {
    "head" -> Ok(Head)
    "shoulders" -> Ok(Shoulders)
    "torso" -> Ok(Torso)
    "legs" -> Ok(Legs)
    "feet" -> Ok(Feet)
    _ -> Error(Nil)
  }
}

pub fn decode(dynamic: Dynamic) -> Result(BodyPart, List(DecodeError)) {
  use string <- result.try(dynamic.string(dynamic))
  from_string(string)
  |> result.replace_error([
    dynamic.DecodeError("Head/Shoulders/Torso/Legs/Feet", string, []),
  ])
}
