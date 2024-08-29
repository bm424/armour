import attack.{type Attack, Attack}
import body_part
import character.{type Character}
import damage_kind
import gleam/dict.{type Dict}
import gleam/dynamic.{dict, int, list}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import lustre
import lustre/attribute
import lustre/element
import lustre/element/html
import lustre/event

pub type Model {
  Importing(character_value: String)
  Running(
    characters: dict.Dict(Int, Character),
    selected_character: Option(Int),
    attack: Attack,
  )
}

fn parse_to_running(data: String) -> Model {
  let characters =
    character.list_from_json(data) |> result.unwrap([]) |> enumerate
  let selected_character = None
  let attack =
    attack.Attack(Ok(damage_kind.Slashing), Ok(body_part.Head), Ok(0))
  Running(characters, selected_character, attack)
}

pub fn init(_flags) -> Model {
  Importing(
    "[
  {
      \"name\": \"Noble's Bodyguard 1\",
      \"stats\": {
          \"brawn\": 4,
          \"resolve\": 4
      },
      \"damage_taken\": 0,
      \"armour\": {
          \"head\": {
              \"name\": \"Steel Helmet with Mail\",
              \"protection\": {
                  \"slashing\": 36,
                  \"piercing\": 24,
                  \"blunt\": 24
              },
              \"hit_points\": 32
          },
          \"torso\": {
              \"name\": \"Lamellar Vest\",
              \"protection\": {
                  \"slashing\": 30,
                  \"piercing\": 18,
                  \"blunt\": 18
              },
              \"hit_points\": 38
          },
          \"shoulders\": {
              \"name\": \"Plate Pauldrons\",
              \"protection\": {
                  \"slashing\": 36,
                  \"piercing\": 24,
                  \"blunt\": 24
              },
              \"hit_points\": 35
          },
          \"feet\": {
              \"name\": \"Leather Boots\",
              \"protection\": {
                  \"slashing\": 5
              },
              \"hit_points\": 13
          }
      }
  },
  {
      \"name\": \"Irhukshun\",
      \"stats\": {
          \"brawn\": 3,
          \"resolve\": 2
      },
      \"damage_taken\": 0,
      \"armour\": {
          \"torso\": {
              \"name\": \"Studded Leather Vest\",
              \"protection\": {
                  \"slashing\": 6,
                  \"blunt\": 5
              },
              \"hit_points\": 20
          },
          \"feet\": {
              \"name\": \"Leather Boots\",
              \"protection\": {
                  \"slashing\": 5
              },
              \"hit_points\": 13
          }
      }
    }
]",
  )
}

pub type Message {
  UserUpdatedCharacterValue(value: String)
  UserSubmittedCharacterValue
  UserSelectedDamageKind(value: String)
  UserSelectedBodyPart(value: String)
  UserUpdatedAmount(value: String)
  UserClickedApplyDamage
  UserSelectedCharacter(value: String)
}

fn enumerate(list: List(a)) -> Dict(Int, a) {
  list |> list.index_map(fn(x, i) { #(i, x) }) |> dict.from_list
}

pub fn update(model: Model, message: Message) -> Model {
  case message, model {
    UserUpdatedCharacterValue(value), Importing(_) -> {
      Importing(character_value: value)
    }
    UserSubmittedCharacterValue, Importing(character_value) -> {
      let characters =
        character.list_from_json(character_value)
        |> result.unwrap([])
        |> enumerate
      Running(
        characters,
        None,
        Attack(Ok(damage_kind.Slashing), Ok(body_part.Head), Ok(0)),
      )
    }
    UserSelectedDamageKind(damage_kind_label),
      Running(characters, selected_character, attack)
    -> {
      let damage_kind = damage_kind.from_string(damage_kind_label)
      let attack = attack |> attack.with_damage_kind(damage_kind)
      Running(characters, selected_character, attack)
    }
    UserSelectedBodyPart(body_part_label),
      Running(characters, selected_character, attack)
    -> {
      let body_part = body_part.from_string(body_part_label)
      let attack = attack |> attack.the_body_part(body_part)
      Running(characters, selected_character, attack)
    }
    UserUpdatedAmount(amount_value),
      Running(characters, selected_character, attack)
    -> {
      let amount = int.parse(amount_value)
      let attack = Attack(..attack, amount: amount)
      Running(characters, selected_character, attack)
    }
    UserClickedApplyDamage, Running(characters, selected_character, attack) -> {
      case attack.validate(attack) {
        Error(_) -> model
        Ok(validated_attack) -> {
          case selected_character {
            None -> model
            Some(selected_character) -> {
              case dict.get(characters, selected_character) {
                Error(_) -> model
                Ok(character) -> {
                  let character = character.damage(character, validated_attack)
                  let characters =
                    dict.insert(characters, selected_character, character)
                  Running(characters, Some(selected_character), attack)
                }
              }
            }
          }
        }
      }
    }
    UserSelectedCharacter(character_label),
      Running(characters, _selected_character, attack)
    -> {
      case int.parse(character_label) {
        Error(_) -> model
        Ok(choice) -> Running(characters, Some(choice), attack)
      }
    }
    _, _ -> model
  }
}

pub fn view(model: Model) -> element.Element(Message) {
  case model {
    Importing(character_value) ->
      html.div([attribute.class("container pt-2 mx-auto flex flex-col gap-2")], [
        html.textarea(
          [
            event.on_input(UserUpdatedCharacterValue),
            attribute.rows(18),
            attribute.class("textarea textarea-bordered leading-5 font-mono"),
          ],
          character_value,
        ),
        html.div([], [
          html.button(
            [
              event.on_click(UserSubmittedCharacterValue),
              attribute.class("btn btn-primary"),
            ],
            [html.text("Submit")],
          ),
        ]),
      ])
    Running(characters, selected_character_id, attack) -> {
      let selected_character = case selected_character_id {
        None -> None
        Some(selected_character_id) -> {
          case dict.get(characters, selected_character_id) {
            Error(_) -> None
            Ok(character) -> Some(character)
          }
        }
      }

      html.div([attribute.class("flex w-full h-screen")], [
        html.div([attribute.class("flex flex-row w-full")], [
          characters_table(characters, selected_character_id),
          character_detail(selected_character),
          attack_form(attack),
        ]),
      ])
    }
  }
}

fn character_detail(character: Option(Character)) -> element.Element(Message) {
  case character {
    None ->
      html.div([attribute.class("basis-1/3 text-center bg-base-200 p-4")], [
        html.p([], [html.text("No character selected.")]),
      ])
    Some(character) ->
      html.div([attribute.class("basis-1/3 bg-base-200 p-4")], [
        html.p([attribute.class("mb-6")], [html.text(character.name)]),
        html.div([attribute.class("flex flex-col gap-2")], [
          html.table([attribute.class("table border-t border-b")], [
            html.thead([], [
              html.th([], [html.text("Item")]),
              html.th([], [html.text("Protection")]),
              html.th([], [html.text("Hit Points")]),
            ]),
            html.tbody(
              [],
              character.armour.items
                |> dict.to_list
                |> list.map(fn(item) {
                  let #(body_part, armour_item) = item
                  let hit_points_label = case armour_item {
                    character.BrokenItem(_) -> "Broken!"
                    character.ArmourItem(hit_points: hit_points, ..) ->
                      int.to_string(hit_points)
                  }
                  html.tr([], [
                    html.td([], [html.text(armour_item.name)]),
                    html.td([], [html.text(body_part.to_string(body_part))]),
                    html.td([], [html.text(hit_points_label)]),
                  ])
                }),
            ),
          ]),
          html.p(
            [attribute.classes([#("text-red-500", character.damage_taken > 0)])],
            [
              html.text(
                "Damage (last attack): "
                <> character.damage_taken |> int.to_string,
              ),
            ],
          ),
        ]),
      ])
  }
}

pub fn characters_table(
  characters: Dict(Int, Character),
  selected_character: Option(Int),
) -> element.Element(Message) {
  html.div([attribute.class("basis-1/3 bg-base-300")], [
    html.p([attribute.class("mb-6 p-4")], [html.text("Characters")]),
    html.table([attribute.class("table")], [
      html.tbody(
        [],
        characters
          |> dict.to_list
          |> list.map(fn(id_character) {
            let #(id, character) = id_character
            html.tr(
              [
                attribute.class("hover cursor-pointer"),
                event.on_click(UserSelectedCharacter(int.to_string(id))),
              ],
              [
                html.td([attribute.class("pl-4")], [
                  html.input([
                    attribute.type_("radio"),
                    attribute.name("selected"),
                    attribute.class("radio radio-sm"),
                    attribute.value(int.to_string(id)),
                    attribute.checked(Some(id) == selected_character),
                    event.on_input(UserSelectedCharacter),
                  ]),
                ]),
                html.td([attribute.class("pr-4")], [html.text(character.name)]),
              ],
            )
          }),
      ),
    ]),
  ])
}

pub fn attack_form(attack: Attack) -> element.Element(Message) {
  let damage_kind_value =
    attack.damage_kind
    |> result.map(damage_kind.to_string)
    |> result.unwrap("")

  let body_part_value =
    attack.body_part |> result.map(body_part.to_string) |> result.unwrap("")

  let amount_value =
    attack.amount |> result.map(int.to_string) |> result.unwrap("")

  html.div([attribute.class("basis-1/3 p-4")], [
    html.p([attribute.class("mb-6")], [html.text("Attack")]),
    html.div([attribute.class("flex flex-col gap-2")], [
      html.label([attribute.class("form-control")], [
        html.label([], [html.text("Type")]),
        html.select(
          [
            attribute.class("select select-bordered"),
            attribute.value(damage_kind_value),
            event.on_input(UserSelectedDamageKind),
          ],
          damage_kind.damage_kinds
            |> list.map(fn(damage_kind) {
              let value = damage_kind.to_string(damage_kind)
              html.option(
                [attribute.selected(damage_kind_value == value)],
                value,
              )
            }),
        ),
      ]),
      html.label([attribute.class("form-control")], [
        html.label([], [html.text("Target")]),
        html.select(
          [
            attribute.class("select select-bordered"),
            attribute.value(body_part_value),
            event.on_input(UserSelectedBodyPart),
          ],
          body_part.body_parts
            |> list.map(fn(body_part) {
              let value = body_part.to_string(body_part)
              html.option([attribute.selected(body_part_value == value)], value)
            }),
        ),
      ]),
      html.label([attribute.class("form-control")], [
        html.label([], [html.text("Damage")]),
        html.input([
          attribute.class("input input-bordered"),
          attribute.type_("number"),
          attribute.value(amount_value),
          event.on_input(UserUpdatedAmount),
        ]),
      ]),
      html.button(
        [attribute.class("btn"), event.on_click(UserClickedApplyDamage)],
        [html.text("Apply Damage")],
      ),
    ]),
  ])
}

pub fn main() {
  let app = lustre.simple(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}
