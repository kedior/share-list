import ffi/ffi
import loading
import lustre/element.{type Element}
import types.{type PageProps, NewEncryptedPage}

pub const page = NewEncryptedPage(start, clean)

fn start(content: String, _props: PageProps) -> Element(msg) {
  ffi.render_raw_html(content)
  loading.element()
}

fn clean() {
  Nil
}
