class ItemAssignee < ApplicationRecord
  belongs_to :todo_item
  belongs_to :user

  validates :user_id, uniqueness: { scope: :todo_item_id, message: "is already assigned to this item" }
end
