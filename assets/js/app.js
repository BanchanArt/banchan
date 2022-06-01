import "phoenix_html"
import { Socket, LongPoll } from "phoenix"
import topbar from "topbar"
import Hooks from "./_hooks"
import { LiveSocket } from "phoenix_live_view"

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
const liveSocket = new LiveSocket('/live', Socket, {
    params: {
        _csrf_token: csrfToken
    },
    hooks: Hooks
})

// liveSocket.socket.onError((_error, transport, establishedConnections) => {
//   if (transport === WebSocket && establishedConnections === 0) {
//     liveSocket.socket.replaceTransport(LongPoll);
//     liveSocket.socket.connect();
//   }
// });

document.addEventListener("DOMContentLoaded", () => {
  let theme = localStorage.getItem("theme")
  if (!theme) {
    theme = window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light"
  }
  document.documentElement.setAttribute("data-theme", theme);
})

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" })
window.addEventListener("phx:page-loading-start", _ => topbar.show())
window.addEventListener("phx:page-loading-stop", _ => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

