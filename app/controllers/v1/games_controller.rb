# frozen_string_literal: true

module V1
  # Game
  class GamesController < ApplicationController
    before_action :authorize_request, except: %i[leaderboard]
    before_action :admin_only, only: %i[create reset_point end_game]
    def create
      player1 = params['A']
      player2 = params['B']
      render json: { message: 'There must be 2 separate player' } and return if player1 == player2

      valid_player(player1, player2); return if performed?

      create_new_game(player1, player2); return if performed?
    end

    def score
      game_id = params[:gameid]
      player_id = params[:player_id]
      valid_id(game_id, player_id); return if performed?

      update_point_score1(game_id) if specify_player(player_id, game_id) == 1
      update_point_score2(game_id) if specify_player(player_id, game_id) == 2
    end

    def reset_point
      game_id = params[:gameid]
      player_id = params[:player_id]
      stride = params[:step]
      choice = params[:choice]
      valid_id(game_id, player_id); return if performed?

      render json: { error: 'Invalid choice (undo/ redo)' } and return if !(choice.eql? 'undo') && !(choice.eql? 'redo')

      reset_log_player(stride, choice, game_id, player_id)
    end

    def end_game
      game = Game.find_by(id: params[:gameid], isPlaying: true)
      log1 = Log.find_by(gameid: params[:gameid], isP1LastPoint: true)
      log2 = Log.find_by(gameid: params[:gameid], isP2LastPoint: true)
      render json: { message: 'Invalid game id or game not start' } and return if game.nil? && log1.nil? && log2.nil?

      update_result_end(game, log1, log2)
      render json: { message: 'End game' }
    end

    def show
      game_id = params[:id]
      game = Game.find_by(id: game_id)
      render json: { message: 'Invalid game id' } and return if game.nil?

      render json: { game: fetch_info_game(game.player1, game.player2, game.id, game.winner) }
    end

    def leaderboard
      player_show = []
      players = Player.find_by_sql('SELECT * FROM players t ORDER BY (t.wincount - t.losecount) DESC')
      players.each do |player|
        player_show.push(fetch_info_player(player))
      end
      render json: { leaderboard: player_show }
    end

    private

    def valid_player(id1, id2)
      player1 = Player.find_by(id: id1, isLogin: true)
      player2 = Player.find_by(id: id2, isLogin: true)
      render json: { message: 'Invalid player id or not login' } and return if player1.nil? || player2.nil?

      playing_player = Game.where(isPlaying: true).pluck(:player1, :player2).flatten
      render json: { message: '1-2 player already in game' } and return if playing_player.include?(id1 || id2)
    end

    def create_new_game(id1, id2)
      game = Game.new(player1: id1, player2: id2, winner: 0, isPlaying: true)
      game.save
      log = Log.new(point1: 0, point2: 0, gameid: game.id, isP1LastPoint: true, isP2LastPoint: true)
      log.save
      render json: { players: params[:players].errors } unless game.save && log.save
      render json: { game: fetch_info_game(id1, id2, game.id, 0) }
    end

    def update_point_score1(game_id)
      game = Game.find(game_id)
      curr_log = Log.find_by(isP1LastPoint: true, gameid: game_id)
      Log.create(point1: curr_log.point1 + 10, point2: curr_log.point2, gameid: game_id, isP1LastPoint: true)
      curr_log.update(isP1LastPoint: false)
      render json: { game: fetch_info_game(game.player1, game.player2, game.id, 0) }
    end

    def update_point_score2(game_id)
      game = Game.find(game_id)
      curr_log = Log.find_by(isP2LastPoint: true, gameid: game_id)
      Log.create(point1: curr_log.point1, point2: curr_log.point2 + 10, gameid: game_id, isP2LastPoint: true)
      curr_log.update(isP2LastPoint: false)
      render json: { game: fetch_info_game(game.player1, game.player2, game.id, 0) }
    end

    def valid_id(game_id, player_id)
      render json: { error: 'Invalid game id or ended' } and return if Game.find_by(id: game_id, isPlaying: true).nil?
      render json: { error: 'Invalid player id' } and return if Player.find_by(id: player_id).nil?
    end

    def specify_player(player_id, game_id)
      game = Game.find_by(id: game_id, isPlaying: true)
      return 1 if game.player1 == player_id.to_i
      return 2 if game.player2 == player_id.to_i
    end

    def reset_log_player(stride, choice, game_id, player_id)
      reset_log_player1(stride, choice, game_id) if specify_player(player_id, game_id) == 1; return if performed?

      reset_log_player2(stride, choice, game_id) if specify_player(player_id, game_id) == 2; return if performed?
    end

    def reset_log_player1(stride, choice, game_id)
      curr_log = Log.find_by(isP1LastPoint: true, gameid: game_id)
      render json: { message: 'Step too big' } and return if stride.to_i * 10 > curr_log.point1.to_i

      moved_log = Log.where(point1: curr_log.point1 - stride * 10, gameid: game_id).last if choice == 'undo'
      moved_log = Log.where(point1: curr_log.point1 + stride * 10, gameid: game_id).first if choice == 'redo'
      curr_log.update(isP1LastPoint: false)
      moved_log.update(isP1LastPoint: true)
      render json: { message: "Reset score of player 1 to #{moved_log.point1}" }
    end

    def reset_log_player2(stride, choice, game_id)
      curr_log = Log.find_by(isP2LastPoint: true, gameid: game_id)
      render json: { message: 'Step too big' } and return if stride * 10 > curr_log.point2

      moved_log = Log.where(point2: curr_log.point2 - stride * 10, gameid: game_id).last if choice == 'undo'
      moved_log = Log.where(point2: curr_log.point2 + stride * 10, gameid: game_id).first if choice == 'redo'
      curr_log.update(isP2LastPoint: false)
      moved_log.update(isP2LastPoint: true)
      render json: { message: "Reset score of player 2 to #{moved_log.point2}" }
    end

    def update_result_end(game, log1, log2)
      update_point(game, log1, log2)
      if log1.point1 > log2.point2
        update_count(game.player1, game.player2, game)
      elsif log1.point1 < log2.point2
        update_count(game.player2, game.player1, game)
      end
      game.update(isPlaying: false)
    end

    def update_point(game, log1, log2)
      player1 = Player.find(game.player1)
      player1.update(point: player1.point + log1.point1)
      player2 = Player.find(game.player2)
      player2.update(point: player2.point + log2.point2)
    end

    def update_count(winner_id, loser_id, game)
      game.update(isPlaying: false, winner: winner_id)
      player1 = Player.find(winner_id)
      player2 = Player.find(loser_id)
      player1.update(wincount: player1.wincount + 1)
      player2.update(losecount: player2.losecount + 1)
    end

    def fetch_info_player(player)
      { 'id' => player.id, 'name' => player.name, 'point' => player.point,
        'wins_count' => player.wincount, 'loses_count' => player.losecount }
    end

    def fetch_info_game(id1, id2, game_id, winner)
      player1 = { 'id' => id1 }
      player2 = { 'id' => id2 }
      player1.store('points', Log.find_by(isP1LastPoint: true, gameid: game_id).point1)
      player2.store('points', Log.find_by(isP2LastPoint: true, gameid: game_id).point2)
      players = [player1, player2]
      { 'id' => game_id, 'players' => players, 'winner' => winner }
    end
  end
end
