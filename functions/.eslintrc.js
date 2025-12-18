module.exports = {
  root: true,
  env: {
    es6: true,
    node: true,
  },
  extends: [
    "eslint:recommended",
    "plugin:import/errors",
    "plugin:import/warnings",
    "plugin:import/typescript",
    "google",
    "plugin:@typescript-eslint/recommended",
  ],
  parser: "@typescript-eslint/parser",
  parserOptions: {
    project: ["tsconfig.json", "tsconfig.dev.json"],
    sourceType: "module",
  },
  ignorePatterns: [
    "/lib/**/*", // Ignore built files.
    "/generated/**/*", // Ignore generated files.
    "/test/**/*", // Ignore test files during YouTube integration.
  ],
  plugins: [
    "@typescript-eslint",
    "import",
  ],
  rules: {
    "quotes": ["error", "double"],
    "import/no-unresolved": 0,
    "indent": ["error", 2],
    // ⚠️ TEMPORARY DISABLED RULES – REMOVE AFTER YOUTUBE FEATURE IS FULLY INTEGRATED
    // TODO(Anna): Re-enable max-len, linebreak-style and require-jsdoc once YouTube UI integration is completed and tested.
    // TEMPORARY relaxations during YouTube integration development
    "max-len": "off",
    "linebreak-style": "off",
    "require-jsdoc": "off",
    "valid-jsdoc": "off", // Disabled: too strict param documentation
    "@typescript-eslint/no-var-requires": "off",
    "@typescript-eslint/no-explicit-any": "warn", // Allow 'any' with warning
    "@typescript-eslint/no-unused-vars": "warn", // Allow unused vars with warning
    "@typescript-eslint/no-non-null-assertion": "warn", // Allow non-null assertions with warning
    "no-empty": "off",
  },
};
