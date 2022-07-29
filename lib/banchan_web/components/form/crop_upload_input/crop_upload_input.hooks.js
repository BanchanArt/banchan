import Croppr from "croppr"

let fileRefs = 1000000;

const CropUploadInput = {
  uploadName() {
    return this.el.dataset.uploadName;
  },

  inputEl() {
    return this.el.querySelector("input.file-input");
  },

  imgElContainer() {
    return this.el.querySelector(".cropper-preview");
  },

  uploadTarget() {
    return this.el.dataset.uploadTarget == "live_view"
      ? "[data-phx-main=\"true\"]"
      : this.el.dataset.uploadTarget;
  },

  setUpCroppr(imgEl) {
    if (this.croppr) {
      this.croppr.destroy();
    }
    this.croppr = new Croppr(imgEl, {
      aspectRatio: this.el.dataset.aspectRatio && parseFloat(this.el.dataset.aspectRatio),
      startSize: [100, 100, "%"],
      onCropEnd: vals => {
        this.cropprToBlob(imgEl, vals, blob => {
          this.blob = blob;
        });
      }
    });
  },

  mounted() {
    this.handleEvent("file_chosen", ({ id }) => {
      if (id === this.el.id) {
        const inputEl = this.inputEl();
        if (this.croppr) {
          this.croppr.destroy();
          this.imgEl && this.imgEl.parentNode.removeChild(this.imgEl);
          this.imgEl && URL.revokeObjectURL(this.imgEl.src)
          this.imgEl = null;
          this.croppr = null;
        }
        if (inputEl.files.length) {
          this.imgEl = new Image();
          this.imgEl.onload = () => this.setUpCroppr(this.imgEl);
          this.imgElContainer().appendChild(this.imgEl);
          this.imgEl.src = URL.createObjectURL(inputEl.files[0]);
          inputEl.value = "";
        }
      }
    });

    this.handleEvent("submit", ({ id }) => {
      if (id === this.el.id && this.blob) {
        console.log("uploadTo", this.uploadTarget(), this.uploadName());
        this.uploadTo(this.uploadTarget(), this.uploadName(), this.blob);
      }
    });
  },

  destroyed() {
    this.croppr && this.croppr.destroy();
    this.imgEl && this.imgEl.src && URL.revokeObjectURL(this.imgEl.src)
  },

  cropprToBlob(imgEl, { width, height, x, y }, cb) {
    const canvas = document.createElement("canvas");
    const context = canvas.getContext("2d");
    canvas.width = width;
    canvas.height = height;
    context.drawImage(imgEl, x, y, width, height, 0, 0, canvas.width, canvas.height);
    canvas.toBlob(cb, "image/jpeg", 0.9)
  }
};

export { CropUploadInput };
