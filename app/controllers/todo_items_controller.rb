class TodoItemsController < ApplicationController
  layout "app"

  before_action :set_todo_list
  before_action :set_todo_item, only: %i[show update destroy toggle archive move copy]

  def show
    @sidebar_lists = Current.user.todo_lists.includes(:todo_items).recently_updated
    @sections = @todo_list.todo_sections.active.includes(todo_items: :assigned_to)
  end

  def create
    @todo_item = @todo_list.todo_items.build(todo_item_params)
    @todo_item.position = 0

    if @todo_item.save
      shift_positions(@todo_item.todo_section_id)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to todo_list_path(@todo_list) }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("inline-item-input", partial: "todo_lists/inline_item_input", locals: { todo_list: @todo_list, section: @todo_item.todo_section, error: @todo_item.errors.full_messages.first }) }
        format.html { redirect_to todo_list_path(@todo_list), alert: @todo_item.errors.full_messages.first }
      end
    end
  end

  def update
    @todo_item.update(todo_item_params)

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace(@todo_item, partial: "todo_lists/todo_item", locals: { item: @todo_item, todo_list: @todo_list }) }
      format.html do
        if @todo_item.errors.any?
          redirect_to todo_list_todo_item_path(@todo_list, @todo_item), alert: @todo_item.errors.full_messages.first
        else
          redirect_to todo_list_todo_item_path(@todo_list, @todo_item)
        end
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
      format.html { redirect_to todo_list_path(@todo_list) }
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
    @todo_item.update!(
      todo_section_id: params[:target_section_id].presence,
      position: params[:target_position].to_i
    )
    redirect_to todo_list_path(@todo_list)
  end

  def copy
    duplicate = @todo_item.dup
    duplicate.assign_attributes(
      todo_section_id: params[:target_section_id].presence,
      position: params[:target_position].to_i
    )
    duplicate.save!
    redirect_to todo_list_path(@todo_list), notice: "Item copied"
  end

  def reorder
    TodoItem.transaction do
      params[:items].each do |item_data|
        @todo_list.todo_items.where(id: item_data[:id])
          .update_all(position: item_data[:position], todo_section_id: item_data[:section_id].presence)
      end
    end

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
    params.require(:todo_item).permit(:name, :status, :due_date, :priority, :todo_section_id, :assigned_to_user_id)
  end

  def shift_positions(section_id)
    scope = @todo_list.todo_items.where(todo_section_id: section_id)
    scope.update_all("position = position + 1")
  end
end
