Rails.application.routes.draw do
  unless TestTrack.enabled?
    namespace :tt do
      namespace :api do
        resource :split_registry, only: :show

        resource :assignment, only: :create

        resource :identifier, only: :create

        resources :visitors, only: [:show] do
          resource :assignment_registry, only: :show
        end

        resources :identifier_types, only: [], param: :name do
          resources :identifiers, only: [], param: :value do
            resource :visitor, only: :show, controller: 'identifier_visitors'
          end
        end

        # Server-side authenticated endpoints
        resources :split_configs, only: [:create, :destroy]
        resource :split_config, only: :create # TODO remove this route once the client is using the pluralize routes
        resource :identifier_type, only: :create
      end
    end
  end
end
