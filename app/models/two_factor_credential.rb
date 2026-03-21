class TwoFactorCredential < ApplicationRecord
  belongs_to :user

  encrypts :otp_secret

  validates :otp_secret, presence: true
  validates :user_id, uniqueness: true

  def provisioning_uri(account_name)
    totp = ROTP::TOTP.new(otp_secret, issuer: "Facere")
    totp.provisioning_uri(account_name)
  end

  def verify_code(code)
    return false if code.blank?

    totp = ROTP::TOTP.new(otp_secret, issuer: "Facere")
    totp.verify(code.to_s, drift_behind: 15, drift_ahead: 15).present?
  end
end
