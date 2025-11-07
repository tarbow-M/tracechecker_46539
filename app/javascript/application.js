// Entry point for the esbuild build script in package.json
// import "@hotwired/turbo-rails"

// Rails UJS (data-method, data-confirm などのため)
import Rails from "@rails/ujs"

// Active Storage (ダイレクトアップロードのため)
import * as ActiveStorage from "@rails/activestorage"

// (Stimulus コントローラは /controllers フォルダが作成されたらここに追加します)
// import "./controllers"

// Rails UJS と Active Storage を開始
Rails.start()
ActiveStorage.start()