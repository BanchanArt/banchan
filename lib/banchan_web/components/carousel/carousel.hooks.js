import Splide from '@splidejs/splide';

const SplideHook = {
  mounted() {
    this.splide = new Splide(this.el, {
      type: 'loop',
      autoplay: true
    }).mount();
  }
};

export { SplideHook };
