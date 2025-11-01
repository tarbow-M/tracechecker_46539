class ApplicationController < ActionController::Base
# basic認証導入
before_action :basic_auth
# ログイン画面以外はすべてログイン必須！　未ログインユーザーはログイン画面以外に直接遷移しようとするとログイン画面に飛ばす
before_action :authenticate_user!, unless: :devise_controller?

before_action :configure_permitted_parameters, if: :devise_controller?

  protected  # gemファイルのDevise::RegistrationsControllerで使うためprivateではなくprotected

  def basic_auth
    authenticate_or_request_with_http_basic do |username, password|
      username == ENV["BASIC_AUTH_USER"] && password == ENV["BASIC_AUTH_PASSWORD"]  # 環境変数を読み込む記述に変更
    end
  end

  def configure_permitted_parameters
    # :sign_up (新規登録) のときに、personal_num と name を許可する
    devise_parameter_sanitizer.permit(:sign_up, keys: [:personal_num, :name])

    # :account_update (アカウント編集) のときにも許可する場合は以下も追記（今後パスワード更新を実装）
    # devise_parameter_sanitizer.permit(:account_update, keys: [:personal_num, :name])
  end
end
