class TagsController < ApplicationController
  before_action :set_todo_list
  before_action :set_todo_item

  def create
    tag = Current.user.tags.find_or_create_by!(name: tag_params[:name]) do |t|
      t.color = tag_params[:color]
    end

    @todo_item.item_tags.find_or_create_by!(tag: tag)
    redirect_to todo_list_todo_item_path(@todo_list, @todo_item)
  rescue ActiveRecord::RecordInvalid => e
    redirect_to todo_list_todo_item_path(@todo_list, @todo_item), alert: e.message
  end

  def destroy
    item_tag = @todo_item.item_tags.find_by!(tag_id: params[:id])
    item_tag.destroy!
    redirect_to todo_list_todo_item_path(@todo_list, @todo_item)
  end

  private

  def set_todo_list
    @todo_list = Current.user.todo_lists.find(params[:todo_list_id])
  end

  def set_todo_item
    @todo_item = @todo_list.todo_items.find(params[:todo_item_id])
  end

  def tag_params
    params.require(:tag).permit(:name, :color)
  end
end
