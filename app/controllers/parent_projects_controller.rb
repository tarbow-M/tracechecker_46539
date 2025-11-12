# Excel/CSV ファイルの読み込みに 'roo' Gem を
require 'roo'

class ParentProjectsController < ApplicationController
  # ApplicationControllerで一括して :authenticate_user! が呼ばれる
  
  # (index 以外のアクションの前に @parent_project を読み込む)
  before_action :set_parent_project, only: [:show, :edit, :update, :destroy, :file_preview, :file_remove] # file_preview を追加

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
    @projects = @parent_project.projects.includes(:archived_results).order(created_at: :desc)
    
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
  end

  # PATCH/PUT /parent_projects/:id
  def update
    # @parent_project は set_parent_project で読み込み済み
    
    # (ActiveStorage: 複数のファイルを "追加" (attach) する)
    if params[:parent_project][:files].present?
      @parent_project.files.attach(params[:parent_project][:files])
      flash[:notice] = "ファイルを追加しました。"
      redirect_to parent_project_path(@parent_project)
      
    # (通常のプロジェクト名更新)
    elsif @parent_project.update(parent_project_params)
      flash[:notice] = "プロジェクト '#{@parent_project.name}' を更新しました。"
      redirect_to @parent_project
    else
      # (ファイルアップロードの失敗時も、show を再描画)
      if params[:parent_project][:files].present?
        flash[:alert] = "ファイルのアップロードに失敗しました。"
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
    
    create_log(
      "parent_project_destroy",
      "親プロジェクト '#{@parent_project.name}' (ID: #{@parent_project.id}) を削除しました。",
      nil
    )
    
    @parent_project.destroy
    flash[:notice] = "プロジェクト '#{@parent_project.name}' を削除しました。"
    redirect_to root_path, status: :see_other
  end

  # ファイルプレビュー機能 
  # (Roo で読み込んだ「生の2次元配列」をそのままJSONで返す)
  # GET /parent_projects/:id/file_preview/:file_id
  def file_preview
    # @parent_project は set_parent_project で読み込み済み
    
    begin
      # 1. :file_id から、この親プロジェクトに紐づく添付ファイル(Attachment)を探す
      attachment = @parent_project.files_attachments.find(params[:file_id])
      
      @raw_data = [] # 生の2次元配列を格納

      # 2. ActiveStorage のファイルを一時ファイルとして開く
      attachment.blob.open do |tempfile|
        
        # 3. ファイルの拡張子を取得
        extension = File.extname(attachment.filename.to_s).downcase.delete('.')

        # 4. Roo でスプレッドシートを開く (Roo v2.8.0以降は .new ではなく .open を使用)
        spreadsheet = Roo::Spreadsheet.open(tempfile.path, extension: extension)
        
        # 5. 拡張子に応じて、生の2次元配列として読み込む(.xlsx と .xlsm の両方をExcelとして扱う)
        if spreadsheet.is_a?(Roo::Excelx) || spreadsheet.is_a?(Roo::Excelxm)

          # --- .xlsx/.xlsm (Excel) の場合 ---
          sheet = spreadsheet.sheet(0) # 最初のシート
          
          # "to_a" でシート全体をrubyの2次元配列に変換（2次元配列とは、配列の中にさらに配列が入っている構造で、Excelの行と列の構造を表現）
          # Excelシートを2次元配列に変換し、さらにその中のすべてのセルの値を文字列に変換して、きれいなデータセットを作る
          @raw_data = sheet.to_a.map { |row| row.map(&:to_s) }
          
        elsif spreadsheet.is_a?(Roo::CSV)
          # --- .csv の場合 ---
          
          # "to_a" でシート全体を2次元配列に変換
          @raw_data = spreadsheet.to_a.map { |row| row.map(&:to_s) }
          
        else
          # --- サポート外のファイル (PDFなど) ---
          raise "Rooではサポートされていないファイル形式です: .#{extension}"
        end
      end # (open do ... end)

      # 6. 成功時: 抽出した「生の2次元配列」をJSONで返す
      # (JavaScript側がマッピング（解釈）を担当する)
      render json: @raw_data

    rescue => e
      # 例外クラスとメッセージをログに出力
      logger.error "ファイルプレビュー処理中にエラーが発生しました: #{e.class}"
      logger.error "エラーメッセージ: #{e.message}"
      # バックトレースも出力すると、より詳細な原因がわかります
      logger.error e.backtrace.join("\n")

      # 7. エラー時
      render json: { 
        error: 'ファイルの読み込みに失敗しました', 
        message: e.message 
      }, status: :unprocessable_entity # (422 エラー)
    end
  end
  
  # ファイル削除機能
  def file_remove
    # @parent_project は set_parent_project で読み込み済み

    begin # begin：エラーになるかもしれない処理を記述する際に使用
      # 1. :file_id から、この親プロジェクトに紐づく添付ファイルを探す
      attachment = @parent_project.files_attachments.find(params[:file_id])
      filename = attachment.filename.to_s # ファイル名を取得

      # 2. 添付ファイルを削除
      attachment.purge # .purge：削除
      flash[:notice] = "ファイル '#{filename}' を削除しました"
    
    ## エラー処理（rescue：beginとセットでダメだった時の処理を記述）
    rescue ActiveRecord::RecordNotFound
      flash[:alert] = "指定されたファイルが見つかりません"
    rescue => e  # e：エラー情報が入っている変数
      flash[:alert] = "ファイルの削除に失敗しました: #{e.message}"
    end

    # 3. 削除後、親の詳細ページにリダイレクト
    redirect_to parent_project_path(@parent_project)
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
    # (update アクションとの競合を避けるため、:name のみを許可)
    params.require(:parent_project).permit(:name)
  end
end