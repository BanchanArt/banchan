const plugin = require('tailwindcss/plugin');
const colors = require('tailwindcss/colors');

module.exports = {
  mode: "jit",
  purge: ["./js/**/*.js", "../lib/*_web/**/*.*ex"],
  content:
    ["./js/**/*.js", "../lib/*_web.ex", "../lib/*_web/**/*.*ex"],
  plugins: [
    require('@tailwindcss/aspect-ratio'),
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
    require('daisyui'),
    plugin(function ({ matchUtilities, theme }) {
      matchUtilities(
        {
          'text-shadow': (value) => ({
            textShadow: value,
          }),
        },
        { values: theme('textShadow') }
      );
    }),
  ],
  theme: {
    extend: {
      aspectRatio: {
        'video': '16 / 9',
        'header-image': '3.5 / 1'
      },
      spacing: {
        '128': '32rem',
        'video': '56.25%',
      },
      gridAutoRows: {
        'gallery': '50px'
      },
      gridTemplateColumns: {
        'gallery': 'repeat(auto-fill, minmax(30%, 1fr))'
      },
      colors: {
        discord: '#5865F2',
        google: '#4285F4',
        twitter: '#1DA1F2'
      },
      textShadow: {
        sm: '0 1px 2px var(--tw-shadow-color)',
        DEFAULT: '0 2px 4px var(--tw-shadow-color)',
        lg: '0 8px 16px var(--tw-shadow-color)',
      },
    }
  },
  daisyui: {
    styled: true,
    base: true,
    utils: true,
    logs: true,
    rtl: false,
    themes: [
      {
        'light': {
          'primary': colors.emerald[500],
          'primary-focus': colors.emerald[600],
          'primary-content': colors.emerald[50],

          'secondary': colors.cyan[500],
          'secondary-focus': colors.cyan[600],
          'secondary-content': colors.cyan[50],

          'accent': colors.purple[500],
          'accent-focus': colors.purple[600],
          'accent-content': colors.purple[50],

          'neutral': colors.zinc[500],
          'neutral-focus': colors.zinc[600],
          'neutral-content': colors.zinc[50],

          'base-100': colors.zinc[50],
          'base-200': colors.zinc[100],
          'base-300': colors.zinc[200],
          'base-content': colors.zinc[700],

          'info': colors.blue[500],
          'success': colors.emerald[500],
          'warning': colors.amber[500],
          'error': colors.red[500],

          '--rounded-box': '1rem',
          '--rounded-btn': '0.5rem',
          '--rounded-badge': '1.9rem',

          '--animation-btn': '0',
          '--animation-input': '0',

          '--btn-text-case': 'uppercase',
          '--navbar-padding': '0.5rem',
          '--border-btn': '1px',
        },
      },
      {
        'dark': {
          'primary': colors.emerald[500],
          'primary-focus': colors.emerald[600],
          'primary-content': colors.emerald[50],

          'secondary': colors.cyan[500],
          'secondary-focus': colors.cyan[600],
          'secondary-content': colors.cyan[50],

          'accent': colors.purple[500],
          'accent-focus': colors.purple[600],
          'accent-content': colors.purple[50],

          'neutral': colors.zinc[500],
          'neutral-focus': colors.zinc[600],
          'neutral-content': colors.zinc[50],

          'base-100': colors.zinc[800],
          'base-200': colors.zinc[900],
          'base-300': colors.zinc[950],
          'base-content': colors.zinc[200],

          'info': colors.blue[400],
          'success': colors.emerald[400],
          'warning': colors.amber[400],
          'error': colors.red[400],

          '--rounded-box': '1rem',
          '--rounded-btn': '0.5rem',
          '--rounded-badge': '1.9rem',

          '--animation-btn': '0.25s',
          '--animation-input': '0.2s',

          '--btn-text-case': 'uppercase',
          '--navbar-padding': '0.5rem',
          '--border-btn': '1px',
        },
      },
    ],
  },
};
