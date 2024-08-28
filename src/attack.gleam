import body_part.{type BodyPart}
import damage_kind.{type DamageKind}

pub type Attack {
  Attack(
    damage_kind: Result(DamageKind, Nil),
    body_part: Result(BodyPart, Nil),
    amount: Result(Int, Nil),
  )
}

pub type ValidatedAttack {
  ValidatedAttack(damage_kind: DamageKind, body_part: BodyPart, amount: Int)
}

pub fn with_damage_kind(
  attack: Attack,
  damage_kind: Result(DamageKind, Nil),
) -> Attack {
  Attack(..attack, damage_kind: damage_kind)
}

pub fn the_body_part(attack: Attack, body_part: Result(BodyPart, Nil)) -> Attack {
  Attack(..attack, body_part: body_part)
}

pub fn validate(attack: Attack) -> Result(ValidatedAttack, Nil) {
  case attack {
    Attack(Ok(damage_kind), Ok(body_part), Ok(amount)) ->
      Ok(ValidatedAttack(damage_kind, body_part, amount))
    _ -> Error(Nil)
  }
}

pub type Damage {
  Damage(kind: DamageKind, amount: Int)
}
