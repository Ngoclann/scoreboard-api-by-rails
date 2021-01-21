# frozen_string_literal: true

# Application
class ApplicationController < ActionController::API
  def not_found
    render json: { error: 'not_found' }
  end

  def authorize_request
    header = request.headers['Authorization']
    header = header.split(' ').last if header
    render json: { errors: 'Token is revoked' } unless Blacklist.find_by(token: header).nil?
    begin
      @current_user = Player.find(JsonWebToken.decode(header)[:id])
    rescue ActiveRecord::RecordNotFound => e
      render json: { errors: 'Record not found' }, status: :ok
    rescue JWT::DecodeError => e
      render json: { errors: 'Decode Error' }, status: :ok
    end
  end

  def admin_only
    render json: { message: 'Only admin can access this action' } and return unless @current_user.isAdmin
  end
end
