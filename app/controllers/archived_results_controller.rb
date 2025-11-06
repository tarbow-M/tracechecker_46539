class ArchivedResultsController < ApplicationController
  # ネストされたコントローラなので、親のプロジェクトを読み込む
  before_action :set_project

  # POST /parent_projects/:parent_project_id/projects/:project_id/archived_results
  def create
    # 親 (ArchivedResult) と 子 (TraceResult) の両方を
    # 1つのトランザクション（処理のかたまり）で安全に保存する
    
    # 1. まず、親 (ArchivedResult) のインスタンスを作成
    @archived_result = @project.archived_results.new(archive_params)
    
    # 2. データベースのトランザクションを開始
    ActiveRecord::Base.transaction do
      # 3. まず親 (ArchivedResult) をDBに保存
      @archived_result.save! # (失敗した場合はここで例外が発生し、ロールバック)

      # 4. JavaScriptから送られてきた "results" (TraceResultの配列) を処理
      results_params = params.require(:results)
      
      if results_params.blank?
        raise ActiveRecord::Rollback, "照合結果（results）が空です"
      end

      # 5. 子 (TraceResult) の配列データを作成
      trace_results_data = results_params.map do |result_param|
        {
          archived_result_id: @archived_result.id,
          key: result_param["key"],     # (シンボル :key ではなく 文字列 "key" を使用)
          flag: result_param["flag"],
          comment: result_param["comment"],
          # "target_cell" (Rubyハッシュ) を "json" カラムに保存
          # (MySQL/PostgreSQL両対応のため .to_json は不要、create! が自動変換)
          target_cell: result_param["target_cell"], 
          created_at: Time.current,
          updated_at: Time.current
        }
      end
      
      # 6. 子 (TraceResult) の配列データを "create!" でDBに登録
      # (insert_all! は型変換をバイパスするため、create! を使う)
      trace_results_data.each do |data|
        TraceResult.create!(data)
      end
      
      # プロジェクトをロック 
      @project.update!(is_locked: true, status: '確定済み')

      # create_log メソッドを呼び出して、操作ログをデータベースに保存（application_controller.rb で定義）
      create_log(
        "archive_create", # action_type（操作の種類）
        "証跡 '#{@archived_result.name}' (ID: #{@archived_result.id}) を作成しました。", # 操作の詳細
        @project # 関連する子プロジェクト
      )
    end
    
    # 8. トランザクションがすべて成功した場合
    render json: { 
      success: true, # 成功フラグ
      message: '結果を保存しました', 
      archived_result_id: @archived_result.id,
      is_locked: @project.is_locked, # ロック状態を返す
      redirect_url: parent_project_path(@parent_project) # 遷移先のパスもJSONで返す
    }, status: :created

  rescue ActiveRecord::RecordInvalid => e
    # バリデーションエラー (例: アーカイブ名が空)
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
    
  rescue => e
    # その他のエラー (results が空、など)
    render json: { errors: [e.message] }, status: :unprocessable_entity
  end

  private

  def set_project
    # ネストされたURLから :parent_project_id と :project_id を取得
    @parent_project = current_user.parent_projects.find(params[:parent_project_id])
    @project = @parent_project.projects.find(params[:project_id])
  end

  # "archived_result" のパラメータを許可
  def archive_params
    params.require(:archived_result).permit(
      :name, 
      :diff_count,
      :file_a_id, 
      :file_b_id
      # child_project_id は @project.archived_results.new で自動セット
    )
  end
end