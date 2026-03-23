class AttachmentsController < ApplicationController
  include ListAuthorization

  before_action :set_todo_list
  before_action :authorize_editor!, only: %i[create destroy]
  before_action :set_todo_item

  def create
    if params[:files].present?
      params[:files].each do |file|
        @todo_item.files.attach(file)
      end
    end
    redirect_to todo_list_todo_item_path(@todo_list, @todo_item)
  end

  def destroy
    attachment = @todo_item.files.find(params[:id])
    attachment.purge
    redirect_to todo_list_todo_item_path(@todo_list, @todo_item)
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
