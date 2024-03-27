import Sortable from 'sortablejs';

export const SortableHook = {
  mounted() {
    new Sortable(this.el.querySelector(".preview-items"), {
      animation: 150,
      delay: 100,
      dragClass: "drag-item",
      ghostClass: "drag-ghost",
      forceFallback: true,
      onEnd: e => {
        let params = { old: e.oldIndex, new: e.newIndex, ...e.item.dataset };
        this.pushEventTo(this.el, "reposition", params);
      }
    });
  }
};
