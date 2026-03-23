class ListCollaborator < ApplicationRecord
  ROLES = %w[editor viewer].freeze

  belongs_to :todo_list
  belongs_to :user

  validates :role, presence: true, inclusion: { in: ROLES }
  validates :user_id, uniqueness: { scope: :todo_list_id, message: "is already a collaborator on this list" }
  validate :user_is_not_list_owner

  private

  def user_is_not_list_owner
    return if todo_list.blank? || user.blank?

    errors.add(:user, "cannot be the list owner") if todo_list.user_id == user_id
  end
end
