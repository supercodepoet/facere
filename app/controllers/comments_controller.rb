class CommentsController < ApplicationController
  include ListAuthorization

  before_action :set_todo_list
  before_action :authorize_list_access!, only: :create
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

  def update
    @comment = @todo_item.comments.find(params[:id])
    return head(:not_found) unless @comment.user == Current.user

    @comment.edited_at = Time.current
    if @comment.update(comment_params)
      redirect_to todo_list_todo_item_path(@todo_list, @todo_item)
    else
      redirect_to todo_list_todo_item_path(@todo_list, @todo_item), alert: @comment.errors.full_messages.first
    end
  end

  def destroy
    @comment = @todo_item.comments.find(params[:id])
    return head(:not_found) unless @comment.user == Current.user

    @comment.destroy!
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

  def comment_params
    params.require(:comment).permit(:body, :parent_id)
  end
end
