Rails.application.routes.draw do
  root "pages#home"

  get "quickstart", to: "pages#quickstart"
  get "algorithms", to: "pages#algorithms"
  get "hybrid", to: "pages#hybrid"
  get "security", to: "pages#security"
  get "debugger", to: "pages#debugger"

  post "verify", to: "verify#create"

  resources :samples, only: :show, constraints: { id: /ml_dsa_(44|65|87)|hybrid_ml_dsa_(44|65|87)/ }

  get "/.well-known/jwks.json", to: "jwks#show", as: :jwks

  get "up", to: "health#show"
end
