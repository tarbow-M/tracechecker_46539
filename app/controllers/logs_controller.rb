class LogsController < ApplicationController
  # before_action :authenticate_user! # (ApplicationControllerで一括管理)

  # GET /logs
  def index
    # ログイン中のユーザーに紐づくログのみを、作成日時の降順（新しいものが上）で取得する
    # N+1問題を避けるため、関連する project も "includes" で事前読み込みする
    @logs = current_user.logs.includes(:project).order(created_at: :desc)
    
    # ページネーションを追加する場合 (例: Kaminari gem)
    # @logs = @logs.page(params[:page]).per(50)
  end
end
