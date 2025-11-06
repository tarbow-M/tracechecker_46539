class ProjectsController < ApplicationController
  # ApplicationControllerで一括して :authenticate_user! が呼ばれる
  
  # 先に親プロジェクト(@parent_project)をURLから読み込む
  before_action :set_parent_project
  # Project が必要なアクションの前に @project を読み込む
  before_action :set_project, only: [:show, :edit, :update, :destroy, :unlock] # :unlock を追加

  # GET /parent_projects/:parent_project_id/projects/:id
  # (照合実行画面)
  def show
    # @project は set_project で読み込み済み
    
    # ファイル選択ドロップダウン用に、親プロジェクトが持つファイル一覧を取得
    @files = @parent_project.files.joins(:blob).order('active_storage_attachments.created_at DESC')

    # ▼▼▼ リファクタリングにより削除 ▼▼▼
    # (ダミーデータは file_preview アクション (ParentProjectsController) が
    #  fetch (AJAX) 経由で提供するため、ここでは不要)
    # @dummy_data_a = generate_dummy_data(true)
    # @dummy_data_b = generate_dummy_data(false)
    # ▲▲▲ 削除ここまで ▲▲▲
  end

  # GET /parent_projects/:parent_project_id/projects/new
  # (子プロジェクト新規作成フォーム)
  def new
    # 親 (@parent_project) に紐づいた空の子 (@project) を作成
    @project = @parent_project.projects.build
  end

  # POST /parent_projects/:parent_project_id/projects
  def create
    @project = @parent_project.projects.build(project_params_for_create) # create 用のストロングパラメータを使用
    
    # (デフォルト値を設定)
    @project.status = '未実行' 
    @project.is_locked = false

    if @project.save
      # ログを作成
      create_log(
        "project_create", 
        "照合単位 '#{@project.name}' (ID: #{@project.id}) を作成しました。",
        @project # 関連する子プロジェクト
      )
      
      flash[:notice] = "照合単位 '#{@project.name}' を作成しました。"
      redirect_to parent_project_path(@parent_project) # 親の詳細ページに戻る
    else
      # 保存失敗 (バリデーションエラーなど)
      # new.html.erb を再描画
      render :new, status: :unprocessable_entity
    end
  end

  # GET /parent_projects/:parent_project_id/projects/:id/edit
  # (子プロジェクト編集フォーム)
  def edit
    # @project は set_project で読み込み済み
  end

  # PATCH/PUT /parent_projects/:parent_project_id/projects/:id
  def update
    # @project は set_project で読み込み済み
    if @project.update(project_params_for_update) # update 用のストロングパラメータを使用
      
      # ログを作成
      create_log(
        "project_update", 
        "照合単位 '#{@project.name}' (ID: #{@project.id}) を更新しました。",
        @project
      )
      
      flash[:notice] = "照合単位 '#{@project.name}' を更新しました。"
      redirect_to parent_project_path(@parent_project)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /parent_projects/:parent_project_id/projects/:id
  def destroy
    # @project は set_project で読み込み済み
    
    # ログを作成
    create_log(
      "project_destroy", 
      "照合単位 '#{@project.name}' (ID: #{@project.id}) を削除しました。",
      @project
    )
    
    @project.destroy
    flash[:notice] = "照合単位 '#{@project.name}' を削除しました。"
    redirect_to parent_project_path(@parent_project), status: :see_other
  end
  
  # ▼▼▼ ロック解除 (unlock) アクション (新規追加) ▼▼▼
  # PATCH /parent_projects/:parent_project_id/projects/:id/unlock
  def unlock
    # @project は set_project で読み込み済み
    if @project.update(is_locked: false, status: '再確認中')
      
      # ログを作成
      create_log(
        "project_unlock", 
        "照合単位 '#{@project.name}' (ID: #{@project.id}) のロックを解除しました。",
        @project
      )
      
      # JavaScript fetch からの呼び出しに対応するため、respond_to ブロック使用
      respond_to do |format|
        format.html do
          # 通常のフォーム送信（button_to）の場合
          flash[:notice] = "プロジェクトのロックを解除しました。再確認モードで照合を実行できます。"
          redirect_to parent_project_project_path(@parent_project, @project)
        end
        format.json do
          # JavaScript fetch からの場合
          render json: { 
            success: true, 
            message: 'ロックを解除しました' 
          }
        end
      end
    else
      respond_to do |format|
        format.html do
          flash[:alert] = "ロック解除に失敗しました。"
          redirect_to parent_project_project_path(@parent_project, @project)
        end
        format.json do
          render json: { 
            success: false, 
            errors: @project.errors.full_messages 
          }, status: :unprocessable_entity
        end
      end
    end
  end


  private

  # 親プロジェクトを読み込む
  def set_parent_project
    # (ParentProjectsController からロジックを共通化)
    @parent_project = current_user.parent_projects.find(params[:parent_project_id])
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "指定された親プロジェクトが見つかりません。"
    redirect_to root_path
  end

  # @project を読み込む
  def set_project
    @project = @parent_project.projects.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "指定された照合単位が見つかりません。"
    redirect_to parent_project_path(@parent_project)
  end

  # ストロングパラメータ (create時)
  def project_params_for_create
    # (status, last_run, diff_count, is_locked は
    #  DBのデフォルト値 または create アクションで設定するため、:name のみ許可)
    params.require(:project).permit(:name)
  end
  
  # ストロングパラメータ (update時)
  def project_params_for_update
     # (編集フォーム (edit.html.erb) で変更を許可するカラム)
     params.require(:project).permit(:name)
  end
  
  # ▼▼▼ リファクタリングにより削除 ▼▼▼
  # (ダミーデータ生成ロジックは ParentProjectsController#file_preview に移行)
  # def generate_dummy_data(is_a)
  #   ...
  # end
  # ▲▲▲ 削除ここまで ▲▲▲
end