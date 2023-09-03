// From https://adrian-philipp.com/notes/how-to-implement-infinite-scroll-with-phoenix-liveview
// Also with some help from @msaraiva
const InfiniteScroll = {
  page() {
    return this.el.dataset.page;
  },
  eventName() {
    return this.el.dataset.eventName;
  },
  eventTarget() {
    return this.el.dataset.eventTarget == "live_view"
      ? "[data-phx-main]"
      : this.el.dataset.eventTarget;
  },

  loadMore(entries) {
    const target = entries[0];
    if (target.isIntersecting && this.pending == this.page()) {
      this.pending = this.page() + 1;
      this.pushEventTo(this.eventTarget(), this.eventName(), {});
    }
  },

  mounted() {
    this.pending = this.page();
    this.observer = new IntersectionObserver(
      (entries) => this.loadMore(entries),
      {
        root: null, // window by default
        rootMargin: "0px",
        threshold: [0.9, 1],
      }
    );
    this.observer.observe(this.el.querySelector("infinite-scroll-marker"));
  },

  beforeDestroy() {
    this.observer.unobserve(this.el.querySelector("infinite-scroll-marker"));
  },

  updated() {
    this.pending = this.page();
  },
};

export {InfiniteScroll}
