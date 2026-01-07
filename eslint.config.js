export default [
  {
    files: ["**/*.js"],
    rules: {
      quotes: ["error", "double"],
      "max-len": ["error", { "code": 120 }],
      "no-trailing-spaces": "off",
      "object-curly-spacing": "off",
      "comma-dangle": "off",
      "padded-blocks": "off",
      "arrow-parens": "off",
      "eol-last": "off",
    },
  },
]; 