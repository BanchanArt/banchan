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

    this.el.querySelector(".editor").addEventListener("keydown", e => {
      if (e.ctrlKey && e.key === 'Enter') {
        this.getInput().form?.dispatchEvent(
          new Event('submit', { bubbles: true, cancelable: true }));
      }
    });

    this.editor.on("text-change", debounce((_x, _y, source) => {
      if (source === "user") {
        const md = this.getMarkdown();
        this.setMarkdown(md, true, false);
      }
    }, 200));

    this.setMarkdown(this.textAreaMarkdown(), false);
  },

  getMarkdown() {
    const md =
      this
        .td
        .turndown(this.editor.root.innerHTML.replaceAll(/<p>\r?\n*<\/p>/g, ""))
        .replaceAll(/^[\u200B\u200C\u200D\u200E\u200F\uFEFF]/g, "");
    return md;
  },

  textAreaMarkdown() {
    return this
      .getInput()
      .value
      .replaceAll(/^[\u200B\u200C\u200D\u200E\u200F\uFEFF]/g, "");
  },

  setMarkdown(md, updateTextArea = true, updateEditor = true) {
    if (updateTextArea) {
      this.updateTextArea(md);
    }
    if (updateEditor) {
      const parsed = marked.parse(
        md.replaceAll(/^[\u200B\u200C\u200D\u200E\u200F\uFEFF]+/g, "") || "",
        { headerIds: false }
      )
      const sanitized = DOMPurify.sanitize(parsed).replaceAll(/<p>\r?\n+<\/p>/g, "")
        .replaceAll("<br>", "<p></p>")
        .replaceAll("<li><p></p></li>", "<li><br></li>")
        .replaceAll(/\n+/g, "");

      if (sanitized.replaceAll("<p></p>", "<p><br></p>") !== this.editor.root.innerHTML) {
        this.editor.root.innerHTML = sanitized;
      }
    }
  },

  updateTextArea(md) {
    const textarea = this.getInput();
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

  getInput() {
    return this.el.parentNode.querySelector(".input-textarea");
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
