class Tag < ApplicationRecord
  belongs_to :user
  has_many :item_tags, dependent: :destroy
  has_many :todo_items, through: :item_tags

  validates :name, presence: true, length: { maximum: 50 },
    uniqueness: { scope: :user_id, case_sensitive: false }
  validates :color, format: { with: /\A#[0-9a-fA-F]{6}\z/, message: "must be a 6-digit hex color (e.g., #FF5733)" },
    allow_blank: true
end
