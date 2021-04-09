const plugin = require('tailwindcss/plugin')

const colorFunc = theme => ({
   'white': theme('colors.white'),
   'gray': theme('colors.gray.500'),
   'red': theme('colors.red.500'),
   'green': theme('colors.green.500'),
   'blue': theme('colors.blue.500'),
   'yellow': theme('colors.yellow.500'),
   'indigo': theme('colors.indigo.500'),
})

module.exports = {
  purge: {
    content: [
      '../lib/**/*.ex',
      '../lib/**/*.leex',
      '../lib/**/*.eex',
      './js/**/*.js'
    ],
    options: {
      // ct- for Chartist overrode styles
      safelist: [/^ct-/],
    },
  },
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
    stroke: colorFunc,
    fill: colorFunc,
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
