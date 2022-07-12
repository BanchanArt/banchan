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
    this.events = this.items.map((item, idx) => {
      return [item, item.addEventListener('click', () => {
        Spotlight.show(this.items.map(item => {
          return { src: item.dataset.src, media: item.dataset.media }
        }), {
          infinite: true,
          autofit: false,
          download: true,
          index: idx + 1
        });
      })];
    });
  },

  removeListeners() {
    this.events.forEach(([item, ev]) => item.removeEventListener('click', ev));
  },

  updateItems() {
    this.items = [...this.el.querySelectorAll(".banchan-lightbox-item")];
  }
};

export { Lightbox };
