class ParentProjectsController < ApplicationController
  # ApplicationControllerで一括して :authenticate_user! が呼ばれる
  
  # (index 以外のアクションの前に @parent_project を読み込む)
  before_action :set_parent_project, only: [:show, :edit, :update, :destroy]

  # GET / (root)
  # (ダッシュボード)
  def index
    # ログイン中のユーザーに紐づく親プロジェクトのみを一覧表示
    @parent_projects = current_user.parent_projects.order(created_at: :desc)
  end

  # GET /parent_projects/:id
  # (親プロジェクト詳細)
  def show
    # @parent_project は set_parent_project で読み込み済み
    
    # 子プロジェクト(照合単位)の一覧を取得
    @projects = @parent_project.projects.order(created_at: :desc)
    
    # 添付されているファイル一覧を取得 (N+1問題対策)
    # (ActiveStorage::Attachment を created_at で並び替えてから、blob を読み込む)
    @files = @parent_project.files.joins(:blob).order('active_storage_attachments.created_at DESC')
  end

  # GET /parent_projects/new
  # (親プロジェクト新規作成フォーム)
  def new
    @parent_project = ParentProject.new
  end

  # POST /parent_projects
  def create
    # ログイン中のユーザーに紐づけて、新しい親プロジェクトを作成
    @parent_project = current_user.parent_projects.build(parent_project_params)

    if @parent_project.save
      # 保存成功
      
      # ログを作成
      create_log(
        "parent_project_create", 
        "親プロジェクト '#{@parent_project.name}' (ID: #{@parent_project.id}) を作成しました。",
        nil # (親プロジェクト作成ログは、特定の子プロジェクトには紐づかない)
      )
      
      flash[:notice] = "プロジェクト '#{@parent_project.name}' を作成しました。"
      redirect_to @parent_project # (作成した詳細ページ /parent_projects/:id へ)
    else
      # 保存失敗 (バリデーションエラーなど)
      # new.html.erb を再描画
      render :new, status: :unprocessable_entity
    end
  end

  # GET /parent_projects/:id/edit
  # (親プロジェクト編集フォーム)
  def edit
    # @parent_project は set_parent_project で読み込み済み
    # (app/views/parent_projects/edit.html.erb が必要)
  end

  # PATCH/PUT /parent_projects/:id
  def update
    # @parent_project は set_parent_project で読み込み済み
    
    # (ActiveStorage: 複数のファイルを "追加" (attach) する)
    if params[:parent_project][:files].present?
      @parent_project.files.attach(params[:parent_project][:files])
      # (ファイル追加時はバリデーションをスキップし、必ずshowにリダイレクト)
      flash[:notice] = "ファイルを追加しました。"
      redirect_to parent_project_path(@parent_project)
      
    # (通常のプロジェクト名更新)
    elsif @parent_project.update(parent_project_params)
      flash[:notice] = "プロジェクト '#{@parent_project.name}' を更新しました。"
      redirect_to @parent_project
    else
      # (ファイルアップロードの失敗時も、show を再描画)
      if params[:parent_project][:files].present?
        # (ファイル追加時のエラーハンドリング - 通常は発生しにくい)
        flash[:alert] = "ファイルのアップロードに失敗しました。"
        # (showアクションのインスタンス変数を再設定)
        @projects = @parent_project.projects.order(created_at: :desc)
        @files = @parent_project.files.joins(:blob).order('active_storage_attachments.created_at DESC')
        render :show, status: :unprocessable_entity
      else
        # (プロジェクト名更新のバリデーションエラー時)
        render :edit, status: :unprocessable_entity
      end
    end
  end

  # DELETE /parent_projects/:id
  def destroy
    # @parent_project は set_parent_project で読み込み済み
    @parent_project.destroy
    flash[:notice] = "プロジェクト '#{@parent_project.name}' を削除しました。"
    redirect_to root_path, status: :see_other
  end


  private

  # (index 以外で呼ばれる)
  def set_parent_project
    @parent_project = current_user.parent_projects.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "指定されたプロジェクトが見つかりません。"
    redirect_to root_path
  end

  # ストロングパラメータ
  def parent_project_params
    # (ActiveStorage: "files" は配列 [] として許可する)
    params.require(:parent_project).permit(:name, files: [])
  end
end

