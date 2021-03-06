Rails.application.routes.draw do
  if ENV['SUBSCRIBER_MODE']
    resources :messages, only: [:create]
    return
  end

  resources :users do
    scope module: :users do
      resources :maps, only: [:index]
      resources :reviews, only: [:index]
      resources :likes, only: [:index]
      resource :push_notification, only: [:update]
    end
  end
  resources :devices, only: %i[update destroy]
  resources :maps do
    scope module: :maps do
      resources :reviews, only: %i[index show create]
      resources :spots, only: %i[index show] do
        scope module: :spots do
          resources :reviews, only: [:index]
        end
      end
      resources :collaborators, only: [:index]
      resources :invites, only: [:create]
      resource :follow, only: %i[create destroy]
      resource :like, only: %i[create destroy]
      resources :likes, only: [:index]
    end
  end
  resources :reviews, only: %i[index update destroy] do
    scope module: :reviews do
      resource :like, only: %i[create destroy]
      resources :likes, only: [:index]
      resources :comments, only: %i[create destroy] do
        scope module: :comments do
          resource :like, only: %i[create destroy]
          resources :likes, only: [:index]
        end
      end
    end
  end
  resources :inappropriate_contents, only: [:create]
  resources :places, only: [:index]
  resources :spots, only: %i[index show] do
    scope module: :spots do
      resources :reviews, only: [:index]
    end
  end
  resources :notifications, only: %i[index update]
  resources :invites, only: [:index]


  get '/healthcheck' => 'application#healthcheck'
  root 'application#healthcheck'

  get '*path' => 'application#routing_error'
end
