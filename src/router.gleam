import gleam/dict
import gleam/dynamic/decode
import gleam/function
import gleam/json
import gleam/list
import gleam/result
import lustre/attribute
import lustre/element

pub type PageProps =
  dict.Dict(String, String)

// #############################################################

pub type Page {
  Page(name: String, with_props: PageProps)
}

pub fn page_to_json(page: Page) {
  json.object([
    #("name", json.string(page.name)),
    #("with_props", json.dict(page.with_props, function.identity, json.string)),
  ])
}

pub fn page_decoder() {
  use name <- decode.field("name", decode.string)
  use with_props <- decode.field(
    "with_props",
    decode.dict(decode.string, decode.string),
  )
  decode.success(Page(name:, with_props:))
}

pub fn create_page(page: Page, attr) {
  element.element(
    page.name,
    list.append(attr, {
      let kvs = page.with_props |> dict.to_list
      use kv <- list.map(kvs)
      attribute.property(kv.0, json.string(kv.1))
    }),
    [],
  )
}

// #############################################################

pub type Router {
  Router(router: dict.Dict(String, Page), default: String)
}

pub fn router_to_json_str(router: Router) {
  json.object([
    #("default", json.string(router.default)),
    #("router", json.dict(router.router, function.identity, page_to_json)),
  ])
  |> json.to_string
}

pub fn router_decoder() {
  use default <- decode.field("default", decode.string)
  use router <- decode.field(
    "router",
    decode.dict(decode.string, page_decoder()),
  )
  decode.success(Router(router:, default:))
}

pub fn new_router(from: List(#(List(String), Page)), default: String) {
  from
  |> list.flat_map(fn(pair) {
    let #(ks, v) = pair
    ks |> list.map(fn(k) { #(k, v) })
  })
  |> dict.from_list
  |> Router(default)
}

pub fn do_route(router: Router, page_type: String) {
  router.router
  |> dict.get(page_type)
  |> result.unwrap({
    dict.get(router.router, router.default)
    |> result.unwrap(Page("div", dict.new()))
  })
}
