const OUTS = [["transition", "ease-in", "duration-200"], ["opacity-100"], ["opacity-0"]];
const TIME = 200;

export const FancySelect = {
  mounted() {
    this.highlighted = 0;

    this.el.addEventListener("click", (_e) => {
      this.toggle();
    });
    this.el.addEventListener("keydown", (e) => {
      switch (e.key) {
        case "Enter":
          e.stopPropagation();
          this.select();
          this.toggle();
          break;
        case "ArrowDown":
          this.down();
          break;
        case "ArrowUp":
          this.up();
          break;
      }
      e.preventDefault();
    });

    this.updateHighlights();
  },

  updated() {
    this.updateHighlights();
  },

  toggle() {
    liveSocket.execJS(this.el.querySelector("ul"), JSON.stringify([["toggle", {
      outs: OUTS,
      time: TIME
    }]]));
  },

  select() {
    this.pushEventTo(this.el, "selected", { selected: this.highlighted });
  },

  up() {
    const items = this.el.querySelectorAll("li");
    const max = items.length - 1;
    const old = this.highlighted;
    this.highlighted = this.highlighted === 0 ? max : this.highlighted - 1;
    this.updateHighlights();
  },

  down() {
    const items = this.el.querySelectorAll("li");
    const max = items.length - 1;
    const old = this.highlighted;
    this.highlighted = this.highlighted === max ? 0 : this.highlighted + 1;
    this.updateHighlights();
  },

  updateHighlights() {
    this.el.querySelectorAll("li").forEach((item, i) => {
      if (i === this.highlighted) {
        item.classList.add("bg-primary", "text-primary-content")
        item.classList.remove("bg-base-200", "text-base-content")
      } else {
        item.classList.add("bg-base-200", "text-base-content")
        item.classList.remove("bg-primary", "text-primary-content")
      }
    });
  }
};
