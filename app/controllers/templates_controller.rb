class TemplatesController < ApplicationController
  # ApplicationControllerで一括して :authenticate_user! が呼ばれる

  # GET /templates (JSON)
  # 照合実行画面のプルダウンに読み込むためのテンプレート一覧
  def index
    @templates = current_user.templates.order(name: :asc)
    
    # "range" (json) と "mapping" (json) カラムもJavaScript側で受け取る
    render json: @templates.as_json(only: [:id, :name, :range, :mapping])
  end

  # POST /templates (JSON)
  # 照合実行画面からテンプレートを保存
  def create
    @template = current_user.templates.new(template_params)

    if @template.save
      # 保存成功
      
      # ログを作成
      create_log(
        "template_create",
        "テンプレート '#{@template.name}' (ID: #{@template.id}) を作成しました。",
        nil # (テンプレートは特定のプロジェクトには紐づかない)
      )

      # as_json で range と mapping も含めて返す
      render json: @template.as_json(only: [:id, :name, :range, :mapping]), status: :created
    else
      # 保存失敗
      render json: { errors: @template.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /templates/:id (JSON)
  def destroy
    @template = current_user.templates.find_by(id: params[:id])
    
    if @template
      # ログを作成
      create_log(
        "template_destroy",
        "テンプレート '#{@template.name}' (ID: #{@template.id}) を削除しました。",
        nil
      )
      
      @template.destroy
      render json: { message: 'Template deleted successfully.' }, status: :ok
    else
      render json: { error: 'Template not found.' }, status: :not_found
    end
  end

  private

  # Strong Parameters
  def template_params
    # "range" (座標) と "mapping" (解釈ルール) の両方を許可する
    
    params.require(:template).permit(
      :name, 
      # range: { a: [], b: [] } # (配列の中身を厳密にチェック)
      range: [:a, :b], # (a と b というキーを持つハッシュを許可)
      
      # mapping: { key_orientation: "...", key_index: "...", value_index: "..." }
      mapping: [:key_orientation, :key_index, :value_index]
    )
  end
end