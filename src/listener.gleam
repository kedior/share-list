// IMPORTS ---------------------------------------------------------------------
import ffi/ffi.{history_replace_state}
import gleam/dict
import gleam/dynamic/decode
import gleam/function
import gleam/json
import gleam/result
import hash
import lustre
import lustre/attribute
import lustre/component
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import page
import plinth/browser/location
import plinth/browser/window
import router
import utils

pub fn register() {
  lustre.component(init, update, view, [
    component.on_property_change("router", {
      use r <- decode.map(router.decoder())
      RouterChange(r)
    }),
  ])
  |> utils.register_with_random_name()
}

pub type HashProps =
  dict.Dict(String, String)

// MODEL -----------------------------------------------------------------------

type Model {
  Model(page_type: String, props: HashProps, router: router.Router)
}

fn init(_) -> #(Model, Effect(Msg)) {
  let eff = {
    use dispatch <- effect.from
    // add hashchange event listener
    window.add_event_listener("hashchange", fn(_event) {
      hash.get_url_params() |> HashChange |> dispatch
    })
    hash.get_url_params() |> HashChange |> dispatch
  }

  #(Model("", dict.new(), router.new([], "")), eff)
}

// UPDATE ----------------------------------------------------------------------

type Msg {
  RouterChange(router: router.Router)
  HashChange(props: HashProps)
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    RouterChange(router) -> #(Model(..model, router:), effect.none())
    HashChange(props) -> {
      let eff = {
        use dispatch <- effect.from
        let now_href = window.self() |> window.location |> location.href
        let next_href = hash.param_dict_to_hashed_href(props)
        case next_href == now_href {
          True -> Nil
          False -> {
            //href is now old style, so refresh hash
            history_replace_state(next_href)
            props |> HashChange |> dispatch
          }
        }
      }
      let page_type = props |> dict.get("d") |> result.unwrap("")
      let next_model = Model(..model, page_type:, props:)
      #(next_model, eff)
    }
  }
}

// VIEW ------------------------------------------------------------------------

fn view(model: Model) -> Element(Msg) {
  let page = router.route(model.router, model.page_type)
  page.create(page, [
    attribute.property(
      "props",
      json.dict(model.props, function.identity, json.string),
    ),
  ])
}
