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

    this.editor.on("text-change", debounce((_x, _y, source) => {
      if (source === "user" && !this.fromSetMarkdown) {
        this.fromTextChange = true;
        this.setMarkdown(this.getMarkdown(), true, false);
        this.fromTextChange = false;
      }
      if (this.fromSetMarkdown) {
        this.fromSetMarkdown = false;
      }
    }, 200));

    this.el.querySelector('.input-textarea').addEventListener("input", _e => {
      if (!this.fromTextChange && !this.fromSetMarkdown) {
        this.setMarkdown(this.getMarkdown(), false);
      }
    });

    this.handleEvent("set_markdown", ({ id, value })=> {
      if (this.el.id === id) {
        this.fromSetMarkdown = true;
        this.setMarkdown(value, false);
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

  setMarkdown(md, updateTextArea = true, updateEditor = true) {
    if (updateTextArea) {
      this.updateTextArea(md);
    }
    if (updateEditor) {
      this.editor.root.innerHTML = DOMPurify.sanitize(
        marked.parse(
          md.replace(/^[\u200B\u200C\u200D\u200E\u200F\uFEFF]/, "") || ""
        )
      );
    }
  },

  updateTextArea(md) {
    const textarea = this.el.querySelector(".input-textarea");
    textarea.value = md || "";
    const evt = new Event("input", {
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
