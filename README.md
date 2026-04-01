# Lustre Admin Dashboard

A server-driven admin dashboard built with [Gleam](https://gleam.run) and [Lustre](https://lustre.build), demonstrating a fullstack architecture with server-side state management and real-time WebSocket updates.

## Overview

This project is split into two Gleam packages:

- **`server/`** — Erlang/OTP backend using Wisp + Mist. Owns all application state and renders UI via Lustre server components over WebSocket.
- **`client/`** — Minimal JavaScript frontend compiled from Gleam. Establishes the WebSocket connection and delegates all rendering to the server.

All state lives on the server. The client is a thin WebSocket bridge.

## Features

- Server-driven UI via Lustre server components
- Real-time updates over WebSocket
- 4-section navigation: Overview, Users, Orders, Activity
- KPI metric cards with live data simulation (refresh button)
- User and order tables with status badges
- Activity feed timeline
- Responsive dark theme (mobile breakpoints at 700px and 1100px)
- No database — mock data with pseudo-random variation

## Architecture

```
Browser
  └── client.gleam (Gleam → JS)
        └── WebSocket /ws
              └── server.gleam (Gleam → Erlang/OTP)
                    └── dashboard.gleam (Lustre component)
```

When a user visits the app:

1. Server returns the HTML bootstrap page with inline CSS.
2. Browser loads the Lustre client runtime and executes the compiled client app.
3. Client opens a WebSocket to `/ws`.
4. Server instantiates a `dashboard` Lustre component per connection.
5. All user interactions (nav clicks, refresh) send messages to the server.
6. Server updates model and pushes a new view diff to the client.

## Project Structure

```
lustre-admin-dashboard/
├── podman_run.sh          # Runs nginx reverse proxy via Podman
├── conf/
│   └── default.conf       # Nginx config with WebSocket proxy
├── server/
│   ├── gleam.toml
│   ├── src/
│   │   ├── server.gleam   # HTTP server, routing, WebSocket handler, CSS
│   │   └── dashboard.gleam # Lustre component: model, messages, view
│   └── priv/static/
│       ├── index.html
│       ├── dashboard.css
│       └── client.js      # Compiled client bundle
└── client/
    ├── gleam.toml         # target = "javascript"
    └── src/
        └── client.gleam   # WebSocket connector
```

## Getting Started

### Prerequisites

- [Gleam](https://gleam.run/getting-started/) >= 1.14.0
- Erlang/OTP >= 28
- Node.js (for compiling the client)

### Run the server

```bash
cd server
gleam run
```

The server listens on `http://localhost:3000`.

### Build and watch the client

```bash
cd client
gleam run -m lustre/dev start
```

The compiled client JS is output to `server/priv/static/client.js`.

### Run tests

```bash
cd server && gleam test
cd client && gleam test
```

## Deployment

An nginx reverse proxy config and Podman helper script are included.

Start the nginx container (proxies port 8080 → backend at port 3000):

```bash
./podman_run.sh
```

The nginx config handles WebSocket upgrade headers and a 3600s connection timeout.

## Key Dependencies

| Package | Purpose |
|---|---|
| `lustre` | UI framework (client + server components) |
| `wisp` | HTTP request handling |
| `mist` | WebSocket server (Erlang) |
| `gleam_json` | JSON encode/decode for WebSocket messages |
| `gleam_otp` | Process supervision |
| `lustre_dev_tools` | Client dev server and bundler |

## Dashboard Sections

| Section | Contents |
|---|---|
| Overview | 4 KPI stat cards, recent orders table, KPI ticker strip |
| Users | User table with roles (Admin, Editor, Viewer) and status badges |
| Orders | Order table with amounts and status (Completed, Pending, Cancelled) |
| Activity | Timeline feed of system events with color-coded categories |
