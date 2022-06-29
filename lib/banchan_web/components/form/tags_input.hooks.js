let TagsInput = {
  mounted() {
    this.inputField = this.el.querySelector(".input-field")
    this.hiddenVal = this.el.querySelector(".hidden-val");

    this.handleEvent("change", () => {
      this.inputField.value = "";
      this.hiddenVal.dispatchEvent(new Event("change", { bubbles: true, cancelable: true }));
    });
  }
};

export { TagsInput };
