import body_part
import character
import damage_kind
import gleam/dict
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

// gleeunit test functions end in `_test`
pub fn character_list_from_json_test() {
  "[
          {
              \"name\": \"Noble's Bodyguard 1\",
              \"damage_taken\": 0,
              \"stats\": {
                  \"brawn\": 4,
                  \"resolve\": 4
              },
              \"armour\": {
                  \"head\": {
                      \"name\": \"Steel Helmet with Mail\",
                      \"protection\": {
                          \"slashing\": 36,
                          \"piercing\": 24,
                          \"blunt\": 24
                      },
                      \"hit_points\": 32
                  }
              }
          }
      ]"
  |> character.list_from_json
  |> should.be_ok
  |> should.equal([
    character.NPC(
      name: "Noble's Bodyguard 1",
      stats: character.Stats(4, 4),
      damage_taken: 0,
      armour: character.Armour(
        dict.from_list([
          #(
            body_part.Head,
            character.ArmourItem(
              "Steel Helmet with Mail",
              dict.from_list([
                #(damage_kind.Slashing, 36),
                #(damage_kind.Piercing, 24),
                #(damage_kind.Blunt, 24),
              ]),
              32,
            ),
          ),
        ]),
      ),
    ),
  ])
}
