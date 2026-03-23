class NotifyPerson < ApplicationRecord
  belongs_to :todo_item
  belongs_to :user

  validates :user_id, uniqueness: { scope: :todo_item_id }
end
