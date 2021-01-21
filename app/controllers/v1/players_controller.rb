# frozen_string_literal: true

module V1
  # Authentication
  class PlayersController < ApplicationController
    include Pagy::Backend
    before_action :authorize_request
    before_action :admin_only, except: %i[show]
    before_action :set_player, only: %i[show update]

    def index
      @pagy, @players = pagy(Player.all, overflow: :empty_page)

      player_show = []
      @players.each do |player|
        player_show.push(fetch_info(player))
      end
      render json: { players: player_show }
    end

    def show
      player_show = []
      @player.each do |player|
        player_show.push(fetch_info(player))
      end
      render json: { player: player_show }
    end

    def create
      player = Player.new(player_params)
      render json: { player: player.errors }, status: :unprocessable_entity and return unless player.save

      player_show = fetch_info(player)
      render json: { player: player_show }
    end

    def update
      @player.update(player_params)
      show
    end

    def destroy
      @player = Player.where(id: params[:id]).first
      render json: { errors: 'Invalid id' }, status: :ok and return if @player.nil?
      render json: { player: @player.errors }, status: :unprocessable_entity and return unless @player.destroy

      render json: { message: 'Player is deleted' }, status: :ok
    end

    private

    def set_player
      @player = Player.where(id: params[:id])
      render json: { errors: 'Invalid id' }, status: :ok and return if @player.empty?
    end

    def player_params
      params.require(:player).permit(:username, :password, :name, :wincount, :losecount, :isAdmin, :point)
    end

    def fetch_info(player)
      { 'id' => player.id,
        'name' => player.name,
        'point' => player.point,
        'wins_count' => player.wincount,
        'loses_count' => player.losecount }
    end
  end
end
