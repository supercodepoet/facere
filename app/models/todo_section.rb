class TodoSection < ApplicationRecord
  belongs_to :todo_list
  has_many :todo_items, dependent: :destroy

  validates :name, presence: true, length: { maximum: 100 }
  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  default_scope { order(:position) }
end
