class Comment < ApplicationRecord
  belongs_to :todo_item
  belongs_to :user
  belongs_to :parent, class_name: "Comment", optional: true

  has_many :replies, class_name: "Comment", foreign_key: :parent_id, dependent: :destroy
  has_many :comment_likes, dependent: :destroy

  validates :body, presence: true, length: { maximum: 2000 }
  validate :nesting_depth_limit
  validate :parent_belongs_to_same_item

  scope :top_level, -> { where(parent_id: nil) }
  scope :ordered, -> { order(created_at: :asc) }
  default_scope { order(created_at: :asc) }

  def edited?
    edited_at.present?
  end

  def liked_by?(user)
    comment_likes.exists?(user: user)
  end

  private

  def nesting_depth_limit
    return if parent.nil?

    errors.add(:parent, "replies can only be one level deep") if parent.parent_id.present?
  end

  def parent_belongs_to_same_item
    return if parent.nil?

    errors.add(:parent, "must belong to the same item") if parent.todo_item_id != todo_item_id
  end
end
