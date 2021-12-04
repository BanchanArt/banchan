const colors = require('tailwindcss/colors')

module.exports = {
  mode: "jit",
  purge: {
    content: ["./js/**/*.js", "../lib/*_web/**/*.*ex"],
    options: {
      // make sure to safelist these classes when using purge
      safelist: [
        'w-64',
        'w-1/2',
        'rounded-l-lg',
        'rounded-r-lg',
        'bg-gray-200',
        'grid-cols-4',
        'grid-cols-7',
        'h-6',
        'leading-6',
        'h-9',
        'leading-9',
        'shadow-lg',
        /data-.*/
      ],
    }
  },
  theme: {
    extend: {},
    colors: {
      // Build your palette here
      transparent: 'transparent',
      current: 'currentColor',
      black: colors.black,
      white: colors.white,
      red: colors.red,
      orange: colors.orange,
      amber: colors.amber,
      lime: colors.lime,
      green: colors.green,
      emerald: colors.emerald,
      teal: colors.teal,
      cyan: colors.cyan,
      blue: colors.blue,
      violet: colors.violet,
      purple: colors.purple,
      gray: colors.coolGray,
      // abstract names
      primary: colors.emerald,
      secondary: colors.teal,
      tertiary: colors.lime,
      link: colors.violet,
      info: colors.cyan,
      success: colors.blue,
      warning: colors.amber,
      danger: colors.red,
    }
  },
  darkMode: 'class',
  variants: {
    extend: {
      // apply variants like hover, focus, dark to components
    }
  },
  plugins: [
    require('@tailwindcss/aspect-ratio'),
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
    require('@themesberg/flowbite/plugin')
  ],
};
