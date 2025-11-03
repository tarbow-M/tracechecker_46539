class ProjectsController < ApplicationController
  # before_action :authenticate_user!
  before_action :set_parent_project
  before_action :set_project, only: [:edit, :update, :destroy] # :show は除外

  # 先に親プロジェクト(@parent_project)をURLから読み込む
  before_action :set_parent_project

  def new
    @project = @parent_project.projects.build # ファームを親IDと紐づける場合はnewではなくbuildを使用
  end

  def create
    @project = @parent_project.projects.build(project_params)
    @project.status = '未実行' # (デフォルト値を設定する場合)

    if @project.save
      redirect_to parent_project_path(@parent_project), notice: '処理名を作成しました。'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    # ネストされた :id (子プロジェクトのID) で @project を検索
    @project = @parent_project.projects.find(params[:id])

    # ファイル選択ドロップダウン用に、親プロジェクトが持つファイル一覧を取得
    @files = @parent_project.files.order('active_storage_attachments.created_at DESC')

   # (デモ用のダミーデータをビューに渡す)
    @dummy_data_a = generate_dummy_data(true)
    @dummy_data_b = generate_dummy_data(false)
  end

    # GET /parent_projects/:parent_project_id/projects/:id/edit
  def edit
    # @project は set_project で設定
  end

  # PATCH/PUT /parent_projects/:parent_project_id/projects/:id
  def update
    # @project は set_project で設定
    if @project.update(project_params)
      redirect_to parent_project_path(@parent_project), notice: '照合単位を正常に更新しました。'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /parent_projects/:parent_project_id/projects/:id
  def destroy
    # @project は set_project で設定
    @project.destroy
    redirect_to parent_project_path(@parent_project), notice: '照合単位を削除しました。', status: :see_other
  end

  private

  # 親プロジェクトをセットする
  def set_parent_project
    # ログイン中のユーザーに紐づく親プロジェクトのみを検索
    @parent_project = current_user.parent_projects.find(params[:parent_project_id])
  end

  # 子プロジェクトを読み込む (show以外)
  def set_project
    @project = @parent_project.projects.find(params[:id])
  end

  # ストロングパラメータ
  def project_params
    params.require(:project).permit(:name, :status, :last_run, :diff_count, :is_locked)
  end
  
  # (デモ用のダミーデータ)
  def generate_dummy_data(is_a)
    base_data = [
        { key: 'ユーザー数', goal: 500, result: is_a ? 480 : 510, type: 'KPI' }, 
        { key: 'コンバージョン率', goal: '5.0%', result: '4.9%', type: 'KPI' }, 
        { key: '平均滞在時間', goal: is_a ? '4分30秒' : '5分00秒', result: '4分32秒', type: 'KPI' }, 
        { key: '資料Aのみ (項目追加)', goal: 'N/A', result: 'N/A', type: 'KPI' }
    ]
    
    data_b_only = [
        { key: '直帰率', goal: '30%', result: '35%', type: 'KPI' },
        { key: '資料Bのみ (項目削除)', goal: '100', result: '120', type: 'KPI' }
    ]

    final_data = is_a ? base_data : base_data[0..2] + data_b_only
    
    # 順序をシャッフル (AとBで順序が異なることをシミュレート)
    is_a ? final_data.shuffle(random: Random.new(1)) : final_data.shuffle(random: Random.new(2))
  end
end
