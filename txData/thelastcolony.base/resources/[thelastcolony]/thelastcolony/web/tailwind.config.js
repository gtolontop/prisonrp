/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        // Custom color palette for apocalyptic theme
        primary: {
          50: '#f0f9ff',
          100: '#e0f2fe',
          200: '#b9e6fe',
          300: '#7cd4fd',
          400: '#36bcfa',
          500: '#0ba2e8',
          600: '#0082c5',
          700: '#0167a0',
          800: '#065783',
          900: '#0b486d',
          950: '#072d48',
        },
        dark: {
          900: '#0a0f1a',
          800: '#121827',
          700: '#1a2234',
          600: '#232d41',
          500: '#2c384e',
          400: '#3f4d64',
          300: '#52627a',
          200: '#657790',
          100: '#788ca6',
        },
        danger: '#ef4444',
        warning: '#f59e0b',
        success: '#10b981',
        info: '#3b82f6',
        // Rarity colors
        rarity: {
          common: '#9ca3af',
          uncommon: '#10b981',
          rare: '#3b82f6',
          epic: '#a855f7',
          legendary: '#f59e0b',
          mythic: '#ef4444',
        }
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
        mono: ['JetBrains Mono', 'monospace'],
      },
      animation: {
        'fade-in': 'fadeIn 0.2s ease-in-out',
        'slide-up': 'slideUp 0.3s ease-out',
        'pulse-slow': 'pulse 3s cubic-bezier(0.4, 0, 0.6, 1) infinite',
      },
      keyframes: {
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
        slideUp: {
          '0%': { transform: 'translateY(10px)', opacity: '0' },
          '100%': { transform: 'translateY(0)', opacity: '1' },
        },
      },
    },
  },
  plugins: [],
}
