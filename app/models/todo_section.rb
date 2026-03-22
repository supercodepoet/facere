class TodoSection < ApplicationRecord
  belongs_to :todo_list
  has_many :todo_items, dependent: :destroy

  validates :name, presence: true, length: { maximum: 100 }
  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :active, -> { where(archived: false) }
  default_scope { order(:position) }

  def archive!
    transaction do
      update!(archived: true)
      todo_items.update_all(archived: true)
    end
  end

  def active_item_count
    todo_items.active.size
  end
end
