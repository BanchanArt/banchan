import Cropper from "cropperjs"

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

  sliderEl() {
    return this.el.querySelector(".rotate-range");
  },

  uploadTarget() {
    return this.el.dataset.uploadTarget == "live_view"
      ? "[data-phx-main=\"true\"]"
      : this.el.dataset.uploadTarget;
  },

  setUpCropper(imgEl) {
    if (this.cropper) {
      this.cropper.destroy();
    }
    this.cropper = new Cropper(imgEl, {
      aspectRatio: this.el.dataset.aspectRatio && parseFloat(this.el.dataset.aspectRatio),
      autoCropArea: 1,
      dragMode: "move",
      crop: ev => {
        this.cropper.getCroppedCanvas().toBlob(blob => {
          this.blob = blob;
        }, "image/jpeg", 0.9);
      }
    });
  },

  mounted() {
    this.sliderEl().addEventListener("input", ev => {
      if (this.cropper) {
        this.cropper.rotateTo(+ev.target.value);
      }
    });
    this.handleEvent("file_chosen", ({ id }) => {
      if (id === this.el.id) {
        const inputEl = this.inputEl();
        if (this.cropper) {
          this.cropper.destroy();
          this.imgEl && this.imgEl.parentNode.removeChild(this.imgEl);
          this.imgEl && URL.revokeObjectURL(this.imgEl.src)
          this.imgEl = null;
          this.cropper = null;
        }
        if (inputEl.files.length) {
          this.imgEl = new Image();
          this.imgEl.onload = () => this.setUpCropper(this.imgEl);
          this.imgElContainer().appendChild(this.imgEl);
          this.imgEl.src = URL.createObjectURL(inputEl.files[0]);
          inputEl.value = "";
        }
      }
    });

    this.handleEvent("submit", ({ id }) => {
      if (id === this.el.id && this.blob) {
        this.uploadTo(this.uploadTarget(), this.uploadName(), [this.blob]);
      }
    });
  },

  destroyed() {
    this.cropper && this.cropper.destroy();
    this.imgEl && this.imgEl.src && URL.revokeObjectURL(this.imgEl.src)
  },

  cropperToBlob(imgEl, { width, height, x, y }, cb) {
  }
};

export { CropUploadInput };
