module.exports = {
  content: 
    ["./js/**/*.js", "../lib/*_web.ex", "../lib/*_web/**/*.*ex"],
  plugins: [
    require('@tailwindcss/aspect-ratio'),
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
    require('daisyui')
  ],
  theme: {
    extend: {
      colors: require('daisyui/colors')
    },
  },
  daisyui: {
    styled: true,
    base: true,
    utils: true,
    logs: true,
    rtl: false,
    themes: [
      'dark',
      'light',
      'forest',
      'synthwave',
      'cupcake',
      'bumblebee',
      'emerald',
      'cyberpunk',
      'valentine',
      'halloween',
      'garden',
      'aqua',
      'fantasy',
      'dracula',
      'cmyk'
      },
    ],
  },
};