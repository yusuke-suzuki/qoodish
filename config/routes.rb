Rails.application.routes.draw do
  resources :users, only: %i[index show create update destroy] do
    scope module: :users do
      resources :maps, only: [:index]
      resources :reviews, only: [:index]
      resources :bookmarks, only: [:index]
      resources :chapters, only: [:index]
      resource :push_notification, only: [:update]
    end
  end
  resources :devices, only: %i[update destroy]
  resources :maps do
    scope module: :maps do
      resources :reviews, only: %i[index show create]
      resources :coauthors, only: %i[index destroy]
      resource :bookmark, only: %i[create destroy]
      resources :coauthorship_invitations, only: [:create]
      resources :journeys, only: [:create]
      resources :chapters, only: [:create]
    end
  end
  resources :coauthorship_invitations, only: [:index] do
    member do
      post :accept
      post :decline
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
  namespace :me do
    resources :journeys, only: %i[index show destroy] do
      member do
        post :start
        post :finish
      end
      scope module: :journeys do
        resources :milestones, only: %i[create destroy]
        resources :checkins, only: %i[create update destroy]
      end
    end
    resources :chapters, only: %i[index show update destroy]
  end
  resources :chapters, only: %i[index show]
  resources :inappropriate_contents, only: [:create]
  resources :notifications, only: %i[index update]
  resources :images, only: [:create]

  namespace :guest do
    resources :maps, only: %i[index show] do
      scope module: :maps do
        resources :reviews, only: [:index]
        resources :spots, only: %i[index show] do
          scope module: :spots do
            resources :reviews, only: [:index]
          end
        end
        resources :coauthors, only: [:index]
      end
    end
    resources :reviews, only: %i[index show]
    resources :chapters, only: %i[index show]
    resources :users, only: %i[show] do
      scope module: :users do
        resources :maps, only: [:index]
        resources :reviews, only: [:index]
        resources :bookmarks, only: [:index]
        resources :chapters, only: [:index]
      end
    end
  end

  get '/healthcheck' => 'application#healthcheck'
  root 'application#healthcheck'

  get '*path' => 'application#routing_error'
end
