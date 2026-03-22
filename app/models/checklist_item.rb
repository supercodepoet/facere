class ChecklistItem < ApplicationRecord
  belongs_to :todo_item

  validates :name, presence: true, length: { maximum: 255 }
  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  default_scope { order(:position) }

  def toggle_completion!
    update!(completed: !completed)
  end
end
