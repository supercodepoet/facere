class ChecklistItemsController < ApplicationController
  before_action :set_todo_list
  before_action :set_todo_item
  before_action :set_checklist_item, only: %i[update destroy toggle]

  def create
    @checklist_item = @todo_item.checklist_items.build(checklist_item_params)
    @checklist_item.position = @todo_item.checklist_items.count

    if @checklist_item.save
      redirect_to todo_list_todo_item_path(@todo_list, @todo_item)
    else
      redirect_to todo_list_todo_item_path(@todo_list, @todo_item), alert: @checklist_item.errors.full_messages.first
    end
  end

  def update
    if @checklist_item.update(checklist_item_params)
      redirect_to todo_list_todo_item_path(@todo_list, @todo_item)
    else
      redirect_to todo_list_todo_item_path(@todo_list, @todo_item), alert: @checklist_item.errors.full_messages.first
    end
  end

  def toggle
    @checklist_item.toggle_completion!
    redirect_to todo_list_todo_item_path(@todo_list, @todo_item)
  end

  def destroy
    @checklist_item.destroy!
    redirect_to todo_list_todo_item_path(@todo_list, @todo_item)
  end

  private

  def set_todo_list
    @todo_list = Current.user.todo_lists.find(params[:todo_list_id])
  end

  def set_todo_item
    @todo_item = @todo_list.todo_items.find(params[:todo_item_id])
  end

  def set_checklist_item
    @checklist_item = @todo_item.checklist_items.find(params[:id])
  end

  def checklist_item_params
    params.require(:checklist_item).permit(:name)
  end
end
