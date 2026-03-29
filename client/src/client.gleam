import lustre
import lustre/attribute
import lustre/element/html
import lustre/server_component

pub fn main() -> Nil {
  let app =
    lustre.simple(fn(_) { Nil }, fn(m, _) { m }, fn(_) {
      html.div([attribute.styles([#("height", "100vh")])], [
        server_component.element(
          [
            server_component.route("/ws"),
            server_component.method(server_component.WebSocket),
          ],
          [],
        ),
      ])
    })

  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}
