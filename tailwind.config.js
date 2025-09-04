/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./App.{js,jsx,ts,tsx}",
    "./src/**/*.{js,jsx,ts,tsx}",
    "./**/*.{js,jsx,ts,tsx}"
  ],
  theme: {
    extend: {
      colors: {
        'dark': {
          950: '#020617',
          900: '#0f172a',
          800: '#1e293b',
        },
        'primary': {
          300: '#7dd3fc',
          400: '#38bdf8',
          500: '#0ea5e9',
        }
      },
      fontFamily: {
        'space-mono': ['Space Mono', 'monospace'],
      }
    },
  },
  plugins: [],
}
