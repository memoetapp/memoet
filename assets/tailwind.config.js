const plugin = require('tailwindcss/plugin')

module.exports = {
  purge: [
    '../lib/**/*.ex',
    '../lib/**/*.leex',
    '../lib/**/*.eex',
    './js/**/*.js'
  ],
  darkMode: false, // or 'media' or 'class'
  theme: {
    extend: {},
  },
  variants: {
    extend: {},
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
    plugin(function({ addBase, config }) {
      addBase({
        'body': { color: config('theme.colors.gray.700') },
      })
    }),
  ],
}
