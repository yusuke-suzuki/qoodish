Rails.application.routes.draw do
  if ENV['SUBSCRIBER_MODE']
    resources :messages, only: [:create]
    return
  end

  resources :users, only: %i[show create update destroy] do
    scope module: :users do
      resources :maps, only: [:index]
      resources :reviews, only: [:index]
      resource :push_notification, only: [:update]
    end
  end
  resources :devices, only: %i[update destroy]
  resources :maps do
    scope module: :maps do
      resources :reviews, only: %i[index show create]
      resources :collaborators, only: [:index]
      resource :follow, only: %i[create destroy]
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
  resources :notifications, only: %i[index update]

  namespace :guest do
    resources :maps, only: %i[index show] do
      scope module: :maps do
        resources :reviews, only: [:index]
        resources :spots, only: %i[index show] do
          scope module: :spots do
            resources :reviews, only: [:index]
          end
        end
        resources :collaborators, only: [:index]
      end
    end
    resources :reviews, only: %i[index show]
    resources :users, only: %i[show] do
      scope module: :users do
        resources :maps, only: [:index]
        resources :reviews, only: [:index]
      end
    end
  end

  get '/healthcheck' => 'application#healthcheck'
  root 'application#healthcheck'

  get '*path' => 'application#routing_error'
end
