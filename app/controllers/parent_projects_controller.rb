class ParentProjectsController < ApplicationController
  before_action :authenticate_user!
  # ▼▼▼ :show, :edit, :update, :destroy の前に @parent_project をセットする ▼▼▼
  before_action :set_parent_project, only: [:show, :edit, :update, :destroy]

  # GET / トップページ
  def index
    # 現在ログインしているユーザーに紐づく ParentProject のみを取得し、作成日時の降順（新しいものが上）に並び替える
    @parent_projects = current_user.parent_projects.order(created_at: :desc)
  end

  # (今後、show, new, create などのアクションもここに追加していきます)

  # GET /parent_projects/:id
  def show
    @projects = @parent_project.projects.order(created_at: :desc)
    
    # ActiveStorageのファイルも読み込む
    # （N+1問題を避けるため、.with_attached_files を含める）
    @files = @parent_project.files.order('active_storage_attachments.created_at DESC')
  end

  # GET /parent_projects/new（新規作成）
  def new
    @parent_project = ParentProject.new
  end

  # POST /parent_projects（新規登録保存）
  def create
    @parent_project = current_user.parent_projects.build(parent_project_params)
    if @parent_project.save
      redirect_to @parent_project, notice: 'プロジェクトを作成しました。'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # @parent_project は before_action でセットされる
  end

  def update
    # @parent_project は before_action でセットされる
    project_params = parent_project_params_for_update
    # :files のみを取得 (配列として)
    files_to_attach = params[:parent_project][:files]

    # まず :name などの更新を試みる（:name もフォームにあれば更新される）
    if @parent_project.update(project_params)
      
      # :name の更新が成功したら、ファイルの添付処理を行う
      if files_to_attach.present?
        # .attach メソッドでファイルを追加（Append）する（files_to_attach が配列でも1ファイルでも対応可能）
        @parent_project.files.attach(files_to_attach)
      end
      
      # 成功したらshowページにリダイレクト
      redirect_to @parent_project, notice: 'プロジェクトが更新されました。'
    else
      # :name の更新に失敗した場合（バリデーションエラーなど）
      # 失敗したらshowページを再描画
      @projects = @parent_project.projects.order(created_at: :desc)
      @files = @parent_project.files.order('active_storage_attachments.created_at DESC')
      render :show, status: :unprocessable_entity
    end
  end

  def destroy
    # @parent_project は before_action でセットされます
    @parent_project.destroy
    redirect_to root_path, notice: 'プロジェクトを削除しました。', status: :see_other
  end

  private

  def parent_project_params
    # 親プロジェクト名とファイルアップロードを許可
    params.require(:parent_project).permit(:name, files: [])
  end
  
  def set_parent_project
    # current_user に紐づくプロジェクトのみを検索対象とする (セキュリティ)
    @parent_project = current_user.parent_projects.find(params[:id])
  end

  # updateアクション専用のストロングパラメータを追加（:files を除外する。attachで別途処理するため）
  def parent_project_params_for_update
    params.require(:parent_project).permit(:name)
  end
end
