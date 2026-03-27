import gleam/int
import gleam/list
import lustre
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub fn component() -> lustre.App(_, Model, Msg) {
  lustre.application(init, update, view)
}

// ── Model ───────────────────────────────────────────────────────────────────

pub type Section {
  Overview
  Users
  Orders
  Activity
}

pub type UserRecord {
  UserRecord(
    id: Int,
    name: String,
    email: String,
    role: String,
    status: UserStatus,
    joined: String,
  )
}

pub type UserStatus {
  Active
  Pending
  Inactive
}

pub type OrderRecord {
  OrderRecord(
    id: String,
    customer: String,
    amount: String,
    status: String,
    date: String,
  )
}

pub type ActivityEvent {
  ActivityEvent(kind: String, text: String, time: String)
}

pub type Metric {
  Metric(name: String, symbol: String, value: String, change: String, up: Bool)
}

pub type Model {
  Model(
    section: Section,
    tick: Int,
    metrics: List(Metric),
    users: List(UserRecord),
    orders: List(OrderRecord),
    activity: List(ActivityEvent),
    tickers: List(Metric),
  )
}

fn initial_metrics() -> List(Metric) {
  [
    Metric("Total Revenue", "$", "$482,901", "+12.4%", True),
    Metric("Active Users", "", "14,320", "+8.1%", True),
    Metric("New Orders", "", "3,841", "+5.6%", True),
    Metric("Churn Rate", "%", "2.4%", "-0.3%", False),
  ]
}

fn initial_users() -> List(UserRecord) {
  [
    UserRecord(
      1,
      "Alice Martin",
      "alice@acme.io",
      "Admin",
      Active,
      "Jan 12, 2024",
    ),
    UserRecord(2, "Bob Chen", "bob@acme.io", "Editor", Active, "Feb 3, 2024"),
    UserRecord(
      3,
      "Clara Osei",
      "clara@acme.io",
      "Viewer",
      Pending,
      "Mar 17, 2024",
    ),
    UserRecord(
      4,
      "David Lim",
      "david@acme.io",
      "Editor",
      Inactive,
      "Apr 5, 2024",
    ),
    UserRecord(
      5,
      "Emma Nakamura",
      "emma@acme.io",
      "Admin",
      Active,
      "May 22, 2024",
    ),
  ]
}

fn initial_orders() -> List(OrderRecord) {
  [
    OrderRecord("#10231", "Alice Martin", "$249.00", "Completed", "Jun 1, 2024"),
    OrderRecord("#10232", "Bob Chen", "$89.50", "Pending", "Jun 2, 2024"),
    OrderRecord("#10233", "Clara Osei", "$512.00", "Completed", "Jun 2, 2024"),
    OrderRecord("#10234", "David Lim", "$34.99", "Cancelled", "Jun 3, 2024"),
    OrderRecord("#10235", "Emma Nakamura", "$799.00", "Pending", "Jun 4, 2024"),
  ]
}

fn initial_activity() -> List(ActivityEvent) {
  [
    ActivityEvent("green", "New user Emma Nakamura registered", "2 min ago"),
    ActivityEvent("blue", "Order #10235 placed by Emma Nakamura", "5 min ago"),
    ActivityEvent("yellow", "Order #10232 is awaiting payment", "18 min ago"),
    ActivityEvent(
      "red",
      "Order #10234 was cancelled by David Lim",
      "34 min ago",
    ),
    ActivityEvent("blue", "Clara Osei account pending verification", "1 hr ago"),
    ActivityEvent("green", "Server component connected (WebSocket)", "startup"),
  ]
}

fn initial_tickers() -> List(Metric) {
  [
    Metric("MRR", "$", "$40,242", "+2.3%", True),
    Metric("ARR", "$", "$482,901", "+12.4%", True),
    Metric("ARPU", "$", "$33.72", "+1.1%", True),
    Metric("LTV", "$", "$182.40", "-0.8%", False),
    Metric("CAC", "$", "$14.20", "-3.2%", False),
  ]
}

fn init(_flags) -> #(Model, Effect(Msg)) {
  let model =
    Model(
      section: Overview,
      tick: 0,
      metrics: initial_metrics(),
      users: initial_users(),
      orders: initial_orders(),
      activity: initial_activity(),
      tickers: initial_tickers(),
    )
  #(model, effect.none())
}

// ── Messages ─────────────────────────────────────────────────────────────────

pub type Msg {
  NavigateTo(Section)
  RefreshMetrics
  Tick
}

// ── Update ───────────────────────────────────────────────────────────────────

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    NavigateTo(section) -> #(Model(..model, section: section), effect.none())

    RefreshMetrics -> {
      // Rotate the tick counter to create the appearance of live data
      let tick = model.tick + 1
      let metrics = jiggle_metrics(model.metrics, tick)
      let tickers = jiggle_metrics(model.tickers, tick + 3)
      let ev = ActivityEvent("blue", "Metrics refreshed by admin", "just now")
      #(
        Model(
          ..model,
          tick: tick,
          metrics: metrics,
          tickers: tickers,
          activity: [ev, ..model.activity],
        ),
        effect.none(),
      )
    }

    Tick ->
      // Silently advance a tick for potential future animation hooks
      #(Model(..model, tick: model.tick + 1), effect.none())
  }
}

// Perturb values slightly each refresh (simulates live data without a DB)
fn jiggle_metrics(metrics: List(Metric), seed: Int) -> List(Metric) {
  list.index_map(metrics, fn(m, i) {
    let bump = { seed + i } % 5
    case bump {
      0 -> Metric(..m, change: "+0.1%", up: True)
      1 -> Metric(..m, change: "+1.2%", up: True)
      2 -> Metric(..m, change: "-0.5%", up: False)
      3 -> Metric(..m, change: "+3.1%", up: True)
      _ -> Metric(..m, change: "-1.0%", up: False)
    }
  })
}

// ── View ─────────────────────────────────────────────────────────────────────

fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("shell")], [
    view_sidebar(model.section),
    html.div([attribute.class("main")], [
      view_topbar(model.section),
      html.div([attribute.class("content")], [
        case model.section {
          Overview -> view_overview(model)
          Users -> view_users(model.users)
          Orders -> view_orders(model.orders)
          Activity -> view_activity(model.activity)
        },
      ]),
    ]),
  ])
}

// Sidebar ─────────────────────────────────────────────────────────────────────

fn view_sidebar(current: Section) -> Element(Msg) {
  html.nav([attribute.class("sidebar")], [
    html.div([attribute.class("sidebar-logo")], [
      html.text("◈ admin"),
      html.span([], [html.text(".gleam")]),
    ]),
    html.div([attribute.class("sidebar-nav")], [
      nav_item(current, Overview, icon_overview(), "Overview"),
      nav_item(current, Users, icon_users(), "Users"),
      nav_item(current, Orders, icon_orders(), "Orders"),
      nav_item(current, Activity, icon_activity(), "Activity"),
    ]),
  ])
}

fn nav_item(
  current: Section,
  target: Section,
  icon: Element(Msg),
  label: String,
) -> Element(Msg) {
  let cls = case current == target {
    True -> "nav-item active"
    False -> "nav-item"
  }
  html.button([attribute.class(cls), event.on_click(NavigateTo(target))], [
    icon,
    html.text(label),
  ])
}

// Top bar ─────────────────────────────────────────────────────────────────────

fn view_topbar(section: Section) -> Element(Msg) {
  html.div([attribute.class("topbar")], [
    html.span([attribute.class("topbar-title")], [
      html.text(section_label(section)),
    ]),
    html.div([attribute.class("topbar-actions")], [
      html.span([attribute.class("badge")], [html.text("● live")]),
      html.span([attribute.class("badge warn")], [html.text("Erlang/OTP")]),
      html.div([attribute.class("avatar")], [html.text("AD")]),
    ]),
  ])
}

fn section_label(s: Section) -> String {
  case s {
    Overview -> "Overview"
    Users -> "User Management"
    Orders -> "Orders"
    Activity -> "Activity Feed"
  }
}

// Overview ────────────────────────────────────────────────────────────────────

fn view_overview(model: Model) -> Element(Msg) {
  html.div([], [
    // Stat cards
    html.div(
      [attribute.class("stat-grid")],
      list.map(model.metrics, view_stat_card),
    ),

    // Two-column section
    html.div([attribute.class("two-col")], [
      // Recent orders
      html.div([attribute.class("card")], [
        html.div(
          [
            attribute.class("section-header"),
            attribute.styles([#("padding", "16px 20px 0")]),
          ],
          [
            html.span([attribute.class("section-title")], [
              html.text("Recent Orders"),
            ]),
            html.button(
              [attribute.class("btn"), event.on_click(NavigateTo(Orders))],
              [html.text("View all")],
            ),
          ],
        ),
        view_orders_table(list.take(model.orders, 3)),
      ]),

      // Tickers / KPI strip
      html.div([attribute.class("card")], [
        html.div(
          [
            attribute.class("section-header"),
            attribute.styles([#("padding", "16px 20px 0")]),
          ],
          [
            html.span([attribute.class("section-title")], [html.text("KPIs")]),
            html.button(
              [attribute.class("refresh-btn"), event.on_click(RefreshMetrics)],
              [html.text("↻ Refresh")],
            ),
          ],
        ),
        html.div([], list.map(model.tickers, view_ticker_row)),
      ]),
    ]),
  ])
}

fn view_stat_card(m: Metric) -> Element(Msg) {
  let delta_cls = case m.up {
    True -> "stat-delta"
    False -> "stat-delta neg"
  }
  html.div([attribute.class("stat-card")], [
    html.span([attribute.class("stat-label")], [html.text(m.name)]),
    html.span([attribute.class("stat-value")], [html.text(m.value)]),
    html.span([attribute.class(delta_cls)], [
      html.text(m.change <> " vs last month"),
    ]),
  ])
}

fn view_ticker_row(m: Metric) -> Element(Msg) {
  let chg_cls = case m.up {
    True -> "ticker-chg up"
    False -> "ticker-chg down"
  }
  html.div([attribute.class("ticker-row")], [
    html.div([], [
      html.div([attribute.class("ticker-name")], [html.text(m.name)]),
    ]),
    html.div([attribute.styles([#("text-align", "right")])], [
      html.div([attribute.class("ticker-val")], [html.text(m.value)]),
      html.div([attribute.class(chg_cls)], [html.text(m.change)]),
    ]),
  ])
}

// Users ───────────────────────────────────────────────────────────────────────

fn view_users(users: List(UserRecord)) -> Element(Msg) {
  html.div([], [
    html.div([attribute.class("section-header")], [
      html.span([attribute.class("section-title")], [html.text("All Users")]),
      html.button([attribute.class("btn primary")], [html.text("+ Invite User")]),
    ]),
    html.div([attribute.class("card")], [
      html.table([], [
        html.thead([], [
          html.tr([], [
            html.th([], [html.text("ID")]),
            html.th([], [html.text("Name")]),
            html.th([], [html.text("Email")]),
            html.th([], [html.text("Role")]),
            html.th([], [html.text("Status")]),
            html.th([], [html.text("Joined")]),
          ]),
        ]),
        html.tbody([], list.map(users, view_user_row)),
      ]),
    ]),
  ])
}

fn view_user_row(u: UserRecord) -> Element(Msg) {
  html.tr([], [
    html.td([], [html.text("#" <> int.to_string(u.id))]),
    html.td([], [html.text(u.name)]),
    html.td([attribute.styles([#("color", "var(--muted)")])], [
      html.text(u.email),
    ]),
    html.td([], [html.text(u.role)]),
    html.td([], [view_status_pill(u.status)]),
    html.td(
      [
        attribute.styles([
          #("font-family", "var(--font-mono)"),
          #("font-size", ".8rem"),
        ]),
      ],
      [html.text(u.joined)],
    ),
  ])
}

fn view_status_pill(s: UserStatus) -> Element(Msg) {
  let #(cls, label) = case s {
    Active -> #("status-pill active", "Active")
    Pending -> #("status-pill pending", "Pending")
    Inactive -> #("status-pill inactive", "Inactive")
  }
  html.span([attribute.class(cls)], [html.text(label)])
}

// Orders ──────────────────────────────────────────────────────────────────────

fn view_orders(orders: List(OrderRecord)) -> Element(Msg) {
  html.div([], [
    html.div([attribute.class("section-header")], [
      html.span([attribute.class("section-title")], [html.text("All Orders")]),
      html.button([attribute.class("btn")], [html.text("Export CSV")]),
    ]),
    html.div([attribute.class("card")], [
      view_orders_table(orders),
    ]),
  ])
}

fn view_orders_table(orders: List(OrderRecord)) -> Element(Msg) {
  html.table([], [
    html.thead([], [
      html.tr([], [
        html.th([], [html.text("Order")]),
        html.th([], [html.text("Customer")]),
        html.th([], [html.text("Amount")]),
        html.th([], [html.text("Status")]),
        html.th([], [html.text("Date")]),
      ]),
    ]),
    html.tbody([], list.map(orders, view_order_row)),
  ])
}

fn view_order_row(o: OrderRecord) -> Element(Msg) {
  let status_cls = case o.status {
    "Completed" -> "status-pill active"
    "Pending" -> "status-pill pending"
    _ -> "status-pill inactive"
  }
  html.tr([], [
    html.td([attribute.styles([#("font-family", "var(--font-mono)")])], [
      html.text(o.id),
    ]),
    html.td([], [html.text(o.customer)]),
    html.td(
      [
        attribute.styles([
          #("font-family", "var(--font-mono)"),
          #("font-weight", "600"),
        ]),
      ],
      [html.text(o.amount)],
    ),
    html.td([], [
      html.span([attribute.class(status_cls)], [html.text(o.status)]),
    ]),
    html.td(
      [attribute.styles([#("color", "var(--muted)"), #("font-size", ".8rem")])],
      [html.text(o.date)],
    ),
  ])
}

// Activity ────────────────────────────────────────────────────────────────────

fn view_activity(events: List(ActivityEvent)) -> Element(Msg) {
  html.div([], [
    html.div([attribute.class("section-header")], [
      html.span([attribute.class("section-title")], [html.text("Activity Feed")]),
      html.span([attribute.class("badge")], [
        html.text(int.to_string(list.length(events)) <> " events"),
      ]),
    ]),
    html.div([attribute.class("card feed")], list.map(events, view_feed_item)),
  ])
}

fn view_feed_item(ev: ActivityEvent) -> Element(Msg) {
  html.div([attribute.class("feed-item")], [
    html.div([attribute.class("feed-dot " <> ev.kind)], []),
    html.div([], [
      html.div([attribute.class("feed-text")], [html.text(ev.text)]),
      html.div([attribute.class("feed-time")], [html.text(ev.time)]),
    ]),
  ])
}

// Icons (inline SVG) ──────────────────────────────────────────────────────────

fn icon_overview() -> Element(Msg) {
  element.unsafe_raw_html(
    "svg",
    "svg",
    [
      attribute.attribute("xmlns", "http://www.w3.org/2000/svg"),
      attribute.attribute("viewBox", "0 0 24 24"),
      attribute.attribute("fill", "none"),
      attribute.attribute("stroke", "currentColor"),
      attribute.attribute("stroke-width", "2"),
    ],
    "<rect x='3' y='3' width='7' height='7'/><rect x='14' y='3' width='7' height='7'/><rect x='3' y='14' width='7' height='7'/><rect x='14' y='14' width='7' height='7'/>",
  )
}

fn icon_users() -> Element(Msg) {
  element.unsafe_raw_html(
    "svg",
    "svg",
    [
      attribute.attribute("xmlns", "http://www.w3.org/2000/svg"),
      attribute.attribute("viewBox", "0 0 24 24"),
      attribute.attribute("fill", "none"),
      attribute.attribute("stroke", "currentColor"),
      attribute.attribute("stroke-width", "2"),
    ],
    "<path d='M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2'/><circle cx='9' cy='7' r='4'/><path d='M23 21v-2a4 4 0 0 0-3-3.87'/><path d='M16 3.13a4 4 0 0 1 0 7.75'/>",
  )
}

fn icon_orders() -> Element(Msg) {
  element.unsafe_raw_html(
    "svg",
    "svg",
    [
      attribute.attribute("xmlns", "http://www.w3.org/2000/svg"),
      attribute.attribute("viewBox", "0 0 24 24"),
      attribute.attribute("fill", "none"),
      attribute.attribute("stroke", "currentColor"),
      attribute.attribute("stroke-width", "2"),
    ],
    "<path d='M6 2L3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4z'/><line x1='3' y1='6' x2='21' y2='6'/><path d='M16 10a4 4 0 0 1-8 0'/>",
  )
}

fn icon_activity() -> Element(Msg) {
  element.unsafe_raw_html(
    "svg",
    "svg",
    [
      attribute.attribute("xmlns", "http://www.w3.org/2000/svg"),
      attribute.attribute("viewBox", "0 0 24 24"),
      attribute.attribute("fill", "none"),
      attribute.attribute("stroke", "currentColor"),
      attribute.attribute("stroke-width", "2"),
    ],
    "<polyline points='22 12 18 12 15 21 9 3 6 12 2 12'/>",
  )
}

// ── Public API ────────────────────────────────────────────────────────────────

pub fn app() -> lustre.App(Nil, Model, Msg) {
  lustre.application(init, update, view)
}
