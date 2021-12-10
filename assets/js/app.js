import "phoenix_html"
import Alpine from "alpinejs"
import persist from '@alpinejs/persist'
import { Socket } from "phoenix"
import topbar from "topbar"
import Hooks from "./_hooks"
import { LiveSocket } from "phoenix_live_view"
import "@themesberg/flowbite"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, { 
    dom: {
        onBeforeElUpdated(from, to){
            if (from.__x) {
                window.Alpine.clone(from.__x, to)
            }
        }
    },
    hooks: Hooks, 
    params: { 
            _csrf_token: csrfToken, 
            theme: - (window.matchMedia('(prefers-color-scheme: dark)').matches)
        }
    })

window.Alpine = Alpine

Alpine.start()
Alpine.plugin(persist)

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