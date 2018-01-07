Rails.application.routes.draw do
  scope :api do
    resources :users, only: [:show, :create, :destroy] do
      scope module: :users do
        resources :maps, only: [:index]
      end
    end
    resources :devices, only: [:create, :destroy]
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
        resource :like, only: [:create, :destroy]
        resources :likes, only: [:index]
      end
    end
    resources :inappropriate_contents, only: [:create]
    resources :places, only: [:index]
    resources :notifications, only: [:index, :update]
  end
end
