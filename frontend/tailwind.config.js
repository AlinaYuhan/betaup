/** @type {import('tailwindcss').Config} */
export default {
  content: ["./index.html", "./src/**/*.{js,jsx}"],
  theme: {
    extend: {
      colors: {
        basalt: "#0d1117",
        ember: "#ff7a18",
        ice: "#8ad7ff",
        moss: "#4f7d64",
        steel: "#151c25",
      },
      fontFamily: {
        display: ["Bebas Neue", "sans-serif"],
        sans: ["Manrope", "sans-serif"],
      },
      boxShadow: {
        glow: "0 0 0 1px rgba(138, 215, 255, 0.18), 0 30px 80px rgba(0, 0, 0, 0.35)",
      },
    },
  },
  plugins: [],
};
