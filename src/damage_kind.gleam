import gleam/dynamic.{type DecodeError, type Dynamic}
import gleam/result

pub type DamageKind {
  Slashing
  Piercing
  Blunt
}

pub const damage_kinds = [Piercing, Slashing, Blunt]

pub fn to_string(damage_kind: DamageKind) -> String {
  case damage_kind {
    Slashing -> "slashing"
    Piercing -> "piercing"
    Blunt -> "blunt"
  }
}

pub fn from_string(string: String) -> Result(DamageKind, Nil) {
  case string {
    "slashing" -> Ok(Slashing)
    "piercing" -> Ok(Piercing)
    "blunt" -> Ok(Blunt)
    _ -> Error(Nil)
  }
}

pub fn decode(dynamic: Dynamic) -> Result(DamageKind, List(DecodeError)) {
  use string <- result.try(dynamic.string(dynamic))
  from_string(string)
  |> result.replace_error([
    dynamic.DecodeError("Slashing/Piercing/Blunt", string, []),
  ])
}
