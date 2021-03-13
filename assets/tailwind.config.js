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
    extend: {
      fontFamily: {
        sans: ["\"Nunito Sans\"", "sans-serif"]
      },
    },
    minWidth: {
       '0': '0',
       'xs': '20rem',
       'sm': '24rem',
       'md': '28rem',
       'lg': '32rem',
       'xl': '36rem',
       '2xl': '42rem',
       '1/4': '25%',
       '1/2': '50%',
       '3/4': '75%',
       'full': '100%',
    },
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
