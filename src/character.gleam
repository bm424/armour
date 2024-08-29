import attack.{type ValidatedAttack}
import body_part.{type BodyPart}
import damage_kind.{type DamageKind}
import gleam/dict
import gleam/dynamic.{type Dynamic}
import gleam/int
import gleam/json

pub type Character {
  NPC(name: String, stats: Stats, armour: Armour, damage_taken: Int)
}

pub fn damage(character: Character, attack: ValidatedAttack) -> Character {
  let body_part = attack.body_part
  let damage_kind = attack.damage_kind
  let amount = attack.amount
  case dict.get(character.armour.items, body_part) {
    Error(_) -> NPC(..character, damage_taken: amount)
    Ok(BrokenItem(_name)) -> NPC(..character, damage_taken: amount)
    Ok(ArmourItem(name, protection, hit_points)) -> {
      case dict.get(protection, damage_kind) {
        Error(_) -> NPC(..character, damage_taken: amount)
        Ok(local_protection) -> {
          let absorbed = int.min(hit_points, local_protection)
          let #(damage_dealt, absorbed) = case amount >= absorbed {
            True -> #(amount - absorbed, absorbed)
            False -> #(0, amount)
          }
          let hit_points = hit_points - absorbed
          let armour_item = case hit_points {
            0 -> BrokenItem(name)
            _ -> ArmourItem(name, protection, hit_points)
          }
          let armour =
            Armour(dict.insert(character.armour.items, body_part, armour_item))
          NPC(..character, armour: armour, damage_taken: damage_dealt)
        }
      }
    }
  }
}

pub fn decode_character(
  dynamic: Dynamic,
) -> Result(Character, List(dynamic.DecodeError)) {
  let character_decoder =
    dynamic.decode4(
      NPC,
      dynamic.field("name", dynamic.string),
      dynamic.field("stats", decode_stats),
      dynamic.field("armour", decode_armour),
      dynamic.field("damage_taken", dynamic.int),
    )
  character_decoder(dynamic)
}

pub fn list_from_json(
  json_string: String,
) -> Result(List(Character), json.DecodeError) {
  let characters_decoder = dynamic.list(decode_character)
  json.decode(json_string, using: characters_decoder)
}

pub type Stats {
  Stats(brawn: Int, resolve: Int)
}

fn decode_stats(dynamic: Dynamic) -> Result(Stats, List(dynamic.DecodeError)) {
  let stats_decoder =
    dynamic.decode2(
      Stats,
      dynamic.field("brawn", dynamic.int),
      dynamic.field("resolve", dynamic.int),
    )
  stats_decoder(dynamic)
}

pub type Armour {
  Armour(items: dict.Dict(BodyPart, ArmourItem))
}

fn decode_armour(dynamic: Dynamic) -> Result(Armour, List(dynamic.DecodeError)) {
  let armour_decoder =
    dynamic.decode1(Armour, dynamic.dict(body_part.decode, decode_armour_item))
  armour_decoder(dynamic)
}

pub type ArmourItem {
  BrokenItem(name: String)
  ArmourItem(
    name: String,
    protection: dict.Dict(DamageKind, Int),
    hit_points: Int,
  )
}

fn decode_armour_item(
  dynamic: Dynamic,
) -> Result(ArmourItem, List(dynamic.DecodeError)) {
  let armour_item_decoder =
    dynamic.decode3(
      ArmourItem,
      dynamic.field("name", dynamic.string),
      dynamic.field("protection", dynamic.dict(damage_kind.decode, dynamic.int)),
      dynamic.field("hit_points", dynamic.int),
    )
  armour_item_decoder(dynamic)
}

pub fn leather_boots() {
  ArmourItem(
    name: "Leather Boots",
    hit_points: 13,
    protection: dict.from_list([#(damage_kind.Slashing, 5)]),
  )
}
