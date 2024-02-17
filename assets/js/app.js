import './styles.js';
import "phoenix_html";
import { Socket, LongPoll } from "phoenix";
import topbar from "topbar";
import Hooks from "./_hooks";
import { LiveSocket } from "phoenix_live_view";
import { replaceIcons } from "./_hooks/BanchanWeb.Components.Icon.hooks";

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");
const orderSeed = document.querySelector("[data-order-seed]")?.dataset.orderSeed;
const liveSocket = new LiveSocket('/live', Socket, {
  params: {
    _csrf_token: csrfToken,
    order_seed: orderSeed == null ? null : parseInt(orderSeed)
  },
  hooks: Hooks
});

// liveSocket.socket.onError((_error, transport, establishedConnections) => {
//   liveSocket.socket.connect();
//   if (transport === WebSocket) {
//     liveSocket.socket.disconnect(() => {
//       liveSocket.socket.replaceTransport(LongPoll);
//       liveSocket.socket.connect();
//     })
//   }
// });

// Show progress bar on live navigation and form submits, with a delay to make
// things feel faster.
//
// See: https://fly.io/phoenix-files/make-your-liveview-feel-faster/#solution
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });

let topBarScheduled = undefined;
window.addEventListener("phx:page-loading-start", () => {
  if (!topBarScheduled) {
    topBarScheduled = setTimeout(() => topbar.show(), 120);
  };
});
window.addEventListener("phx:page-loading-stop", () => {
  clearTimeout(topBarScheduled);
  topBarScheduled = undefined;
  topbar.hide();
});

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;

replaceIcons();
