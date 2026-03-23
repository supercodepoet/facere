class NotifyPeopleController < ApplicationController
  before_action :set_todo_list
  before_action :set_todo_item

  def create
    @notify_person = @todo_item.notify_people.build(user: Current.user)
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
    @todo_list = Current.user.todo_lists.find(params[:todo_list_id])
  end

  def set_todo_item
    @todo_item = @todo_list.todo_items.find(params[:todo_item_id])
  end
end
