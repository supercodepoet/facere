class CommentsController < ApplicationController
  before_action :set_todo_list
  before_action :set_todo_item

  def create
    @comment = @todo_item.comments.build(comment_params)
    @comment.user = Current.user

    if @comment.save
      redirect_to todo_list_todo_item_path(@todo_list, @todo_item)
    else
      redirect_to todo_list_todo_item_path(@todo_list, @todo_item), alert: @comment.errors.full_messages.first
    end
  end

  def destroy
    @comment = @todo_item.comments.find(params[:id])
    @comment.destroy!
    redirect_to todo_list_todo_item_path(@todo_list, @todo_item)
  end

  private

  def set_todo_list
    @todo_list = Current.user.todo_lists.find(params[:todo_list_id])
  end

  def set_todo_item
    @todo_item = @todo_list.todo_items.find(params[:todo_item_id])
  end

  def comment_params
    params.require(:comment).permit(:body)
  end
end
