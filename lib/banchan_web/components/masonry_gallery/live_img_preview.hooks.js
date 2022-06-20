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
        'row-span-1' :
        ratio < 180 && ratio >= 120 ?
          // Wide
          'row-span-2' :
          ratio < 120 && ratio >= 80 ?
            // Square-ish
            'row-span-3' :
            ratio < 80 && ratio >= 60 ?
              // Tall
              'row-span-4' :
              // Very tall
              'row-span-5';

    this.el.classList = [spanClass, ...this.baseClasses].join(' ');
  }
}

export {LiveImgPreview}
