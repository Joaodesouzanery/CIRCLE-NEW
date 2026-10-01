/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      fontFamily: { sans: ['Inter', 'system-ui', 'sans-serif'] },
      colors: {
        navy: { 950: '#071A3D', 900: '#0B2350', 800: '#10306B', 700: '#173F86' },
        brand: { DEFAULT: '#1463E6', soft: '#E8F0FD' },
        ok: { DEFAULT: '#0E9F6E', soft: '#DDF5EB' },
        warn: { DEFAULT: '#E8A317', soft: '#FDF1D6' },
        bad: { DEFAULT: '#E0364A', soft: '#FDE4E7' },
        ink: { DEFAULT: '#14213D', soft: '#5B6785', faint: '#94A0BA' },
        canvas: '#F3F6FB',
      },
      boxShadow: { card: '0 1px 2px rgba(16,35,80,.05), 0 4px 16px rgba(16,35,80,.06)' },
    },
  },
  plugins: [],
}
