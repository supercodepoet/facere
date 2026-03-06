class RecoveryCode < ApplicationRecord
  belongs_to :user

  validates :code_digest, presence: true

  def used?
    used_at.present?
  end

  def consume!
    update!(used_at: Time.current)
  end

  def self.generate_for(user, count: 10)
    user.recovery_codes.destroy_all

    codes = count.times.map { SecureRandom.alphanumeric(10).downcase }

    codes.each do |code|
      user.recovery_codes.create!(code_digest: BCrypt::Password.create(code))
    end

    codes
  end

  def matches?(plaintext_code)
    BCrypt::Password.new(code_digest) == plaintext_code
  end
end
