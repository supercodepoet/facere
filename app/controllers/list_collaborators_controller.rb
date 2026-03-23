class ListCollaboratorsController < ApplicationController
  include ListAuthorization

  before_action :set_todo_list
  before_action :authorize_owner!, only: %i[index update destroy]
  before_action :authorize_list_access!, only: %i[leave]

  def index
    @collaborators = @todo_list.list_collaborators.includes(:user)
    @pending_invitations = @todo_list.list_invitations.active

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to todo_list_path(@todo_list) }
    end
  end

  def update
    collaborator = @todo_list.list_collaborators.find(params[:id])
    if collaborator.update(collaborator_params)
      redirect_to todo_list_path(@todo_list), notice: "Role updated to #{collaborator.role}."
    else
      redirect_to todo_list_path(@todo_list), alert: collaborator.errors.full_messages.first
    end
  end

  def destroy
    collaborator = @todo_list.list_collaborators.find(params[:id])
    collaborator.destroy!
    redirect_to todo_list_path(@todo_list), notice: "#{collaborator.user.name} removed from the list."
  end

  def leave
    collaborator = @todo_list.list_collaborators.find_by!(user: Current.user)
    collaborator.destroy!
    redirect_to todo_lists_path, notice: "You left \"#{@todo_list.name}\"."
  end

  private

  def set_todo_list
    @todo_list = TodoList.where(id: params[:todo_list_id])
      .where(id: Current.user.todo_lists.select(:id))
      .or(TodoList.where(id: params[:todo_list_id])
        .where(id: Current.user.shared_lists.select(:id)))
      .first!
  end

  def collaborator_params
    role = params.dig(:collaborator, :role)
    { role: role }.select { |_, v| ListCollaborator::ROLES.include?(v) }
  end
end
