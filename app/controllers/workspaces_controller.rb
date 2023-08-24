class WorkspacesController < ApplicationController
  before_action :set_workspace, except: %i[index upsert delete]
  before_action :is_admin

  layout 'admin'

  def index
    workspaces = Workspace.user_workspaces(@session_user)
    workspaces = workspaces.select(:uuid, :name) unless @session_user.superadmin

    render json: workspaces, status: :ok
  end

  def show
    render json: @workspace, status: :ok
  end

  def upsert
    if workspace_params[:id]
      workspace = Workspace.find(workspace_params['id'])
      workspace.assign_attributes(workspace_params)
    else
      workspace = Workspace.new(workspace_params)
    end

    if workspace.save
      render json: { workspace: workspace }, status: :ok
    else
      render json: { message: workspace.errors.full_messages.join(', ') }, status: :bad_request
    end
  end

  def delete
    workspaces_ids = params[:workspaces]

    if workspaces_ids&.any?
      Workspace.where(id: workspaces_ids).destroy_all

      render json: { message: 'ok' }, status: :ok
    else
      render json: { message: 'No workspaces selected.' }, status: :bad_request
    end
  end

  private

  def set_workspace
    @workspace = Workspace.find(params[:id])
  end

  def workspace_params
    params.require(:workspace).permit(:id, :name)
  end
end
