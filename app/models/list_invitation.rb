class ListInvitation < ApplicationRecord
  ROLES = %w[editor viewer].freeze
  STATUSES = %w[pending accepted cancelled expired].freeze

  belongs_to :todo_list
  belongs_to :invited_by, class_name: "User"

  normalizes :email, with: ->(e) { e.strip.downcase }

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :role, presence: true, inclusion: { in: ROLES }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :expires_at, presence: true
  validate :cannot_invite_list_owner
  validate :no_existing_collaborator

  generates_token_for :acceptance, expires_in: 30.days do
    status
  end

  scope :active, -> { where(status: "pending").where("expires_at > ?", Time.current) }

  before_validation :set_defaults, on: :create

  def accept!(user)
    transaction do
      update!(status: "accepted", accepted_at: Time.current)
      todo_list.list_collaborators.create!(user: user, role: role)
    end
  end

  def expired?
    expires_at < Time.current
  end

  def pending?
    status == "pending" && !expired?
  end

  def mark_expired!
    update!(status: "expired")
  end

  private

  def set_defaults
    self.expires_at ||= 30.days.from_now
  end

  def cannot_invite_list_owner
    return if todo_list.blank? || email.blank?

    errors.add(:email, "cannot invite the list owner") if todo_list.user.email_address == email
  end

  def no_existing_collaborator
    return if todo_list.blank? || email.blank?

    existing_user = User.find_by(email_address: email)
    return unless existing_user

    if todo_list.list_collaborators.exists?(user: existing_user)
      errors.add(:email, "is already a collaborator on this list")
    end
  end
end
