import Spotlight from "spotlight.js/src/js/spotlight.js";

const Lightbox = {
  mounted() {
    this.addListeners();
  },

  beforeUpdate() {
    this.removeListeners();
  },

  updated() {
    this.addListeners();
  },

  destroyed() {
    this.removeListeners();
  },

  addListeners() {
    this.updateItems();
    this.downloadControl = null;
    this.events = this.items.map((item, idx, items) => {
      return [item, item.addEventListener("click", () => {
        Spotlight.show(this.items.map(item => {
          let src = item.dataset.src;
          if (!src) {
            const img = item.querySelector("img");
            if (img) {
              src = img.src;
            }
          }
          return { src, media: item.dataset.media }
        }), {
          infinite: true,
          autofit: false,
          index: idx + 1,
          onshow: i => {
            Spotlight.removeControl("banchan-download");
            this.downloadControl = Spotlight.addControl("banchan-download", () => {
              this.download(this.items[i - 1].dataset.download)
            });
          },
          onchange: (i) => {
            Spotlight.removeControl("banchan-download");
            if (this.items[i - 1].dataset.download) {
              this.downloadControl = Spotlight.addControl("banchan-download", () => {
                this.download(this.items[i - 1].dataset.download)
              });
            }
          },
          onclose: () => {
            Spotlight.removeControl("banchan-download");
          }
        });
      })];
    });
  },

  removeListeners() {
    this.events.forEach(([item, ev]) => item.removeEventListener("click", ev));
  },

  updateItems() {
    this.items = [...this.el.querySelectorAll(".banchan-lightbox-item")];
  },

  download(src) {
    const link = document.createElement("a");
    link.href = src;
    link.download = true;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  }
};

export { Lightbox };
