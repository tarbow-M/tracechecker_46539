class TemplatesController < ApplicationController
  def index
    # 子プロの詳細ページで登録済みの照合範囲のテンプレートをプルダウンで表示するためのもの
    @templates = current_user.templates.order(name: :asc)
    
    # "range" (jsonb) カラムもJavaScript側で受け取るために "as_json" を使う
    render json: @templates.as_json(only: [:id, :name, :range])
  end

  def create
   @template = current_user.templates.new(template_params)

    if @template.save
      # 保存成功
      render json: @template.as_json(only: [:id, :name, :range]), status: :created # as_json で range も含めて返す
    else
      # 保存失敗（エラー文表示）
      render json: { errors: @template.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @template = current_user.templates.find_by(id: params[:id])
    
    if @template
      @template.destroy
      render json: { message: 'Template deleted successfully.' }, status: :ok
    else
      render json: { error: 'Template not found.' }, status: :not_found
    end
  end

  private

  def template_params
    # fetch (JavaScript) から送られてくる "range" (JSON) を許可する（"range" はキーを持つオブジェクト(ハッシュ)なので、キーの指定が必要）
    # デモ版のJavaScriptロジック (selectionCoordsA, selectionCoordsB) は
    # { "a": [...], "b": [...] } というJSONオブジェクトを送ってくることを想定
    
    # params.require(:template).permit(:name, range: {}) # {} だと空のハッシュしか許可されない
    
    # "range" の中身が { "a": [...], "b": [...] } であることを明示的に許可する
    params.require(:template).permit(:name, range: [a: [], b: []])
  end
end
