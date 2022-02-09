let MarkdownInput = {
  mounted() {
    let textarea = this.el.querySelector(".textarea");
    this.pushEventTo(this.el, "change", { value: textarea.value })
    textarea.addEventListener("change", e => {
      this.pushEventTo(this.el, "change", { value: textarea.value })
    });
  }
};

export { MarkdownInput };
