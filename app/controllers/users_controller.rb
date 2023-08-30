class UsersController < ApplicationController
  before_action :is_superadmin?, except: %i[current_user]

  layout 'admin'

  def index
    users = User.order(:username)

    render json: users, status: :ok
  end

  def delete
    user_ids = params[:users]&.reject { |uid| uid.to_i == @session_user.id }

    if user_ids&.any?
      User.where(id: user_ids).destroy_all

      render json: { message: 'ok' }, status: :ok
    else
      render json: { message: 'No users selected.' }, status: :bad_request
    end
  end

  def toggle_admin
    user_ids = params[:users]&.reject { |uid| uid.to_i == @session_user.id }

    if user_ids&.any?
      User.where(id: user_ids).each do |user|
        user.toggle!(:superadmin)
      end

      render json: { message: 'ok' }, status: :ok
    else
      render json: { message: 'No users selected.' }, status: :bad_request
    end
  end

  def sudo
    session["#{@session_user.id}_active_users"] = params[:users]

    render json: { message: 'ok' }, status: :ok
  end

  def current_user
    render json: {
      username: helpers.clean_username(@session_user.username),
      user_id: @session_user.id,
      is_superadmin: @session_user.superadmin,
      sudo_users: get_sudo_users_usernames
    }, status: :ok
  end

  private

  def get_sudo_users
    unless session["#{@session_user.id}_active_users"].blank?
      session["#{@session_user.id}_active_users"].map { |uid| User.where(id: uid).first }.compact
    else
      []
    end
  end

  def get_sudo_users_usernames
    get_sudo_users.map { |u| User.where(id: u).first&.username }.compact
  end
end
