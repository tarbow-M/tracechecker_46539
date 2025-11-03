Rails.application.routes.draw do
  devise_for :users

  # URLのrootパスをトップページに。ただし未ログインユーザーはログイン画面へ（application_controller.rb記載）
  root 'parent_projects#index'  

  resources :parent_projects do
    resources :projects, except: [:index] do
      resources :archived_results, only: [:create]
    end
  end

  resources :templates, only: [:index, :create, :destroy]
  resources :logs, only: [:index]

  # (rails7.1標準搭載の本番環境の定期チェック)
  get "up" => "rails/health#show", as: :rails_health_check
end
