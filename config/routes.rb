Rails.application.routes.draw do
  unless TestTrack.enabled?
    namespace :tt do
      namespace :api do
        namespace :v1 do
          resource :assignment, only: :create

          resource :identifier, only: :create

          resources :visitors, only: :show

          resource :split_detail, only: :show

          resources :identifier_types, only: [], param: :name do
            resources :identifiers, only: [], param: :value do
              resource :visitor, only: :show, controller: 'identifier_visitors'
              resource :visitor_details, only: :show
            end
          end

          resources :split_configs, only: [:create, :destroy]
          resource :identifier_type, only: :create

          resource :reset, only: :update
        end
      end
    end
  end
end
