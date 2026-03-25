class TagsController < ApplicationController
  include ListAuthorization

  before_action :set_todo_list
  before_action :authorize_list_access!, only: %i[index]
  before_action :authorize_editor!, only: %i[create update destroy]
  before_action :set_todo_item

  def index
    @tags = Current.user.tags.order(:name)
    @applied_tag_ids = @todo_item.tag_ids
  end

  def create
    if params.dig(:tag, :id).present?
      toggle_tag_on
    else
      create_new_tag
    end
  end

  def update
    @tag = Current.user.tags.find(params[:id])

    if @tag.update(tag_params)
      load_editor_data
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to todo_list_todo_item_path(@todo_list, @todo_item) }
      end
    else
      @form_tag = @tag
      @form_mode = :edit
      load_editor_data
      respond_to do |format|
        format.turbo_stream { render :update }
        format.html { redirect_to todo_list_todo_item_path(@todo_list, @todo_item), alert: @tag.errors.full_messages.join(", ") }
      end
    end
  end

  def destroy
    if params[:permanent].present?
      destroy_tag_permanently
    else
      remove_tag_from_item
    end
  end

  private

  def toggle_tag_on
    tag = Current.user.tags.find(params.dig(:tag, :id))
    @todo_item.item_tags.find_or_create_by!(tag: tag)
    load_editor_data
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to todo_list_todo_item_path(@todo_list, @todo_item) }
    end
  end

  def create_new_tag
    @tag = Current.user.tags.new(tag_params)

    if @tag.save
      @todo_item.item_tags.find_or_create_by!(tag: @tag)
      load_editor_data
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to todo_list_todo_item_path(@todo_list, @todo_item) }
      end
    else
      @form_tag = @tag
      @form_mode = :create
      load_editor_data
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to todo_list_todo_item_path(@todo_list, @todo_item), alert: @tag.errors.full_messages.join(", ") }
      end
    end
  end

  def remove_tag_from_item
    item_tag = @todo_item.item_tags.find_by!(tag_id: params[:id])
    item_tag.destroy!
    load_editor_data
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to todo_list_todo_item_path(@todo_list, @todo_item) }
    end
  end

  def destroy_tag_permanently
    tag = Current.user.tags.find(params[:id])
    tag.destroy!
    load_editor_data
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to todo_list_todo_item_path(@todo_list, @todo_item) }
    end
  end

  def load_editor_data
    @tags = Current.user.tags.order(:name)
    @applied_tag_ids = @todo_item.reload.tag_ids
  end

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

  def tag_params
    params.require(:tag).permit(:name, :color)
  end
end
