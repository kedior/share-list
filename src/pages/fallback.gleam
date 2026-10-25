import lustre
import lustre/attribute
import lustre/effect
import lustre/element
import lustre/element/html
import utils

pub fn element() {
  element.fragment([
    html.div([attribute.style("text-align", "center")], [
      html.h1([], [
        html.text("Oops! This page galloped away on a unicorn."),
      ]),
      html.img([
        attribute.attribute("src", "./unicorn.png"),
        attribute.attribute("alt", "Lost Unicorn"),
        attribute.styles([
          #("max-width", "300px"),
          #("margin", "40px auto"),
          #("display", "block"),
        ]),
      ]),
    ]),
  ])
}

fn init(_) -> #(Nil, effect.Effect(Nil)) {
  #(Nil, utils.set_title_effect("404!"))
}

fn update(_model: Nil, _msg: Nil) -> #(Nil, effect.Effect(Nil)) {
  #(Nil, effect.none())
}

pub fn register() {
  lustre.component(init, update, fn(_model) { element() }, [])
  |> utils.register_with_random_name
}
