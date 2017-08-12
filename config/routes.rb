Rails.application.routes.draw do
  resources :users, only: [:create, :destroy]
  resources :maps do
    scope module: :maps do
      resources :reviews, only: [:index, :show, :create]
      resources :spots, only: [:index, :show]
      resources :collaborators, only: [:index]
      resource :follow, only: [:create, :destroy]
    end
  end
  resources :reviews, only: [:update, :destroy]
end
