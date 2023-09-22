const OUTS = [["transition", "ease-in", "duration-200"], ["opacity-100"], ["opacity-0"]];
const TIME = 200;

export const FancySelect = {
  mounted() {
    this.highlighted = 0;

    this.clickAway = document.addEventListener("click", (e) => {
      this.hide();
    });
    this.escape = document.addEventListener("keydown", (e) => {
      if (e.key === "Escape") {
        this.hide();
      }
    });
    this.el.querySelector("button").addEventListener("click", (e) => {
      this.toggle();
      e.stopPropagation();
    });
    this.el.querySelector("ul").addEventListener("click", (e) => {
      this.toggle();
      e.stopPropagation();
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

    this.updated();
  },

  updated() {
    this.updateHighlights();
    this.updateListeners();
  },

  destroyed() {
    document.removeEventListener("click", this.clickAway);
    document.removeEventListener("keydown", this.escape);
  },

  hide() {
    liveSocket.execJS(this.el.querySelector("ul"), JSON.stringify([["hide", {
      transition: OUTS,
      time: TIME
    }]]));
  },

  toggle() {
    liveSocket.execJS(this.el.querySelector("ul"), JSON.stringify([["toggle", {
      outs: OUTS,
      time: TIME
    }]]));
  },

  select() {
    const input = this.el.querySelector("input");
    if (("" + this.highlighted) !== input.value) {
      input.value = this.highlighted;
      input.dispatchEvent(new Event("input", { bubbles: true }));
    }
  },

  up() {
    const items = this.el.querySelectorAll("li");
    const max = items.length - 1;
    this.highlighted = this.highlighted === 0 ? max : this.highlighted - 1;
    this.updateHighlights();
  },

  down() {
    const items = this.el.querySelectorAll("li");
    const max = items.length - 1;
    this.highlighted = this.highlighted === max ? 0 : this.highlighted + 1;
    this.updateHighlights();
  },

  updateHighlights() {
    this.el.querySelectorAll("li").forEach((item, i) => {
      if (i === this.highlighted) {
        item.classList.add("bg-base-200", "text-base-content")
        item.classList.remove("bg-base-100", "text-base-content")
      } else {
        item.classList.add("bg-base-100", "text-base-content")
        item.classList.remove("bg-base-200", "text-base-content")
      }
    });
  },

  updateListeners() {
    if (!this.itemListeners) {
      this.itemListeners = [];
    }
    for (const [item, clickListener, mouseListener] of this.itemListeners) {
      item.removeEventListener("click", clickListener);
      item.removeEventListener("mouseenter", mouseListener);
    }
    const children = this.el.querySelectorAll("li");
    for (let i = 0; i < children.length; i++) {
      const child = children[i];
      [child,
        child.addEventListener("click", (_e) => {
          this.highlighted = i;
          this.select();
        }),
        child.addEventListener("mouseenter", (_e) => {
          this.highlighted = i;
          this.updateHighlights();
        })
      ]
    }
  }
};
