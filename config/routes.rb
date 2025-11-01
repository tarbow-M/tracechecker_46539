Rails.application.routes.draw do
  devise_for :users

  # URLのrootパスをトップページに。ただし未ログインユーザーはログイン画面へ（application_controller.rb記載）
  root 'parent_projects#index'  

  resources :parent_projects do
    resources :projects, except: [:index]
  end
end
