Rails.application.routes.draw do
  resources :users, only: [:show, :create, :destroy]
  resources :devices, only: [:create]
  resources :maps do
    scope module: :maps do
      resources :reviews, only: [:index, :show, :create]
      resources :spots, only: [:index, :show]
      resources :collaborators, only: [:index]
      resource :follow, only: [:create, :destroy]
      resource :metadata, only: [:show]
    end
  end
  resources :reviews, only: [:index, :update, :destroy] do
    scope module: :reviews do
      resource :metadata, only: [:show]
    end
  end
  resources :inappropriate_contents, only: [:create]
end
