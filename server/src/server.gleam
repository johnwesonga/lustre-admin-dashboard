import dashboard
import gleam/bytes_tree
import gleam/erlang/application
import gleam/erlang/process.{type Selector, type Subject}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/json
import gleam/option.{type Option, None, Some}
import lustre
import lustre/attribute
import lustre/element
import lustre/element/html.{html}
import lustre/server_component
import mist.{type Connection, type ResponseData}

pub fn main() {
  let assert Ok(_) =
    fn(request: Request(Connection)) -> Response(ResponseData) {
      case request.path_segments(request) {
        [] -> serve_html()
        ["lustre", "runtime.mjs"] -> serve_runtime()
        ["ws"] -> serve_dashboard(request)
        _ -> response.set_body(response.new(404), mist.Bytes(bytes_tree.new()))
      }
    }
    |> mist.new
    |> mist.bind("0.0.0.0")
    |> mist.port(3000)
    |> mist.start

  process.sleep_forever()
}

fn serve_dashboard(request: Request(Connection)) {
  mist.websocket(
    request:,
    on_init: init_dashboard_socket,
    handler: loop_dashboard_socket,
    on_close: close_dashboard_socket,
  )
}

type DashboardSocket {
  DashboardSocket(
    component: lustre.Runtime(dashboard.Msg),
    self: Subject(server_component.ClientMessage(dashboard.Msg)),
  )
}

type DashboardSocketMessage =
  server_component.ClientMessage(dashboard.Msg)

type DashboardSocketInit =
  #(DashboardSocket, Option(Selector(DashboardSocketMessage)))

fn serve_runtime() {
  let assert Ok(lustre_priv) = application.priv_directory("lustre")
  let file_path = lustre_priv <> "/static/lustre-server-component.mjs"

  case mist.send_file(file_path, offset: 0, limit: None) {
    Ok(file) ->
      response.new(200)
      |> response.prepend_header("content-type", "application/javascript")
      |> response.set_body(file)

    Error(_) ->
      response.new(404)
      |> response.set_body(mist.Bytes(bytes_tree.new()))
  }
}

fn serve_html() {
  let html =
    html([attribute.lang("en")], [
      html.head([], [
        html.meta([attribute.charset("utf-8")]),
        html.meta([
          attribute.name("viewport"),
          attribute.content("width=device-width, initial-scale=1"),
        ]),
        html.title([], "Admin Dashboard"),
        html.script(
          [attribute.type_("module"), attribute.src("/lustre/runtime.mjs")],
          "",
        ),
        html.style([], dashboard_styles()),
      ]),
      html.body([attribute.style("height", "100dvh")], [
        server_component.element([server_component.route("/ws")], []),
      ]),
    ])
    |> element.to_document_string_tree
    |> bytes_tree.from_string_tree

  response.new(200)
  |> response.set_body(mist.Bytes(html))
  |> response.set_header("content-type", "text/html")
}

// Inline CSS ------------------------------------------------------------------

fn dashboard_styles() -> String {
  "
  *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

  :root {
    --bg:        #0d0f14;
    --surface:   #161b26;
    --border:    #1e2535;
    --accent:    #5b8ff9;
    --accent2:   #38d9a9;
    --danger:    #f06292;
    --warn:      #ffd166;
    --text:      #e0e6f0;
    --muted:     #6b7a99;
    --font-mono: 'JetBrains Mono', 'Fira Code', monospace;
    --font-sans: 'DM Sans', system-ui, sans-serif;
    --radius:    10px;
    --shadow:    0 4px 24px rgba(0,0,0,.45);
  }

  @import url('https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600&family=JetBrains+Mono:wght@400;600&display=swap');

  html, body { height: 100%; background: var(--bg); color: var(--text); font-family: var(--font-sans); }

  #app { height: 100%; }

  /* ---- layout ---- */
  .shell { display: flex; height: 100vh; overflow: hidden; }

  .sidebar {
    width: 220px; flex-shrink: 0;
    background: var(--surface);
    border-right: 1px solid var(--border);
    display: flex; flex-direction: column;
    padding: 24px 0;
  }

  .sidebar-logo {
    font-family: var(--font-mono); font-weight: 600; font-size: 1rem;
    color: var(--accent); letter-spacing: .05em;
    padding: 0 24px 28px;
    border-bottom: 1px solid var(--border);
  }

  .sidebar-logo span { color: var(--accent2); }

  .sidebar-nav { display: flex; flex-direction: column; gap: 4px; padding: 20px 12px; flex: 1; }

  .nav-item {
    display: flex; align-items: center; gap: 10px;
    padding: 10px 14px; border-radius: var(--radius);
    font-size: .875rem; font-weight: 500; color: var(--muted);
    cursor: pointer; border: none; background: transparent; text-align: left;
    transition: all .15s;
  }
  .nav-item:hover { background: rgba(91,143,249,.08); color: var(--text); }
  .nav-item.active { background: rgba(91,143,249,.14); color: var(--accent); }
  .nav-item svg { width: 16px; height: 16px; flex-shrink: 0; }

  .main { flex: 1; display: flex; flex-direction: column; overflow: hidden; }

  .topbar {
    height: 64px; flex-shrink: 0;
    border-bottom: 1px solid var(--border);
    display: flex; align-items: center; justify-content: space-between;
    padding: 0 32px;
  }

  .topbar-title { font-size: 1rem; font-weight: 600; }

  .topbar-actions { display: flex; align-items: center; gap: 14px; }

  .badge {
    font-family: var(--font-mono); font-size: .7rem; font-weight: 600;
    padding: 3px 8px; border-radius: 100px;
    background: rgba(56,217,169,.15); color: var(--accent2);
  }
  .badge.warn { background: rgba(255,209,102,.15); color: var(--warn); }
  .badge.danger { background: rgba(240,98,146,.15); color: var(--danger); }

  .avatar {
    width: 34px; height: 34px; border-radius: 50%;
    background: linear-gradient(135deg, var(--accent), var(--accent2));
    display: flex; align-items: center; justify-content: center;
    font-size: .75rem; font-weight: 700; color: #fff;
    cursor: pointer;
  }

  .content { flex: 1; overflow-y: auto; padding: 32px; display: flex; flex-direction: column; gap: 28px; }

  /* ---- stat cards ---- */
  .stat-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 16px; }

  .stat-card {
    background: var(--surface); border: 1px solid var(--border);
    border-radius: var(--radius); padding: 22px 24px;
    display: flex; flex-direction: column; gap: 14px;
    box-shadow: var(--shadow);
    transition: border-color .2s;
  }
  .stat-card:hover { border-color: var(--accent); }

  .stat-label { font-size: .75rem; text-transform: uppercase; letter-spacing: .08em; color: var(--muted); font-weight: 600; }
  .stat-value { font-family: var(--font-mono); font-size: 1.9rem; font-weight: 600; }
  .stat-delta { font-size: .78rem; color: var(--accent2); }
  .stat-delta.neg { color: var(--danger); }

  /* ---- tables ---- */
  .section-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 14px; }
  .section-title { font-size: .95rem; font-weight: 600; }

  .btn {
    font-size: .8rem; font-weight: 600; padding: 8px 16px;
    border-radius: 8px; border: 1px solid var(--border);
    background: transparent; color: var(--text); cursor: pointer;
    transition: all .15s;
  }
  .btn:hover { background: var(--accent); border-color: var(--accent); color: #fff; }
  .btn.primary { background: var(--accent); border-color: var(--accent); color: #fff; }
  .btn.primary:hover { opacity: .85; }

  .card {
    background: var(--surface); border: 1px solid var(--border);
    border-radius: var(--radius); box-shadow: var(--shadow);
  }

  table { width: 100%; border-collapse: collapse; }
  thead tr { border-bottom: 1px solid var(--border); }
  th { font-size: .72rem; text-transform: uppercase; letter-spacing: .07em; color: var(--muted); font-weight: 600; padding: 14px 20px; text-align: left; }
  td { padding: 14px 20px; font-size: .85rem; border-bottom: 1px solid var(--border); }
  tbody tr:last-child td { border-bottom: none; }
  tbody tr:hover { background: rgba(255,255,255,.02); }

  .status-pill {
    display: inline-block; font-size: .7rem; font-weight: 700;
    padding: 3px 10px; border-radius: 100px; text-transform: uppercase;
  }
  .status-pill.active   { background: rgba(56,217,169,.15); color: var(--accent2); }
  .status-pill.pending  { background: rgba(255,209,102,.15); color: var(--warn); }
  .status-pill.inactive { background: rgba(240,98,146,.12); color: var(--danger); }

  /* ---- two-col grid ---- */
  .two-col { display: grid; grid-template-columns: 2fr 1fr; gap: 16px; }

  /* ---- activity feed ---- */
  .feed { display: flex; flex-direction: column; }
  .feed-item {
    display: flex; align-items: flex-start; gap: 12px;
    padding: 16px 20px; border-bottom: 1px solid var(--border);
  }
  .feed-item:last-child { border-bottom: none; }
  .feed-dot {
    width: 8px; height: 8px; border-radius: 50%; margin-top: 5px; flex-shrink: 0;
  }
  .feed-dot.blue  { background: var(--accent); }
  .feed-dot.green { background: var(--accent2); }
  .feed-dot.red   { background: var(--danger); }
  .feed-dot.yellow { background: var(--warn); }
  .feed-text { font-size: .84rem; line-height: 1.5; }
  .feed-time { font-size: .72rem; color: var(--muted); margin-top: 2px; font-family: var(--font-mono); }

  /* ---- ticker ---- */
  .ticker-row { display: flex; align-items: center; justify-content: space-between; padding: 14px 20px; border-bottom: 1px solid var(--border); }
  .ticker-row:last-child { border-bottom: none; }
  .ticker-name { font-family: var(--font-mono); font-weight: 600; font-size: .85rem; }
  .ticker-sub  { font-size: .72rem; color: var(--muted); }
  .ticker-val  { font-family: var(--font-mono); font-size: .9rem; font-weight: 600; }
  .ticker-chg  { font-size: .78rem; }
  .ticker-chg.up   { color: var(--accent2); }
  .ticker-chg.down { color: var(--danger); }

  /* ---- refresh button ---- */
  .refresh-btn {
    font-family: var(--font-mono); font-size: .72rem; font-weight: 600;
    padding: 6px 14px; border-radius: 8px;
    border: 1px solid var(--accent); color: var(--accent);
    background: transparent; cursor: pointer; transition: all .15s;
  }
  .refresh-btn:hover { background: var(--accent); color: #fff; }

  @media (max-width: 1100px) {
    .stat-grid { grid-template-columns: repeat(2, 1fr); }
    .two-col   { grid-template-columns: 1fr; }
  }
  @media (max-width: 700px) {
    .sidebar   { display: none; }
    .stat-grid { grid-template-columns: 1fr; }
  }
  "
}

fn init_dashboard_socket(_) -> DashboardSocketInit {
  let dashboard = dashboard.component()
  let assert Ok(component) = lustre.start_server_component(dashboard, Nil)

  let self = process.new_subject()
  let selector =
    process.new_selector()
    |> process.select(self)

  server_component.register_subject(self)
  |> lustre.send(to: component)

  #(DashboardSocket(component:, self:), Some(selector))
}

fn loop_dashboard_socket(
  state: DashboardSocket,
  message: mist.WebsocketMessage(DashboardSocketMessage),
  connection: mist.WebsocketConnection,
) {
  case message {
    mist.Text(json) -> {
      case json.parse(json, server_component.runtime_message_decoder()) {
        Ok(runtime_message) -> lustre.send(state.component, runtime_message)
        Error(_) -> Nil
      }

      mist.continue(state)
    }

    mist.Binary(_) -> {
      mist.continue(state)
    }

    mist.Custom(client_message) -> {
      let json = server_component.client_message_to_json(client_message)
      let assert Ok(_) = mist.send_text_frame(connection, json.to_string(json))

      mist.continue(state)
    }

    mist.Closed | mist.Shutdown -> mist.stop()
  }
}

fn close_dashboard_socket(state: DashboardSocket) -> Nil {
  lustre.shutdown()
  |> lustre.send(to: state.component)
}
