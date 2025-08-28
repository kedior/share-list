// IMPORTS ---------------------------------------------------------------------
import fallback
import gleam/dict
import gleam/dynamic/decode
import gleam/function
import gleam/json
import gleam/result
import loading
import lustre
import lustre/attribute
import lustre/component
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import markdown
import rawhtml
import types.{type PageProps, type Router, do_route, new_router}
import utils

pub fn register() {
  lustre.component(init, update, view, [
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
  Props(page_type: String, src: String, key: String, other: PageProps)
}

fn empty_prop() {
  Props("", "", "", dict.new())
}

type Model {
  Model(status: Status, props: Props, router: Router)
}

fn init(_) -> #(Model, Effect(Msg)) {
  let markdown_name = markdown.register()
  let raw_html_name = rawhtml.register()

  let router =
    new_router(
      [
        #(["md", "markdown"], markdown_name),
        #(["html"], raw_html_name),
      ],
      markdown_name,
    )
  #(Model(Loading, empty_prop(), router), effect.none())
}

// UPDATE ----------------------------------------------------------------------

type Msg {
  MsgRouterChange(Router)
  MsgPropsChange(Props)
  MsgSuccess(Model)
  MsgFailed
}

fn is_source_changed(old_props: Props, new_props: Props) {
  old_props.src != new_props.src || old_props.key != new_props.key
}

fn do_fetch_content(model: Model, dispatch) {
  use res <- utils.await_get_content(model.props.src, model.props.key)
  case res {
    Ok(content) -> {
      let next_model = Model(..model, status: Success(content))
      dispatch(MsgSuccess(next_model))
    }
    Error(_) -> dispatch(MsgFailed)
  }
}

fn props_change_effect(model: Model, props: Props) {
  use dispatch <- effect.from()
  let r = model.router
  let old_type = model.props.page_type
  let new_type = props.page_type
  let page_changed = do_route(r, old_type) != do_route(r, new_type)
  let source_changed = is_source_changed(model.props, props)

  let next_model = Model(..model, props:)
  case page_changed, source_changed {
    True, _ | _, True -> do_fetch_content(next_model, dispatch)
    False, False -> dispatch(MsgSuccess(next_model))
  }
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    MsgRouterChange(router) -> #(Model(..model, router:), effect.none())
    MsgPropsChange(props) -> {
      #(
        Model(..model, status: Loading, props:),
        props_change_effect(model, props),
      )
    }
    MsgFailed -> #(Model(..model, status: Failed), effect.none())
    MsgSuccess(model) -> #(model, effect.none())
  }
}

// VIEW ------------------------------------------------------------------------

fn view(model: Model) -> Element(Msg) {
  case model.status {
    Loading -> loading.element()
    Failed -> fallback.element()
    Success(content) -> {
      let next_props = model.props.other |> dict.insert("content", content)
      do_route(model.router, model.props.page_type)
      |> element.element(
        [
          attribute.property(
            "props",
            json.dict(next_props, function.identity, json.string),
          ),
        ],
        [],
      )
    }
  }
}
