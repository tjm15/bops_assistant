BopsAssistant::Engine.routes.draw do
  resources :assessments, only: [:create, :index, :show]
  post "/callback", to: "callbacks#create"
  get  "/overlays/:id", to: "overlays#show", as: :overlay
end
