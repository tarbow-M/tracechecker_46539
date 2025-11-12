// Rails UJS (data-method, data-confirm などのため)
import Rails from "@rails/ujs"

// Active Storage (ダイレクトアップロードのため)
import * as ActiveStorage from "@rails/activestorage"

// checker.js（照合処理）をインポート
import "./checker"

// Rails UJS と Active Storage を開始
Rails.start()
ActiveStorage.start()