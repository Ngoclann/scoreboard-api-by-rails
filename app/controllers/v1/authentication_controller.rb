# frozen_string_literal: true

module V1
  # Authentication
  class AuthenticationController < ApplicationController
    before_action :authorize_request, except: :login
    before_action :fetch_user, only: %i[login logout]
    # POST /auth/login
    def login
      render json: { error: 'Invalid username' }, status: :ok and return if @user.nil?
      render json: { error: 'Invalid password' }, status: :ok and return if params[:password] != @user.password

      token = JsonWebToken.encode(id: @user.id)
      @user.update(token: token)
      time = Time.now + 24.hours.to_i
      @user.update(isLogin: true)
      render json: { token: token, exp: time.strftime('%m-%d-%Y %H:%M') }, status: :ok
    end

    def logout
      render json: { error: 'Invalid username' }, status: :ok and return if @user.nil?
      render json: { error: 'Invalid password' }, status: :ok and return if params[:password] != @user.password

      blacklist = Blacklist.new(token: @user.token)
      blacklist.save

      @user.update(isLogin: false)
      render json: { message: 'Logged out' }, status: :ok
    end

    private

    def fetch_user
      @user = Player.find_by(username: params[:username])
    end
  end
end
