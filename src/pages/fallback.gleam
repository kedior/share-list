import lustre
import lustre/attribute
import lustre/effect
import lustre/element
import lustre/element/html
import styles/modules/global_module_css as css
import utils

pub fn element() {
  element.fragment([
    html.style([], css.css),
    html.div([attribute.class(css.fallback)], [
      html.h1([], [
        html.text("Oops! This page galloped away on a unicorn."),
      ]),
      html.img([
        attribute.attribute("src", "./unicorn.png"),
        attribute.attribute("alt", "Lost Unicorn"),
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
