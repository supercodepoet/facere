class TodoListsController < ApplicationController
  include ListAuthorization

  layout "app"

  before_action :set_todo_list, only: %i[show edit update destroy]
  before_action :authorize_list_access!, only: %i[show]
  before_action :authorize_owner!, only: %i[edit update destroy]

  def index
    @todo_lists = Current.user.todo_lists.includes(:todo_items).positioned
    @shared_lists = Current.user.shared_lists.includes(:user, :list_collaborators, :todo_items).recently_updated
  end

  def reorder
    lists_data = params.require(:lists).map { |l| l.permit(:id, :position) }

    TodoList.transaction do
      lists_data.each do |list_data|
        Current.user.todo_lists.where(id: list_data[:id])
          .update_all(position: list_data[:position])
      end
    end

    head :ok
  end

  def show
    @sidebar_lists = Current.user.todo_lists.includes(:todo_items).positioned
    @shared_sidebar_lists = Current.user.shared_lists.includes(:user, :todo_items).recently_updated
    @sections = @todo_list.todo_sections.active.includes(todo_items: { item_assignees: :user })
    @unsectioned_items = @todo_list.todo_items.active.includes(item_assignees: :user).where(todo_section_id: nil)
  end

  def new
    @todo_list = Current.user.todo_lists.build(color: TodoList::COLORS.first, template: "blank")
  end

  def create
    @todo_list = Current.user.todo_lists.build(todo_list_params)
    @todo_list.position = Current.user.todo_lists.maximum(:position).to_i + 1

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
    @todo_list = TodoList.where(id: params[:id])
      .where(id: Current.user.todo_lists.select(:id))
      .or(TodoList.where(id: params[:id])
        .where(id: Current.user.shared_lists.select(:id)))
      .first!
  end

  def todo_list_params
    params.require(:todo_list).permit(:name, :color, :icon, :description, :template)
  end
end
