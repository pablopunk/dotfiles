module.exports = {
    "env": {
        "browser": true,
        "es6": true,
    },
    "extends": "standard",
    "globals": {
        "Atomics": "readonly",
        "SharedArrayBuffer": "readonly"
    },
    "parserOptions": {
        "ecmaFeatures": {
            "jsx": true
        },
        "ecmaVersion": 2018,
        "sourceType": "module"
    },
    "plugins": [
        "react"
    ],
    "rules": {
      "react/jsx-filename-extension": [1, { "extensions": [".js", ".jsx", ".ts", ".tsx"] }],
      "react/jsx-uses-vars": 2,
      "react/self-closing-comp": ["error", {
        "component": true,
        "html": true
      }],
      "jsx-quotes": [2, "prefer-single"],
      "space-before-function-paren": 0
    }
};
