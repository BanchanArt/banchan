import Quill from "quill";
import DOMPurify from "dompurify";

let QuillInput = {
  mounted() {
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
    this.initialized = false;
    this.editor = new Quill(el, {
      theme: "snow",
      modules: {
        history: true,
        toolbar: [
          [{ header: [1, 2, 3, false] }],
          ['bold', 'italic', 'underline'],
          [{ 'list': 'ordered' }, { 'list': 'bullet' }],
          ['blockquote'],
          ['link'],
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
        if (!this.initialized) {
          this.initialized = true;
        }
        if (this.updating) {
          this.updating = false;
          return;
        }
        const text = this.getRichText();
        this.setRichText(text, true, false);
      }
    }, 200));

    this.handleEvent("set_rich_text", ({ id }) => {
      if (this.el.id === id && !this.el.contains(document.activeElement)) {
        if (this.initialized) {
          this.updating = true;
        }
        this.setRichText(this.textAreaRichText(), false, true);
      }
    });

    this.setRichText(this.textAreaRichText(), false);
  },

  getRichText() {
    return this.editor.root.innerHTML
      .replaceAll(/<p>\r?\n*<\/p>/g, "")
      .replaceAll(/^[\u200B\u200C\u200D\u200E\u200F\uFEFF]/g, "");
  },

  textAreaRichText() {
    return this
      .getInput()
      .value
      .replaceAll(/^[\u200B\u200C\u200D\u200E\u200F\uFEFF]/g, "");
  },

  setRichText(text, updateTextArea = true, updateEditor = true) {
    if (updateTextArea && text) {
      this.updateTextArea(DOMPurify.sanitize(text));
    }
    if (updateEditor && text) {
      const sanitized = DOMPurify.sanitize(text).replaceAll(/<p>\r?\n+<\/p>/g, "")
        .replaceAll("<br>", "<p></p>")
        .replaceAll("<li><p></p></li>", "<li><br></li>")
        .replaceAll(/\n+/g, "");

      if (sanitized.replaceAll("<p></p>", "<p><br></p>") !== this.editor.root.innerHTML) {
        const delta = this.editor.clipboard.convert(sanitized);
        this.editor.setContents(delta, "silent");
      }
    }
  },

  updateTextArea(text) {
    const textarea = this.getInput();
    if (textarea.value === text) {
      return;
    }
    textarea.value = text || "";
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
