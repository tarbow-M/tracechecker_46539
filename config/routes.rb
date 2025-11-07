Rails.application.routes.draw do
  devise_for :users

  # URLのrootパスをトップページに。ただし未ログインユーザーはログイン画面へ（application_controller.rb記載）
  root 'parent_projects#index'  

  resources :parent_projects do
    
    # ファイルプレビュー用のルーティング
    member do
      # (:id ではなく :file_id でファイルBLOBのIDを受け取る)
      get 'file_preview/:file_id', to: 'parent_projects#file_preview', as: 'file_preview'
      delete 'file_remove/:file_id', to: 'parent_projects#file_remove', as: 'file_remove'
    end

    resources :projects, except: [:index] do
      # unlockアクション追加
      member do
        patch :unlock
      end

      resources :archived_results, only: [:create]
    end
  end

  resources :templates, only: [:index, :create, :destroy]
  resources :logs, only: [:index]

  # (rails7.1標準搭載の本番環境の定期チェック)
  get "up" => "rails/health#show", as: :rails_health_check
end
