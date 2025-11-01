/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './app/views/**/*.html.erb',
    './app/helpers/**/*.rb',
    './app/assets/stylesheets/**/*.css', // この行は既存ですが、念のため含めます
    './app/javascript/**/*.js',
    './app/javascript/**/*.jsx', // React/Vueなどを使用する場合
    './app/javascript/**/*.ts',  // TypeScriptを使用する場合
    './app/javascript/**/*.tsx', // TypeScript + Reactなどを使用する場合
  ],

  safelist: [  // Tailwind CSSの「Purge（パージ/除去）」機能から緑、赤、オレンジのハイライトを除外
    'diff-highlight',
    'match-highlight',
    'unmatched-highlight',
  ],

  theme: {
    extend: {},
  },

  plugins: [
    require('@tailwindcss/forms'), // Tailwind CSS のFormsを追加
  ],
}
