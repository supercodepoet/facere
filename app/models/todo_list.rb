class TodoList < ApplicationRecord
  COLORS = %w[purple blue teal green pink orange].freeze

  ICONS = %w[
    list-check cart-shopping briefcase book
    dumbbell house utensils plane
    graduation-cap heart-pulse music palette
  ].freeze

  TEMPLATES = {
    "blank" => { sections: [], items: {} },
    "project" => {
      sections: [ "Planning", "In Progress", "Review", "Done" ],
      items: {
        "Planning" => [ "Define project scope", "Set budget limits", "Research materials needed" ],
        "In Progress" => [],
        "Review" => [],
        "Done" => []
      }
    },
    "weekly" => {
      sections: [ "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday" ],
      items: {}
    },
    "shopping" => {
      sections: [ "Produce", "Dairy & Eggs", "Meat & Seafood", "Pantry", "Frozen", "Household" ],
      items: {
        "Produce" => [ "Fruits", "Vegetables" ],
        "Dairy & Eggs" => [ "Milk", "Eggs", "Cheese" ],
        "Meat & Seafood" => [],
        "Pantry" => [],
        "Frozen" => [],
        "Household" => []
      }
    }
  }.freeze

  MAX_COLLABORATORS = 25

  belongs_to :user
  has_many :todo_sections, -> { active }
  has_many :all_todo_sections, class_name: "TodoSection", dependent: :destroy
  has_many :todo_items, dependent: :destroy
  has_many :list_collaborators, dependent: :destroy
  has_many :collaborators, through: :list_collaborators, source: :user
  has_many :list_invitations, dependent: :destroy

  validates :name, presence: true, length: { maximum: 100 },
    uniqueness: { scope: :user_id, case_sensitive: false }
  validates :color, presence: true, inclusion: { in: COLORS }
  validates :description, length: { maximum: 500 }
  validates :template, presence: true, inclusion: { in: TEMPLATES.keys }

  scope :recently_updated, -> { order(updated_at: :desc) }

  def apply_template!
    template_data = TEMPLATES[template]
    return if template_data.blank? || template == "blank"

    transaction do
      template_data[:sections].each_with_index do |section_name, index|
        section = todo_sections.create!(name: section_name, position: index)

        (template_data[:items][section_name] || []).each_with_index do |item_name, item_index|
          todo_items.create!(name: item_name, todo_section: section, position: item_index)
        end
      end
    end
  end

  def shift_item_positions(section_id)
    todo_items.where(todo_section_id: section_id).update_all("position = position + 1")
  end

  def reorder_items(items_data)
    TodoItem.transaction do
      items_data.each do |item_data|
        todo_items.where(id: item_data[:id])
          .update_all(position: item_data[:position], todo_section_id: item_data[:section_id].presence)
      end
    end
  end

  def reorder_sections(sections_data)
    TodoSection.transaction do
      sections_data.each do |section_data|
        all_todo_sections.where(id: section_data[:id])
          .update_all(position: section_data[:position])
      end
    end
  end

  def role_for(user)
    return nil unless user
    return "owner" if user_id == user.id

    list_collaborators.find_by(user_id: user.id)&.role
  end

  def all_members
    User.where(id: [ user_id ] + list_collaborators.pluck(:user_id))
  end

  def at_collaborator_limit?
    list_collaborators.count >= MAX_COLLABORATORS
  end

  def completion_percentage
    active_items = todo_items.where(archived: false)
    total = active_items.size
    return 0 if total.zero?

    completed = active_items.where(completed: true).count
    (completed * 100.0 / total).round
  end
end
