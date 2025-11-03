class ArchivedResultsController < ApplicationController
  # ネストされたコントローラなので、親のプロジェクトを読み込む
  before_action :set_project

  def create
    # 親 (ArchivedResult) と 子 (TraceResult) の両方を
    # 1つのトランザクション（2つの処理を一つにまとめること）で安全に保存する → どちらとも成功した場合のみDb保存
    
    # 1. まず、親 (ArchivedResult) のインスタンスを作成
    # (まだDBには保存しない)
    @archived_result = @project.archived_results.new(archive_params)
    
    # 2. データベースのトランザクションを開始
    ActiveRecord::Base.transaction do
      # 3. まず親 (ArchivedResult) をDBに保存 (これにより @archived_result.id が確定する)
      @archived_result.save! # (失敗した場合はここで例外が発生し、トランザクションがロールバックされる)

      # 4. JavaScriptから送られてきた "results" (TraceResultの配列) を処理  （ストパラ）
      results_params = params.require(:results) # results 配列を必須にする
      
      # "results" 配列が空でないことを確認
      if results_params.blank?
        # 空の場合はトランザクションを失敗させる (ロールバック)
        raise ActiveRecord::Rollback, "照合結果（results）が空です"
      end

      # 5. results 配列をループ処理し、"create!" を使って1件ずつDBに保存する
      # (create! なら ActiveRecord の型変換 (Hash -> JSON文字列) が正しく動作する)
      results_params.each do |result_param|
        @archived_result.trace_results.create!(
          key: result_param["key"],
          flag: result_param["flag"],
          comment: result_param["comment"],
          # "target_cell" はRubyハッシュのまま渡せば、create! が自動でJSON文字列に変換
          target_cell: result_param["target_cell"], 
        )
      end
    end
    
    # 6. トランザクションがすべて成功した場合
    render json: { 
      message: '証跡を保存しました', 
      archived_result_id: @archived_result.id,
      # 遷移先のパスもJSONで返す
      redirect_url: parent_project_path(@parent_project) 
    }, status: :created

  rescue ActiveRecord::RecordInvalid => e
    # バリデーションエラー (例: アーカイブ名が空、または "create!" が失敗)
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

  # 忘備録 
  # "results" (TraceResultの配列) のパラメータはcreate アクション内で "require" して直接処理するため、ストロングパラメータのメソッドは不要
end
