class ItemAssigneesController < ApplicationController
  include ListAuthorization

  before_action :set_todo_list
  before_action :set_todo_item
  before_action :authorize_editor!

  def create
    user = User.find(params[:user_id])

    unless @todo_list.all_members.exists?(id: user.id)
      head :not_found
      return
    end

    @assignee = @todo_item.item_assignees.create!(user: user)

    respond_to do |format|
      format.turbo_stream { redirect_to todo_list_todo_item_path(@todo_list, @todo_item) }
      format.html { redirect_to todo_list_todo_item_path(@todo_list, @todo_item) }
    end
  rescue ActiveRecord::RecordInvalid
    redirect_to todo_list_todo_item_path(@todo_list, @todo_item), alert: "User is already assigned."
  end

  def destroy
    assignee = @todo_item.item_assignees.find(params[:id])
    assignee.destroy!

    respond_to do |format|
      format.turbo_stream { redirect_to todo_list_todo_item_path(@todo_list, @todo_item) }
      format.html { redirect_to todo_list_todo_item_path(@todo_list, @todo_item) }
    end
  end

  private

  def set_todo_list
    @todo_list = TodoList.where(id: params[:todo_list_id])
      .where(id: Current.user.todo_lists.select(:id))
      .or(TodoList.where(id: params[:todo_list_id])
        .where(id: Current.user.shared_lists.select(:id)))
      .first!
  end

  def set_todo_item
    @todo_item = @todo_list.todo_items.find(params[:todo_item_id])
  end
end
