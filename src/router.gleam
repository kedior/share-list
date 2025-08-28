// IMPORTS ---------------------------------------------------------------------
import download
import encrypted
import fallback
import ffi/ffi.{history_replace_state}
import gleam/dict
import gleam/function
import gleam/json
import gleam/result
import loading
import lustre
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import plinth/browser/window
import types.{type PageProps, type Router, do_route, new_router}
import utils

pub fn register() {
  lustre.component(init, update, view, [])
  |> utils.register_with_random_name()
}

// MODEL -----------------------------------------------------------------------

type Model {
  Model(page_type: String, props: PageProps, router: Router)
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

  let download_name = download.register()
  let fallback_name = fallback.register()
  let loading_name = loading.register()
  let enc_name = encrypted.register()
  let router =
    new_router(
      [
        #(["fallback", "404"], fallback_name),
        #(["loading", "load"], loading_name),
        #(["download"], download_name),
        #([""], enc_name),
      ],
      enc_name,
    )
  #(Model("", dict.new(), router), eff)
}

// UPDATE ----------------------------------------------------------------------

type Msg {
  RouterChange(router: Router)
  HashChange(props: PageProps)
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    RouterChange(router) -> #(Model(..model, router:), effect.none())
    HashChange(props) -> {
      let page_type =
        props
        |> dict.get("d")
        |> result.unwrap("")

      let next_model = Model(..model, page_type:, props:)
      #(next_model, effect.none())
    }
  }
}

// VIEW ------------------------------------------------------------------------

fn view(model: Model) -> Element(Msg) {
  do_route(model.router, model.page_type)
  |> element.element(
    [
      attribute.property(
        "props",
        json.dict(model.props, function.identity, json.string),
      ),
    ],
    [],
  )
}
