import gleam/dict
import lustre/element.{type Element}

pub type PageProps =
  dict.Dict(String, String)

pub type Page(msg) {
  NewPage(start: fn(PageProps) -> Element(msg), clean: fn() -> Nil)
}

pub type EncryptedPage(msg) {
  NewEncryptedPage(
    start: fn(String, PageProps) -> Element(msg),
    clean: fn() -> Nil,
  )
}
