import gleam/dict
import gleam/list
import gleam/result

pub type PageProps =
  dict.Dict(String, String)

pub type Router {
  Router(router: dict.Dict(String, String), default: String)
}

pub fn new_router(from: List(#(List(String), String)), default: String) {
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
  |> result.unwrap(router.default)
}
