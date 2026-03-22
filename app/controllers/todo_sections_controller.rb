class TodoSectionsController < ApplicationController
  layout "app"

  before_action :set_todo_list
  before_action :set_todo_section, only: %i[update destroy archive move]

  def create
    @todo_section = @todo_list.todo_sections.build(todo_section_params)
    @todo_section.position = @todo_list.todo_sections.count

    if @todo_section.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to todo_list_path(@todo_list) }
      end
    else
      respond_to do |format|
        format.turbo_stream { head :unprocessable_entity }
        format.html { redirect_to todo_list_path(@todo_list), alert: @todo_section.errors.full_messages.first }
      end
    end
  end

  def update
    if @todo_section.update(todo_section_params)
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace(@todo_section, partial: "todo_lists/section", locals: { section: @todo_section, todo_list: @todo_list }) }
        format.html { redirect_to todo_list_path(@todo_list) }
      end
    else
      respond_to do |format|
        format.turbo_stream { head :unprocessable_entity }
        format.html { redirect_to todo_list_path(@todo_list), alert: @todo_section.errors.full_messages.first }
      end
    end
  end

  def destroy
    @todo_section.destroy!
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove(@todo_section) }
      format.html { redirect_to todo_list_path(@todo_list), notice: "Section deleted" }
    end
  end

  def archive
    @todo_section.archive!
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove(@todo_section) }
      format.html { redirect_to todo_list_path(@todo_list), notice: "Section archived" }
    end
  end

  def move
    @todo_section.update!(position: params[:target_position].to_i)
    redirect_to todo_list_path(@todo_list)
  end

  def reorder
    TodoSection.transaction do
      params[:sections].each do |section_data|
        @todo_list.todo_sections.where(id: section_data[:id])
          .update_all(position: section_data[:position])
      end
    end

    head :ok
  end

  private

  def set_todo_list
    @todo_list = Current.user.todo_lists.find(params[:todo_list_id])
  end

  def set_todo_section
    @todo_section = @todo_list.todo_sections.find(params[:id])
  end

  def todo_section_params
    params.require(:todo_section).permit(:name, :icon)
  end
end
