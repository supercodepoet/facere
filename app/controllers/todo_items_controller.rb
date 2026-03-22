class TodoItemsController < ApplicationController
  layout "app"

  before_action :set_todo_list
  before_action :set_todo_item, only: %i[show update destroy toggle archive move copy]

  def show
    @todo_item = @todo_list.todo_items
      .includes(
        :rich_text_notes,
        :tags,
        :checklist_items,
        :files_attachments,
        :assigned_to,
        :notify_people,
        comments: [ :user, :comment_likes, replies: [ :user, :comment_likes ] ]
      )
      .find(params[:id])
    @sidebar_lists = Current.user.todo_lists.includes(:todo_items).recently_updated
  end

  def create
    @todo_item = @todo_list.todo_items.build(todo_item_params)
    @todo_item.position = 0

    ActiveRecord::Base.transaction do
      @todo_list.shift_item_positions(@todo_item.todo_section_id)
      @todo_item.save!
    end

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to todo_list_path(@todo_list) }
    end
  rescue ActiveRecord::RecordInvalid
    respond_to do |format|
      format.turbo_stream { redirect_to todo_list_path(@todo_list), alert: @todo_item.errors.full_messages.first }
      format.html { redirect_to todo_list_path(@todo_list), alert: @todo_item.errors.full_messages.first }
    end
  end

  def update
    if @todo_item.update(todo_item_params)
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace(@todo_item, partial: @todo_item.completed? ? "todo_lists/todo_item_completed" : "todo_lists/todo_item", locals: { item: @todo_item, todo_list: @todo_list }) }
        format.html { redirect_to todo_list_todo_item_path(@todo_list, @todo_item) }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace(@todo_item, partial: @todo_item.completed? ? "todo_lists/todo_item_completed" : "todo_lists/todo_item", locals: { item: @todo_item, todo_list: @todo_list }), status: :unprocessable_entity }
        format.html { redirect_to todo_list_todo_item_path(@todo_list, @todo_item), alert: @todo_item.errors.full_messages.first }
      end
    end
  end

  def destroy
    @todo_item.destroy!
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove(@todo_item) }
      format.html { redirect_to todo_list_path(@todo_list), notice: "Item deleted" }
    end
  end

  def toggle
    @todo_item.toggle_completion!
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace(@todo_item, partial: @todo_item.completed? ? "todo_lists/todo_item_completed" : "todo_lists/todo_item", locals: { item: @todo_item, todo_list: @todo_list }) }
      format.html { redirect_back fallback_location: todo_list_todo_item_path(@todo_list, @todo_item) }
    end
  end

  def archive
    @todo_item.archive!
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove(@todo_item) }
      format.html { redirect_to todo_list_path(@todo_list), notice: "Item archived" }
    end
  end

  def move
    validate_target_section!
    @todo_item.move_to(section_id: params[:target_section_id].presence, position: params[:target_position].to_i)
    redirect_to todo_list_path(@todo_list)
  end

  def copy
    validate_target_section!
    @todo_item.duplicate_to(section_id: params[:target_section_id].presence, position: params[:target_position].to_i)
    redirect_to todo_list_path(@todo_list), notice: "Item copied"
  end

  def reorder
    items_data = params.require(:items).map do |item|
      item.permit(:id, :position, :section_id)
    end
    @todo_list.reorder_items(items_data)
    head :ok
  end

  private

  def set_todo_list
    @todo_list = Current.user.todo_lists.find(params[:todo_list_id])
  end

  def set_todo_item
    @todo_item = @todo_list.todo_items.find(params[:id])
  end

  def todo_item_params
    permitted = params.require(:todo_item).permit(:name, :status, :due_date, :priority, :todo_section_id, :assigned_to_user_id, :notes, files: [])
    if permitted.key?(:assigned_to_user_id)
      permitted[:assigned_to_user_id] = Current.user.id
    end
    permitted
  end

  def validate_target_section!
    section_id = params[:target_section_id].presence
    return unless section_id

    unless @todo_list.all_todo_sections.exists?(id: section_id)
      raise ActiveRecord::RecordNotFound, "Section not found in this list"
    end
  end
end
