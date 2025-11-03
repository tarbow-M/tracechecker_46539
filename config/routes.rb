Rails.application.routes.draw do
  devise_for :users

  # URLのrootパスをトップページに。ただし未ログインユーザーはログイン画面へ（application_controller.rb記載）
  root 'parent_projects#index'  

  resources :parent_projects do
    resources :projects, except: [:index] do
      resources :archived_results, only: [:create, :index, :show] # (index, show は将来の証跡閲覧用)
    end
  end

  resources :templates, only: [:index, :create, :destroy]


end
