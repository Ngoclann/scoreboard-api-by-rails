Rails.application.routes.draw do
  # devise_for :users
  namespace :v1, defaults: { format: :json } do
    resources :players
    resources :games
    post '/games/:gameid/score', to: 'games#score'
    delete '/games/:gameid/reset_point', to: 'games#reset_point'
    put '/games/:gameid/end', to: 'games#end_game'
    get '/leaderboard', to: 'games#leaderboard'
    post '/auth/login', to: 'authentication#login'
    post '/auth/logout', to: 'authentication#logout'
    get '/*a', to: 'application#not_found'
  end
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
