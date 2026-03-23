module TodoItemScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_todo_list
    before_action :set_todo_item
  end

  private

  def set_todo_list
    @todo_list = Current.user.todo_lists.find(params[:todo_list_id])
  end

  def set_todo_item
    @todo_item = @todo_list.todo_items.find(params[:todo_item_id])
  end
end
