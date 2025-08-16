// IMPORTS ---------------------------------------------------------------------
import encrypted
import fallback
import ffi/ffi.{history_replace_state}
import gleam/dict
import gleam/result
import loading
import lustre
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import plinth/browser/window
import types.{type Page, type PageProps}
import utils

const component_name = "hash-router"

pub fn register() -> Result(Nil, lustre.Error) {
  let assert Ok(_) = encrypted.register()

  let comp = lustre.component(init, update, view, [])
  lustre.register(comp, component_name)
}

pub fn element() -> Element(msg) {
  element.element(component_name, [], [])
}

fn router(page_type: String) -> Page(Msg) {
  case page_type {
    "404" | "fallback" -> fallback.page
    "load" | "loading" -> loading.page
    _ -> encrypted.page
  }
}

// MODEL -----------------------------------------------------------------------

type Model {
  Model(page_type: String, props: PageProps)
}

fn init(_) -> #(Model, Effect(Msg)) {
  let eff = {
    use dispatch <- effect.from

    // add hashchange event listener
    window.add_event_listener("hashchange", fn(_event) {
      utils.get_url_params() |> HashChange |> dispatch
    })

    // refresh hash
    let params = utils.get_url_params()
    let next_url = utils.param_dict_to_hashed_url(params)

    history_replace_state(next_url)

    params |> HashChange |> dispatch
  }
  #(Model("", dict.new()), eff)
}

// UPDATE ----------------------------------------------------------------------

type Msg {
  HashChange(props: PageProps)
}

fn update(_model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  let d =
    msg.props
    |> dict.get("d")
    |> result.unwrap("")

  let next_model = Model(page_type: d, props: msg.props)

  #(next_model, effect.none())
}

// VIEW ------------------------------------------------------------------------

fn view(model: Model) -> Element(Msg) {
  model.props |> router(model.page_type)
}
