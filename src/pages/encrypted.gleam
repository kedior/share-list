// IMPORTS ---------------------------------------------------------------------
import gleam/dict
import gleam/dynamic/decode
import gleam/function
import gleam/json
import gleam/result
import listener
import lustre
import lustre/attribute
import lustre/component
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import page
import pages/fallback
import pages/loading
import router
import utils

pub fn register() {
  lustre.component(init, update, view, [
    component.on_property_change("router", {
      use json_str <- decode.map(decode.string)
      let assert Ok(r) = json.parse(json_str, router.decoder())
      MsgRouterChange(r)
    }),
    component.on_property_change("props", {
      use props <- decode.map(decode.dict(decode.string, decode.string))
      let try_parse_props = {
        use src <- result.try(props |> dict.get("src"))
        use key <- result.try(props |> dict.get("key"))
        let d = props |> dict.get("d") |> result.unwrap("")
        // history reasons
        let next_src = utils.wrap_src(src)
        let next_props = dict.insert(props, "src", next_src)

        Ok(Props(d, next_src, key, next_props))
      }
      case try_parse_props {
        Ok(props) -> MsgPropsChange(props)
        Error(Nil) -> MsgFailed
      }
    }),
  ])
  |> utils.register_with_random_name
}

// MODEL -----------------------------------------------------------------------
type Status {
  Loading
  Failed
  Success(String)
}

type Props {
  Props(page_type: String, src: String, key: String, other: listener.HashProps)
}

fn empty_prop() {
  Props("", "", "", dict.new())
}

type Model {
  Model(status: Status, props: Props, router: router.Router)
}

fn init(_) -> #(Model, Effect(Msg)) {
  #(Model(Loading, empty_prop(), router.new([], "")), effect.none())
}

// UPDATE ----------------------------------------------------------------------

type Msg {
  MsgRouterChange(router.Router)
  MsgPropsChange(Props)
  MsgSuccess(String)
  MsgFailed
}

fn is_source_changed(old_props: Props, new_props: Props) {
  old_props.src != new_props.src || old_props.key != new_props.key
}

fn do_fetch_content(model: Model, dispatch) {
  use res <- utils.await_get_content(model.props.src, model.props.key)
  case res {
    Ok(content) -> {
      dispatch(MsgSuccess(content))
    }
    Error(_) -> dispatch(MsgFailed)
  }
}

fn props_change_effect(old_model: Model, new_model: Model) {
  use dispatch <- effect.from()
  let old_r = old_model.router
  let new_r = new_model.router
  let old_type = old_model.props.page_type
  let new_type = new_model.props.page_type

  let page_changed =
    router.route(old_r, old_type) != router.route(new_r, new_type)
  let source_changed = is_source_changed(old_model.props, new_model.props)
  case page_changed, source_changed {
    True, _ | _, True -> do_fetch_content(new_model, dispatch)
    False, False -> Nil
  }
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    MsgRouterChange(router) -> #(Model(..model, router:), effect.none())
    MsgPropsChange(props) -> {
      let next_model = Model(..model, status: Loading, props:)
      #(next_model, props_change_effect(model, next_model))
    }
    MsgFailed -> #(Model(..model, status: Failed), effect.none())
    MsgSuccess(content) -> #(
      Model(..model, status: Success(content)),
      effect.none(),
    )
  }
}

// VIEW ------------------------------------------------------------------------

fn view(model: Model) -> Element(Msg) {
  case model.status {
    Loading -> loading.element()
    Failed -> fallback.element()
    Success(content) -> {
      let next_props = model.props.other |> dict.insert("content", content)
      let p = router.route(model.router, model.props.page_type)
      page.create(p, [
        attribute.property(
          "props",
          json.dict(next_props, function.identity, json.string),
        ),
      ])
    }
  }
}
