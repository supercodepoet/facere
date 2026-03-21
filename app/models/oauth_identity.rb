class OAuthIdentity < ApplicationRecord
  ALLOWED_PROVIDERS = %w[google_oauth2 facebook apple].freeze

  belongs_to :user

  validates :provider, presence: true, inclusion: { in: ALLOWED_PROVIDERS }
  validates :uid, presence: true, uniqueness: { scope: :provider }
end
