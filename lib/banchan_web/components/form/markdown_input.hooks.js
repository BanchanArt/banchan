let MarkdownInput = {
  mounted() {
    let textarea = this.el.querySelector(".textarea");
    textarea.addEventListener("change", e => {
      this.pushEventTo(this.el, "change", { value: textarea.value })
    });
  }
};

export { MarkdownInput };
