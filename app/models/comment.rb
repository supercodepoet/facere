class Comment < ApplicationRecord
  belongs_to :todo_item
  belongs_to :user

  validates :body, presence: true, length: { maximum: 2000 }

  default_scope { order(created_at: :asc) }
end
