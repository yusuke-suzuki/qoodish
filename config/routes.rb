Rails.application.routes.draw do
  resources :users, only: %i[index show create] do
    scope module: :users do
      resources :maps, only: [:index]
      resources :chapters, only: [:index]
      resource :journal, only: [:show]
      resource :block, only: %i[create destroy]
      resource :mute, only: %i[create destroy]
    end
  end
  resources :maps do
    scope module: :maps do
      resources :pins, only: %i[index create]
      resources :coauthors, only: %i[index destroy]
      resource :bookmark, only: %i[create destroy]
      resources :coauthorship_invitations, only: [:create]
      resources :journeys, only: [:create]
      resources :chapters, only: %i[index create]
      resources :pin_properties, only: %i[index create update destroy] do
        scope module: :pin_properties do
          resources :options, only: %i[create update destroy]
        end
      end
    end
  end
  resources :pins, only: [:show] do
    scope module: :pins do
      resource :like, only: %i[create destroy]
      resources :likes, only: [:index]
      resources :comments, only: %i[create update destroy] do
        scope module: :comments do
          resource :like, only: %i[create destroy]
          resources :likes, only: [:index]
        end
      end
    end
  end
  namespace :me do
    resource :profile, only: %i[show update]
    resource :account, only: [:destroy]
    resource :journal, only: %i[show update]
    resource :preferences, only: [:update]
    resources :maps, only: [:index]
    resources :pins, only: %i[update destroy]
    resources :devices, only: %i[update destroy]
    resources :notifications, only: [:update]
    resources :coauthorship_invitations, only: [:index] do
      member do
        post :accept
        post :decline
      end
    end
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
    namespace :bookmarks do
      resources :maps, only: [:index]
      resources :journals, only: [:index]
    end
  end
  namespace :v2 do
    resources :pins, only: [:index]
    resources :users, only: [] do
      scope module: :users do
        resources :pins, only: [:index]
      end
    end
    namespace :me do
      resources :notifications, only: [:index]
      resources :pins, only: [:index]
      resources :mutes, only: [:index]
      resources :blocks, only: [:index]
    end
  end
  scope 'guest/v2', module: 'v2/guest', as: 'v2_guest' do
    resources :pins, only: [:index]
    resources :chapters, only: [:index]
    resources :users, only: [] do
      scope module: :users do
        resources :pins, only: [:index]
      end
    end
  end
  resources :chapters, only: %i[index show] do
    scope module: :chapters do
      resource :like, only: %i[create destroy]
      resources :comments, only: %i[index create update destroy] do
        scope module: :comments do
          resource :like, only: %i[create destroy]
        end
      end
    end
  end
  resources :journals, only: [:show] do
    scope module: :journals do
      resource :bookmark, only: %i[create destroy]
    end
  end
  resources :reports, only: [:create]
  resources :images, only: [:create]

  namespace :admin do
    resources :reports, only: %i[index show] do
      scope module: :reports do
        resource :decision, only: [:create]
      end
    end
    resources :staff_members, only: %i[index create] do
      scope module: :staff_members do
        resources :roles, only: [:destroy]
        resource :revocation, only: [:create]
      end
    end
    resources :roles, only: [:index]
  end

  namespace :guest do
    resources :maps, only: %i[index show] do
      get :featured, on: :collection

      scope module: :maps do
        resources :pins, only: [:index]
        resources :coauthors, only: [:index]
        resources :chapters, only: [:index]
        resources :pin_properties, only: [:index]
      end
    end
    resources :pins, only: %i[index show]
    resources :chapters, only: %i[index show] do
      scope module: :chapters do
        resources :comments, only: [:index]
      end
    end
    resources :users, only: %i[show] do
      scope module: :users do
        resources :maps, only: [:index]
        resources :chapters, only: [:index]
      end
    end
  end

  get '/healthcheck' => 'application#healthcheck'
  root 'application#healthcheck'

  get '*path' => 'application#routing_error'
end
