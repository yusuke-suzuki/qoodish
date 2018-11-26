Rails.application.routes.draw do
  resources :users do
    scope module: :users do
      resources :maps, only: [:index]
      resources :reviews, only: [:index]
      resource :push_notification, only: [:create, :destroy]
    end
  end
  resources :devices, only: [:create, :destroy]
  resources :maps do
    scope module: :maps do
      resources :reviews, only: [:index, :show, :create]
      resources :spots, only: [:index, :show]
      resources :collaborators, only: [:index]
      resources :invites, only: [:create]
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
  resources :spots, only: [:index, :show] do
    scope module: :spots do
      resources :reviews, only: [:index]
      resource :metadata, only: [:show]
    end
  end
  resources :notifications, only: [:index, :update]
  resources :invites, only: [:index]
end
