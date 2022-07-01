let TagsInput = {
  eventTarget() {
    return this.inputField.dataset.eventTarget == "live_view"
      ? "[data-phx-main=\"true\"]"
      : this.inputField.dataset.eventTarget;
  },
  mounted() {
    this.inputField = this.el.querySelector(".input-field");
    this.tagsList = this.el.querySelector(".tags-list");
    this.hiddenVal = this.el.querySelector(".hidden-val");

    this.inputField.addEventListener("input", debounce(e => {
      this.pushEventTo(this.eventTarget(), "autocomplete", { value: e.target.value });
    }, 200, false));

    this.inputField.addEventListener("blur", () => {
      this.pushEventTo(this.eventTarget(), "autocomplete", { value: "" });
    });

    this.inputField.addEventListener("focus", e => {
      this.pushEventTo(this.eventTarget(), "autocomplete", { value: e.target.value });
    });

    this.tagsList.addEventListener("click", () => {
      this.inputField.focus();
    });

    this.inputField.addEventListener("keydown", e => {
      if (e.key === "Enter") {
        e.preventDefault();
      }
    });

    this.tagsList.addEventListener("keydown", e => {
      if (e.key === "ArrowUp" || e.key === "ArrowDown") {
        e.preventDefault();
      }
    });

    this.handleEvent("change", () => {
      this.inputField.value = "";
      this.hiddenVal.dispatchEvent(new Event("change", { bubbles: true, cancelable: true }));
    });
  }
};

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

export { TagsInput };
