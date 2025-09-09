import gleam/dict
import gleam/dynamic/decode
import gleam/function
import gleam/json
import gleam/list
import gleam/result
import page

pub opaque type Router {
  Router(router: dict.Dict(String, page.Page), default: String)
}

pub fn to_json(router: Router) {
  json.object([
    #("default", json.string(router.default)),
    #("router", json.dict(router.router, function.identity, page.to_json)),
  ])
}

pub fn decoder() {
  use default <- decode.field("default", decode.string)
  use router <- decode.field(
    "router",
    decode.dict(decode.string, page.decoder()),
  )
  decode.success(Router(router:, default:))
}

pub fn new(from: List(#(List(String), page.Page)), default: String) {
  from
  |> list.flat_map(fn(pair) {
    let #(ks, v) = pair
    ks |> list.map(fn(k) { #(k, v) })
  })
  |> dict.from_list
  |> Router(default)
}

pub fn route(router: Router, page_type: String) {
  router.router
  |> dict.get(page_type)
  |> result.unwrap({
    dict.get(router.router, router.default)
    |> result.unwrap(page.new("div"))
  })
}
