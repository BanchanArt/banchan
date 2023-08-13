import Quill from "quill";
import TurndownService from "turndown";
import * as marked from "marked";
import DOMPurify from "dompurify";

let QuillInput = {
  mounted() {
    this.td = new TurndownService().addRule("break", {
      filter: ["br"],
      replacement: function (_) {
        return "<br/>\n";
      }
    });

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
          ['bold', 'italic'],
          [{ 'list': 'ordered' }, { 'list': 'bullet' }],
          ['blockquote'],
          ['clean']
        ]
      }
    });

    this.editor.on("text-change", debounce((_x, _y, source) => {
      if (source === "user" && !this.updating) {
        this.updating = true;
        this.setMarkdown(this.getMarkdown(), true, false);
      }
      if (this.updating) {
        this.updating = false;
      }
    }, 200));

    this.inputListener = this.el.querySelector('.input-textarea').addEventListener("input", e => {
      if (!this.updating) {
        // NB(zkat): This is a dirty hack to work around some obnoxious
        // round-tripping behavior that keeps messing with the QuillInput.
        this.el.querySelector('.input-textarea').removeEventListener("input", this.inputListener);
        this.setMarkdown(e.target.value, false);
      }
    });

    this.handleEvent("set_markdown", ({ id, value }) => {
      if (this.el.id === id && !this.updating) {
        this.setMarkdown(value, false);
      }
    });

    this.editor.root.innerHTML = DOMPurify.sanitize(
      marked.parse(
        (this
          .el
          .querySelector('.input-textarea')
          .value || "")
          .replaceAll(/^[\u201B\u200C\u200D\u200E\u200F\uFEFF]/g, "")
      )
    );
  },

  getMarkdown() {
    return this
      .td
      .turndown(this.editor.root.innerHTML.replaceAll(/<p>\r?\n*<\/p>/g, ""))
      .replaceAll(/^[\u200B\u200C\u200D\u200E\u200F\uFEFF]/g, "");
  },

  setMarkdown(md, updateTextArea = true, updateEditor = true) {
    if (updateTextArea) {
      this.updateTextArea(md);
    }
    if (updateEditor) {
      const parsed = DOMPurify.sanitize(
        marked.parse(
          md.replaceAll(/^[\u200B\u200C\u200D\u200E\u200F\uFEFF]+/g, "") || "",
          { headerIds: false }
        )
      ).replaceAll(/<p>\r?\n*<\/p>/g, "")
        .replaceAll("<br>", "<p></p>")
        .replaceAll(/\n+/g, "");

      if (parsed.replaceAll("<p></p>", "<p><br></p>") !== this.editor.root.innerHTML) {
        this.editor.root.innerHTML = parsed;
      }
    }
  },

  updateTextArea(md) {
    const textarea = this.el.querySelector(".input-textarea");
    if (textarea.value === md) {
      return;
    }
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
