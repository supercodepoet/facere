class User < ApplicationRecord
  has_secure_password validations: false

  has_many :sessions, dependent: :destroy
  has_many :oauth_identities, dependent: :destroy
  has_many :todo_lists, dependent: :destroy
  has_many :tags, dependent: :destroy
  has_one :two_factor_credential, dependent: :destroy
  has_many :recovery_codes, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :name, presence: true, length: { maximum: 255 }
  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, confirmation: true, length: { minimum: 8 },
    format: {
      with: /\A(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^a-zA-Z\d]).+\z/,
      message: "must include uppercase, lowercase, digit, and special character"
    },
    if: :password_required?
  validates :terms_accepted_at, presence: true, on: :create

  generates_token_for :email_verification, expires_in: 24.hours do
    email_address
  end

  generates_token_for :password_reset, expires_in: 2.hours do
    password_digest&.last(10)
  end

  # Lockout constants
  MAX_FAILED_ATTEMPTS = 5
  LOCKOUT_DURATION = 15.minutes
  LOCKOUT_ESCALATION_FACTOR = 2

  def initials
    name.split.map(&:first).join.upcase.first(2)
  end

  def email_verified?
    email_verified_at.present?
  end

  def within_verification_grace_period?
    return true if email_verified?
    return false if email_verification_grace_expires_at.nil?

    Time.current < email_verification_grace_expires_at
  end

  def two_factor_enabled?
    two_factor_credential&.enabled?
  end

  def locked?
    locked_until.present? && locked_until > Time.current
  end

  def lockout_remaining_minutes
    return 0 unless locked?
    ((locked_until - Time.current) / 60).ceil
  end

  def increment_failed_login_attempts!
    new_count = failed_login_attempts + 1
    if new_count >= MAX_FAILED_ATTEMPTS
      duration = LOCKOUT_DURATION * (LOCKOUT_ESCALATION_FACTOR**lockout_count)
      update!(
        failed_login_attempts: new_count,
        lockout_count: lockout_count + 1,
        locked_until: duration.from_now
      )
    else
      update!(failed_login_attempts: new_count)
    end
  end

  def reset_failed_login_attempts!
    update!(failed_login_attempts: 0, lockout_count: 0, locked_until: nil)
  end

  private

  def password_required?
    return false if @skip_password_validation
    return false if password.blank? && password_digest.present?
    return false if oauth_identities.any? && password_digest.blank? && password.blank?

    true
  end
end
