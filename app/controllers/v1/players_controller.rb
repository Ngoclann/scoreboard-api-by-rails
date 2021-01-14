class V1::PlayersController < ApplicationController
    before_action :set_player, only: [:show, :update]

    def index
        @players = Player.all

        render json: @players, status: :ok
    end

    def show
        render json: @player, status: :ok
    end

    def create
        @player = Player.new(player_params)

        @player.save
        render json: @player, status: :created
    end

    def update
        @player.update(player_params)
        
        render json: @player, status: :ok
    end

    def destroy
        @player = Player.where(id: params[:id]).first
        if(@player.destroy)
            head(:ok)
        else
            head(:unprocessable_entity)
        end
       
    end

    private

    def set_player
        @player = Player.where(id: params[:id])
    end

    def player_params
        params.require(:player).permit(:username, :password, :wins_count, :loses_count)
    end
end
