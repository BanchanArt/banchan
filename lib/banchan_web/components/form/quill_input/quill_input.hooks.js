import Quill from "quill";
import TurndownService from "turndown";
import * as marked from "marked";
import DOMPurify from "dompurify";

let QuillInput = {
  mounted() {
    this.td = new TurndownService();

    this.initEditor();
  },

  destroyed() {
    document.removeEventListener("dragenter", this.ondragenter);
    document.removeEventListener("dragover", this.ondragover);
    document.removeEventListener("dragleave", this.ondragleave);
    document.removeEventListener("drop", this.ondrop);
  },

  initEditor() {
    const el = this.el.querySelector(".editor");
    this.editor = new Quill(el, {
      theme: "snow",
      modules: {
        history: true,
        toolbar: [
          [{ header: [1, 2, 3, false] }],
          ['bold', 'italic', 'underline', 'strike'],
          [{ 'list': 'ordered' }, { 'list': 'bullet' }],
          ['blockquote'],
          ['clean']
        ]
      }
    });

    this.editor.on("text-change", (_x, _y, source) => {
      if (source === "user") {
        this.changedSinceLastUpdate = true;
        const md = this.getMarkdown();
        this.updateTextArea(md);
      }
    });

    this.handleEvent("markdown-updated", msg => {
      if (msg.id === this.el.id) {
        const md = this.getMarkdown();
        if (md !== msg.value && !this.changedSinceLastUpdate) {
          this.setMarkdown(msg.value);
        }
      }
    });

    this.editor.root.innerHTML = DOMPurify.sanitize(
      marked.parse(
        (this
          .el
          .querySelector('.input-textarea')
          .value || "")
          .replace(/^[\u201B\u200C\u200D\u200E\u200F\uFEFF]/, "")
      )
    );
  },

  getMarkdown() {
    return this
      .td
      .turndown(this.editor.root.innerHTML)
      .replace(/^[\u200B\u200C\u200D\u200E\u200F\uFEFF]/, "");
  },

  setMarkdown(md) {
    this.updateTextArea(md);
    this.editor.root.innerHTML = DOMPurify.sanitize(
      marked.parse(
        md.replace(/^[\u200B\u200C\u200D\u200E\u200F\uFEFF]/, "") || ""
      )
    );
  },

  updateTextArea(md) {
    const textarea = this.el.querySelector(".input-textarea");
    textarea.value = md || "";
    const evt = new Event("change", {
      bubbles: true,
      cancelable: true
    });
    textarea.dispatchEvent(evt);
  },

  initDragDrop() {
    let dragCounter = 0;

    this.ondragenter = document.addEventListener("dragenter", e => {
      e.preventDefault();
      e.stopPropagation();
      dragCounter += 1;
      if (e.dataTransfer.types.includes("Files") || e.dataTransfer.types.includes("application/x-moz-file")) {
        this.pushEventTo(this.el, "dragstart", {});
      }
    });

    this.ondragover = document.addEventListener("dragover", e => {
      e.dataTransfer.dropEffect = "none";
      if (e.dataTransfer.types.includes("Files") || e.dataTransfer.types.includes("application/x-moz-file")) {
        e.dataTransfer.dropEffect = "copy";
      }
    });

    this.ondragleave = document.addEventListener("dragleave", e => {
      e.preventDefault();
      e.stopPropagation();

      dragCounter -= 1;

      if (dragCounter <= 1) {
        this.pushEventTo(this.el, "dragend", {});
      }
    });

    this.ondrop = document.addEventListener("drop", e => {
      dragCounter -= 1;
      this.pushEventTo(this.el, "dragend", {});
    });
  }
};

export { QuillInput };
