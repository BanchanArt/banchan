import Croppr from "croppr"

let fileRefs = 1000000;

const Cropper = {
  mounted() {
    this.ref = this.el.dataset.entryRef;
    this.inputEl = document.getElementById(this.el.dataset.uploadRef);
    this.uploadName = this.el.dataset.uploadName;
    this.getEntryDataURL(this.inputEl, this.ref, url => {
      this.url = url;
      this.el.onload = () => {
        this.croppr = new Croppr(this.el, {
          aspectRatio: this.el.dataset.aspectRatio && parseFloat(this.el.dataset.aspectRatio),
          startSize: [100, 100, "%"],
          onCropEnd: vals => {
            this.cropprToBlob(vals, blob => {
              this.upload(this.el.dataset.uploadName, [blob]);
            });
          }
        });

      };
      this.el.src = url;
    });
  },

  destroyed() {
    this.croppr && this.croppr.destroy();
    this.el.src && URL.revokeObjectURL(this.el.src);
    this.el.src = null;
    this.croppr = null;
  },

  cropprToBlob({ width, height, x, y }, cb) {
    const canvas = document.createElement("canvas");
    const context = canvas.getContext("2d");
    canvas.width = width;
    canvas.height = height;
    context.drawImage(this.el, x, y, width, height, 0, 0, canvas.width, canvas.height);
    canvas.toBlob(cb, "image/jpeg", 0.9)
  },

  // This is all stuff spelunked from Phoenix because we need it but they
  // don't export it.
  getEntryDataURL(inputEl, ref, cb) {
    let file = this.activeFiles(inputEl).find(file => this.genFileRef(file) === ref);
    cb(URL.createObjectURL(file));
  },

  genFileRef(file) {
    let ref = file._phxRef
    if(ref !== undefined){
      return ref
    } else {
      file._phxRef = (fileRefs++).toString()
      return file._phxRef
    }
  },

  activeFiles(inputEl) {
    files = (inputEl["phxPrivate"] && inputEl["phxPrivate"].files) || [];

    return files.filter(f => this.isActive(inputEl, f));
  },

  isActive(inputEl, file) {
    let isNew = file._phxRef === undefined;
    let activeRefs = inputEl.getAttribute("data-phx-active-refs").split(",");
    let isActive = activeRefs.indexOf(this.genFileRef(file)) >= 0;
    return file.size > 0 && (isNew || isActive);
  }
};

export { Cropper };
