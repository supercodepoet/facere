class CommentLikesController < ApplicationController
  before_action :set_todo_list
  before_action :set_todo_item
  before_action :set_comment

  def create
    @like = @comment.comment_likes.build(user: Current.user)
    if @like.save
      redirect_back fallback_location: todo_list_todo_item_path(@todo_list, @todo_item)
    else
      redirect_back fallback_location: todo_list_todo_item_path(@todo_list, @todo_item), alert: "Already liked"
    end
  end

  def destroy
    @like = @comment.comment_likes.find_by!(user: Current.user)
    @like.destroy!
    redirect_back fallback_location: todo_list_todo_item_path(@todo_list, @todo_item)
  end

  private

  def set_todo_list
    @todo_list = Current.user.todo_lists.find(params[:todo_list_id])
  end

  def set_todo_item
    @todo_item = @todo_list.todo_items.find(params[:todo_item_id])
  end

  def set_comment
    @comment = @todo_item.comments.find(params[:comment_id])
  end
end
