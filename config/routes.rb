Rails.application.routes.draw do
  # Registration
  get  "sign_up", to: "registrations#new"
  post "sign_up", to: "registrations#create"

  # Sessions
  get    "sign_in",  to: "sessions#new"
  post   "sign_in",  to: "sessions#create"
  delete "sign_out", to: "sessions#destroy"

  # Passwords
  get   "passwords/new",          to: "passwords#new",    as: :new_password
  post  "passwords",              to: "passwords#create",  as: :passwords
  get   "passwords/:token/edit",  to: "passwords#edit",    as: :edit_password
  patch "passwords/:token",       to: "passwords#update",  as: :password

  # Email Verification
  get  "email_verification", to: "email_verifications#show"
  post "email_verification", to: "email_verifications#create"

  # OAuth (OmniAuth middleware handles POST /auth/:provider)
  get  "auth/:provider/callback", to: "oauth_callbacks#create"
  get  "auth/failure",            to: "oauth_callbacks#failure"
  get  "auth/terms",              to: "oauth_callbacks#terms_acceptance"
  post "auth/terms",              to: "oauth_callbacks#accept_terms"
  get  "auth/link",               to: "oauth_callbacks#link_account"
  post "auth/link",               to: "oauth_callbacks#confirm_link"

  # Two-Factor Authentication
  get    "two_factor/new",            to: "two_factor_authentication#new",            as: :new_two_factor
  post   "two_factor",                to: "two_factor_authentication#create",         as: :two_factor
  delete "two_factor",                to: "two_factor_authentication#destroy"
  get    "two_factor/verify",         to: "two_factor_authentication#verify",         as: :verify_two_factor
  post   "two_factor/verify",         to: "two_factor_authentication#confirm",        as: :confirm_two_factor
  get    "two_factor/recovery_codes", to: "two_factor_authentication#recovery_codes", as: :two_factor_recovery_codes
  get    "two_factor/recovery_help",  to: "two_factor_authentication#recovery_help",  as: :two_factor_recovery_help

  # TODO Lists
  resources :todo_lists, path: "lists" do
    resources :todo_items, path: "items", except: [ :index ] do
      member do
        patch :toggle
        patch :archive
        patch :move
        post :copy
      end
      collection do
        patch :reorder
      end

      resources :checklist_items, path: "checklist", only: [ :create, :update, :destroy ] do
        member do
          patch :toggle
        end
      end

      resources :tags, only: [ :create, :destroy ]
      resources :attachments, only: [ :create, :destroy ]
      resources :comments, only: [ :create, :update, :destroy ] do
        resources :likes, only: [ :create, :destroy ], controller: "comment_likes"
      end
      resources :notify_people, only: [ :create, :destroy ]
      resources :item_assignees, path: "assignees", only: [ :create, :destroy ]
    end

    resources :todo_sections, path: "sections", except: [ :index, :show ] do
      member do
        patch :archive
        patch :move
      end
      collection do
        patch :reorder
      end
    end

    # Collaboration
    resources :collaborators, controller: "list_collaborators", only: [ :index, :update, :destroy ]
    delete "leave", to: "list_collaborators#leave", as: :leave
    resources :invitations, controller: "list_invitations", only: [ :create, :destroy ]
  end

  # Invitation acceptance (top-level, token-based)
  get "invitations/:token/accept", to: "list_invitations#accept", as: :accept_invitation

  # Root
  root "todo_lists#index"

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
