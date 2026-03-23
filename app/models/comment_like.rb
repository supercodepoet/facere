class CommentLike < ApplicationRecord
  belongs_to :comment, counter_cache: :likes_count
  belongs_to :user

  validates :user_id, uniqueness: { scope: :comment_id }
end
