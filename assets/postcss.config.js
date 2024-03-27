module.exports = {
  plugins: {
    'postcss-import': {},
    'cssnano': { preset: 'default' },
    'tailwindcss/nesting': {},
    tailwindcss: {},
    autoprefixer: {},
    'postcss-url': {
      url: 'inline',
    }
  }
};
