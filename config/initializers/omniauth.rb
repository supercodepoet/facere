Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2,
    Rails.application.credentials.dig(:omniauth, :google, :client_id),
    Rails.application.credentials.dig(:omniauth, :google, :client_secret),
    scope: "email,profile"

  provider :facebook,
    Rails.application.credentials.dig(:omniauth, :facebook, :app_id),
    Rails.application.credentials.dig(:omniauth, :facebook, :app_secret),
    scope: "email,public_profile"

  provider :apple,
    Rails.application.credentials.dig(:omniauth, :apple, :client_id),
    Rails.application.credentials.dig(:omniauth, :apple, :team_id),
    scope: "email name",
    key_id: Rails.application.credentials.dig(:omniauth, :apple, :key_id),
    pem: Rails.application.credentials.dig(:omniauth, :apple, :private_key)
end

OmniAuth.config.allowed_request_methods = [ :post ]
OmniAuth.config.silence_get_warning = true
