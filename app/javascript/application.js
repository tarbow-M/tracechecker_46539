// Entry point for the esbuild build script in package.json
import "@hotwired/turbo-rails"
import * as ActiveStorage from "@rails/activestorage"

// ActiveStorage を開始
ActiveStorage.start()

// (Stimulus コントローラは /controllers フォルダが作成されたらここに追加します)
// import "./controllers"