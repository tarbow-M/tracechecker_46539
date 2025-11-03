class ApplicationController < ActionController::Base
# basic認証導入
before_action :basic_auth
# ログイン画面以外はすべてログイン必須！　未ログインユーザーはログイン画面以外に直接遷移しようとするとログイン画面に飛ばす
before_action :authenticate_user!, unless: :devise_controller?
# ユーザー認証機能のストパラ
before_action :configure_permitted_parameters, if: :devise_controller?

  protected  # gemファイルのDevise::RegistrationsControllerで使うためprivateではなくprotected

  # basic認証
  def basic_auth
    authenticate_or_request_with_http_basic do |username, password|
      username == ENV["BASIC_AUTH_USER"] && password == ENV["BASIC_AUTH_PASSWORD"]  # 環境変数を読み込む記述に変更
    end
  end

  # ユーザー認証機能のストパラ
  def configure_permitted_parameters
    # :sign_up (新規登録) のときに、personal_num と name を許可する
    devise_parameter_sanitizer.permit(:sign_up, keys: [:personal_num, :name])

    # :account_update (アカウント編集) のときにも許可する場合は以下も追記（今後パスワード更新を実装）
    # devise_parameter_sanitizer.permit(:account_update, keys: [:personal_num, :name])
  end

  private

  # 共通ログ作成ヘルパーメソッド（親プロ、テンプレ保存、アーカイブ保存）
  def create_log(action_type, description, project = nil)
    current_user.logs.create( 
      project: project, 
      action_type: action_type,
      description: description
    )
  rescue => e
    # ログの作成に失敗しても、メインの処理 (アーカイブ保存など) は
    # 停止させたくないので、エラーをRailsのログに出力するだけにする
    Rails.logger.error "Log creation failed: #{e.message}"
  end
end
