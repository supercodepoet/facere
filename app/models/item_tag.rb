class ItemTag < ApplicationRecord
  belongs_to :todo_item
  belongs_to :tag

  validates :tag_id, uniqueness: { scope: :todo_item_id }
end
