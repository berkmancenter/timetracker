class UsersController < ApplicationController
  before_action :is_admin

  layout 'admin'

  def index
    @users = User.order(:username)
  end

  def sudo
    session["#{@session_user.id}_active_users"] = params[:active_users]&.reject(&:empty?)
    flash[:notice] = "You are now viewing only your own timesheets." if session["#{@session_user.id}_active_users"].blank?

    redirect_to root_url
  end

  def destroy
    u = User.find(params[:id])

    if u != @session_user
      u.destroy
      flash[:notice] = 'User has been removed.'
    else
      flash[:notice] = 'You can\'t remove yourself, you cheeky monkey!'
    end

    redirect_to users_url
  rescue
    flash[:notice] = 'There was a problem removing that user. Que malo!'
    redirect_to users_url
  end

  def destroy_multi
    user_ids = params[:users]&.reject { |uid| uid.to_i == @session_user.id }

    if user_ids&.any?
      User.where(id: user_ids).destroy_all
      flash[:notice] = 'Users have been removed.'
    else
      flash[:notice] = 'No users selected.'
    end

    redirect_to users_url
  end

  def toggle_admin_multi
    user_ids = params[:users]&.reject { |uid| uid.to_i == @session_user.id }

    if user_ids&.any?
      User.where(id: user_ids).each do |user|
        user.toggle!(:superadmin)
      end

      flash[:notice] = 'Users have been toggled.'
    else
      flash[:notice] = 'No users selected.'
    end

    redirect_to users_url
  end
end
