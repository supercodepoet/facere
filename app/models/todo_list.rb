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

  belongs_to :user
  has_many :todo_sections, dependent: :destroy
  has_many :todo_items, dependent: :destroy

  validates :name, presence: true, length: { maximum: 100 },
    uniqueness: { scope: :user_id, case_sensitive: false }
  validates :color, presence: true, inclusion: { in: COLORS }
  validates :description, length: { maximum: 500 }
  validates :template, presence: true, inclusion: { in: TEMPLATES.keys }

  scope :recently_updated, -> { order(updated_at: :desc) }

  def apply_template!
    template_data = TEMPLATES[template]
    return if template_data.blank? || template == "blank"

    template_data[:sections].each_with_index do |section_name, index|
      section = todo_sections.create!(name: section_name, position: index)

      (template_data[:items][section_name] || []).each_with_index do |item_name, item_index|
        todo_items.create!(name: item_name, todo_section: section, position: item_index)
      end
    end
  end

  def completion_percentage
    items = todo_items.loaded? ? todo_items : todo_items.to_a
    total = items.size
    return 0 if total.zero?

    completed = items.count(&:completed?)
    (completed * 100.0 / total).round
  end
end
