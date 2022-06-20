const DragDropCards = {
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
    this.updateCards();
    this.cardEvents = this.cards.map(card => {
      return [
        card,
        card.addEventListener("dragstart", () => card.classList.add("dragging")),
        card.addEventListener("dragend", () => {
          card.classList.remove("dragging");
          this.pushEvent("drop_card", {
            type: card.dataset.type,
            new_index: this.cards.indexOf(card)
          });
        })
      ];
    });
    this.dragover = this.el.addEventListener("dragover", e => {
      const last = this.cards[this.cards.length - 1];
      const dragged = this.el.querySelector(".offering-card.dragging");
      e.preventDefault();
      e.dataTransfer.dropEffect = "move";
      const over = this.hoveringOver(e.clientX, e.clientY);
      if (over == dragged) {
        // Do nothing
      } else if (over && dragged.nextSibling == over && over.nextSibling) {
        this.el.insertBefore(dragged, over.nextSibling);
        this.updateCards();
      } else if (over) {
        this.el.insertBefore(dragged, over);
        this.updateCards();
      }
    });
  },

  removeListeners() {
    this.el.removeEventListener("dragover", this.dragover);
    this.cardEvents.forEach(([card, start, end]) => {
      card.removeEventListener("dragstart", start);
      card.removeEventListener("dragend", end);
    });
  },

  hoveringOver(x, y) {
    return this.cards.find(card => {
      const rect = card.getBoundingClientRect();
      return x >= rect.left && x <= rect.right && y >= rect.top && y <= rect.bottom;
    });
  },

  updateCards() {
    this.cards = [...this.el.querySelectorAll(".offering-card:not(.archived)")];
  }
}

export {DragDropCards}
