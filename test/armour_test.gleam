import armour
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

fn is_importing(model: armour.Model) {
  case model {
    armour.Importing(_) -> True
    _ -> False
  }
}

// the app should start in the right state
pub fn init_test() {
  armour.init(Nil) |> is_importing |> should.be_true
}
