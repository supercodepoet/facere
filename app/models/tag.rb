class Tag < ApplicationRecord
  belongs_to :user
  has_many :item_tags, dependent: :destroy
  has_many :todo_items, through: :item_tags

  validates :name, presence: true, length: { maximum: 50 },
    uniqueness: { scope: :user_id, case_sensitive: false }
end
