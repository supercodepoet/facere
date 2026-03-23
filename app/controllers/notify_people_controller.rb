class NotifyPeopleController < ApplicationController
  include ListAuthorization

  before_action :set_todo_list
  before_action :authorize_editor!, only: %i[create destroy]
  before_action :set_todo_item

  def create
    user = User.find(params[:user_id] || Current.user.id)

    unless @todo_list.all_members.exists?(id: user.id)
      head :not_found
      return
    end

    @notify_person = @todo_item.notify_people.build(user: user)
    if @notify_person.save
      redirect_back fallback_location: todo_list_todo_item_path(@todo_list, @todo_item)
    else
      redirect_back fallback_location: todo_list_todo_item_path(@todo_list, @todo_item), alert: "Already on notify list"
    end
  end

  def destroy
    @notify_person = @todo_item.notify_people.find(params[:id])
    @notify_person.destroy!
    redirect_back fallback_location: todo_list_todo_item_path(@todo_list, @todo_item)
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
