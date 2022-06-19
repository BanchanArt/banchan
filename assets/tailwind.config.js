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
      spacing: {
        '128': '32rem',
        'video': '56.25%',
      },
      gridAutoRows: {
        'gallery': '50px'
      },
      gridTemplateColumns: {
        'gallery': 'repeat(auto-fill, minmax(30%, 1fr))'
      }
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
           'primary' : '#66cc8a',
           'primary-focus' : '#41be6d',
           'primary-content' : '#f9fafb',

           'secondary' : '#5a7c65',
           'secondary-focus' : '#48604f',
           'secondary-content' : '#f9fafb',

           'accent' : '#ea5234',
           'accent-focus' : '#d03516',
           'accent-content' : '#f9fafb',

           'neutral' : '#333c4d',
           'neutral-focus' : '#1f242e',
           'neutral-content' : '#f9fafb',

           'base-100' : '#ffffff',
           'base-200' : '#f9fafb',
           'base-300' : '#f0f0f0',
           'base-content' : '#333c4d',

           'info' : '#1c92f2',
           'success' : '#009485',
           'warning' : '#ff9900',
           'error' : '#ff5724',

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
           'primary' : '#5db776',
           'primary-focus' : '#239261',
           'primary-content' : '#ffffff',

           'secondary' : '#418052',
           'secondary-focus' : '#186644',
           'secondary-content' : '#ffffff',

           'accent' : '#d99330',
           'accent-focus' : '#b57721',
           'accent-content' : '#ffffff',

           'neutral' : '#2a2e37',
           'neutral-focus' : '#16181d',
           'neutral-content' : '#ffffff',

           'base-100' : '#3b424e',
           'base-200' : '#2a2e37',
           'base-300' : '#16181d',
           'base-content' : '#ebecf0',

           'info' : '#66c7ff',
           'success' : '#87cf3a',
           'warning' : '#e1d460',
           'error' : '#ff6b6b',

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
