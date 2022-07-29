function debounce(func, wait, immediate) {
  var timeout;
  return function () {
    var context = this, args = arguments;
    var later = function () {
      timeout = null;
      if (!immediate) func.apply(context, args);
    };
    var callNow = immediate && !timeout;
    clearTimeout(timeout);
    timeout = setTimeout(later, wait);
    if (callNow) func.apply(context, args);
  };
};

let TagsInput = {
  eventTarget() {
    return this.inputField.dataset.eventTarget == "live_view"
      ? "[data-phx-main=\"true\"]"
      : this.inputField.dataset.eventTarget;
  },

  setUpListeners() {
    this.inputField = this.el.querySelector(".input-field");
    this.tagsList = this.el.querySelector(".tags-list");
    this.hiddenVal = this.el.querySelector(".hidden-val");

    this.handlers = {
      input: this.inputField.addEventListener("input", debounce(e => {
        this.pushEventTo(this.eventTarget(), "autocomplete", { value: e.target.value });
      }, 200, false)),
      click: this.tagsList.addEventListener("click", () => {
        this.inputField.focus();
      }),
      inputKeydown: this.inputField.addEventListener("keydown", e => {
        if (e.key === "Enter" || e.key === "Tab") {
          e.preventDefault();
        }
      }),
      tagsKeydown: this.tagsList.addEventListener("keydown", e => {
        if (e.key === "ArrowUp" || e.key === "ArrowDown") {
          e.preventDefault();
        }
      })
    };
  },

  tearDownListeners() {
    if (this.handlers) {
      this.inputField.removeEventListener("input", this.handlers.input);
      this.tagsList.removeEventListener("click", this.handlers.click);
      this.inputField.removeEventListener("keydown", this.handlers.inputKeydown);
      this.tagsList.removeEventListener("keydown", this.handlers.tagsKeydown);
      this.handlers = null;
      this.inputField = null;
      this.tagsList = null;
      this.hiddenVal = null;
    }
  },

  mounted() {
    this.setUpListeners();
    this.handleEvent("change", ({ id: id }) => {
      if (this.el.id === id) {
        this.inputField.value = "";
        this.hiddenVal.dispatchEvent(new Event("change", { bubbles: true, cancelable: true }));
      }
    });
  },

  updated() {
    this.setUpListeners();
  },

  beforeUpdate() {
    this.tearDownListeners();
  },

  destroyed() {
    this.tearDownListeners();
  }
};

export { TagsInput };
