import Editor from '@toast-ui/editor';

let MarkdownInput = {
  mounted() {
    this.initEditor();
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
  },

  destroyed() {
    document.removeEventListener("dragenter", this.ondragenter);
    document.removeEventListener("dragover", this.ondragover);
    document.removeEventListener("dragleave", this.ondragleave);
    document.removeEventListener("drop", this.ondrop);
    this.editor.destroy();
  },

  initEditor() {
    const el = this.el.querySelector(".editor");
    this.editor = new Editor({
      el,
      initialEditType: 'wysiwyg',
      previewStyle: 'tab',
      usageStatistics: false,
      // NB(@zkat): placeholders hide the cursor on Firefox for some reason,
      // so I'm just disabling this altogether. Maybe try again some day.
      //
      // placeholder: el.dataset.placeholder,
      height: el.dataset.height,
      autofocus: false,
      initialValue: this.el.querySelector(".input-textarea").value,
      toolbarItems: [
        ['heading', 'bold', 'italic', 'strike'],
        ['hr', 'quote'],
        ['ul', 'ol', 'task', 'indent', 'outdent'],
        ['table', 'link'],
      ],
      theme: document.documentElement.getAttribute("data-theme") === "dark" && "dark",
      events: {
        change: debounce(() => {
          const textarea = this.el.querySelector(".input-textarea");
          const value = this.editor.getMarkdown();
          if (!this.updatingFromServer && textarea.value !== value) {
            textarea.value = value;
            var evt = new Event("change", {
              bubbles: true,
              cancelable: true
            });
            textarea.dispatchEvent(evt);
          }

          if (this.updatingFromServer) {
            this.updatingFromServer -= 1;
          } else {
            this.updatingFromServer = null;
          }
        }, 300)
      }
    });

    this.handleEvent(`markdown-input-updated`, msg => {
      if (msg.id == this.el.id && msg.value !== this.editor.getMarkdown()) {
        this.updatingFromServer = 2;
        this.el.querySelector(".input-textarea").value = msg.value || "";
        this.editor.setMarkdown(msg.value || "");
      }
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

export { MarkdownInput };
