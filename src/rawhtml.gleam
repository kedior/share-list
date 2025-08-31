import ffi/ffi
import gleam/dict
import gleam/dynamic/decode
import gleam/result
import lustre
import lustre/component
import lustre/effect
import lustre/element
import utils

fn init(_) {
  #(Nil, effect.none())
}

fn update(_model, _msg) {
  #(Nil, effect.none())
}

fn view(_model) {
  element.none()
}

pub fn register() {
  lustre.component(init, update, view, [
    component.on_property_change("props", {
      use props <- decode.map(decode.dict(decode.string, decode.string))
      {
        use content <- result.try(props |> dict.get("content"))
        ffi.render_raw_html(content)
        Ok(Nil)
      }
      |> result.unwrap(Nil)
    }),
  ])
  |> utils.register_with_random_name
}
