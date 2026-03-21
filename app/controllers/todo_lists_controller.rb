class TodoListsController < ApplicationController
  layout "app"

  before_action :set_todo_list, only: %i[show edit update destroy]

  def index
    @todo_lists = Current.user.todo_lists.recently_updated
  end

  def show
    @sidebar_lists = Current.user.todo_lists.recently_updated
    @sections = @todo_list.todo_sections.includes(:todo_items)
  end

  def new
    @todo_list = Current.user.todo_lists.build(color: TodoList::COLORS.first, template: "blank")
  end

  def create
    @todo_list = Current.user.todo_lists.build(todo_list_params)

    if @todo_list.save
      @todo_list.apply_template!
      redirect_to @todo_list, notice: "List created successfully! Time to get things done"
    else
      flash.now[:alert] = "Oops! Please fix the issues below before creating your list"
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @todo_list.update(todo_list_params.except(:template))
      redirect_to @todo_list, notice: "List updated successfully"
    else
      flash.now[:alert] = "Oops! Please fix the issues below"
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @todo_list.destroy!
    redirect_to todo_lists_path, notice: "List deleted successfully"
  end

  private

  def set_todo_list
    @todo_list = Current.user.todo_lists.find(params[:id])
  end

  def todo_list_params
    params.require(:todo_list).permit(:name, :color, :icon, :description, :template)
  end
end
