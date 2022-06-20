const LiveImgPreview = {
  mounted() {
    this.baseClasses = this.el.classList;
    this.el.querySelector('img').addEventListener('load', () => {
      const img = this.el.querySelector('img');
      const [width, height] = [img.naturalWidth, img.naturalHeight];

      this.ratio = width / height * 100;

      this.updateClass();
    });
  },

  updated() {
    this.updateClass();
  },

  updateClass() {
    const ratio = this.ratio;

    const spanClass =
      ratio >= 180 ?
        // Very Wide
        'sm:row-span-1' :
        ratio < 180 && ratio >= 120 ?
          // Wide
          'sm:row-span-2' :
          ratio < 120 && ratio >= 80 ?
            // Square-ish
            'sm:row-span-3' :
            ratio < 80 && ratio >= 60 ?
              // Tall
              'sm:row-span-4' :
              // Very tall
              'sm:row-span-5';

    this.el.classList = [spanClass, ...this.baseClasses].join(' ');
  }
}

export {LiveImgPreview}
