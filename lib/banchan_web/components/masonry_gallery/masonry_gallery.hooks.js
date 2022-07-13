const MasonryGallery = {
  mounted() {
    this.addListeners();
  },

  beforeUpdate() {
    this.removeListeners();
  },

  updated() {
    this.addListeners();
  },

  destroyed() {
    this.removeListeners();
  },

  addListeners() {
    this.updateImages();
    this.imageEvents = this.images.map((image, idx) => {
      return [
        image,
        image.addEventListener("dragstart", () => image.classList.add("dragging")),
        image.addEventListener("dragend", () => {
          image.classList.remove("dragging");
          this.pushEventTo('#' + this.el.id, "items_reordered", {
            items: this.images.map(image => ({
              type: image.dataset.type,
              id: image.dataset.id
            }))
          });
        })
      ];
    });
    this.dragover = this.el.addEventListener("dragover", e => {
      const last = this.images[this.images.length - 1];
      const dragged = this.el.querySelector(".masonry-item.dragging");
      e.preventDefault();
      e.dataTransfer.dropEffect = "move";
      const over = this.hoveringOver(e.clientX, e.clientY);
      if (over == dragged) {
        // Do nothing
      } else if (over && dragged.nextSibling == over && over.nextSibling) {
        this.el.insertBefore(dragged, over.nextSibling);
        this.updateImages();
      } else if (over) {
        this.el.insertBefore(dragged, over);
        this.updateImages();
      }
    });
  },

  removeListeners() {
    this.el.removeEventListener("dragover", this.dragover);
    this.imageEvents.forEach(([image, start, end]) => {
      image.removeEventListener("dragstart", start);
      image.removeEventListener("dragend", end);
    });
  },

  hoveringOver(x, y) {
    return this.images.find(image => {
      const rect = image.getBoundingClientRect();
      return x >= rect.left && x <= rect.right && y >= rect.top && y <= rect.bottom;
    });
  },

  updateImages() {
    this.images = [...this.el.querySelectorAll(".masonry-item")];
  }
}

export {MasonryGallery}
