class OAuthCallbacksController < ApplicationController
  allow_unauthenticated_access
  layout "authentication"

  def create
    auth = request.env["omniauth.auth"]
    identity = OAuthIdentity.find_by(provider: auth.provider, uid: auth.uid)

    if identity
      if identity.user.two_factor_enabled?
        session[:pending_2fa_user_id] = identity.user.id
        redirect_to verify_two_factor_path
        return
      end
      start_new_session_for(identity.user)
      redirect_to after_authentication_url
    elsif (user = User.find_by(email_address: auth.info.email))
      session[:oauth_data] = extract_oauth_data(auth)
      redirect_to auth_link_path
    else
      session[:oauth_data] = extract_oauth_data(auth)
      redirect_to auth_terms_path
    end
  end

  def failure
    redirect_to sign_in_path, alert: "Authentication failed: #{params[:message].to_s.humanize}. Please try again."
  end

  def terms_acceptance
    @oauth_data = session[:oauth_data]
    redirect_to sign_in_path, alert: "OAuth session expired. Please try again." unless @oauth_data
  end

  def accept_terms
    oauth_data = session.delete(:oauth_data)
    return redirect_to sign_in_path, alert: "OAuth session expired. Please try again." unless oauth_data

    unless params[:terms_accepted] == "1"
      session[:oauth_data] = oauth_data
      return redirect_to auth_terms_path, alert: "You must accept the Terms of Service and Privacy Policy."
    end

    user = User.new(
      name: oauth_data["name"],
      email_address: oauth_data["email"],
      terms_accepted_at: Time.current,
      email_verified_at: Time.current
    )
    user.instance_variable_set(:@skip_password_validation, true)

    if user.save
      user.oauth_identities.create!(provider: oauth_data["provider"], uid: oauth_data["uid"])
      start_new_session_for(user)
      redirect_to root_path, notice: "Welcome to Facere!"
    else
      session[:oauth_data] = oauth_data
      redirect_to auth_terms_path, alert: user.errors.full_messages.to_sentence
    end
  end

  def link_account
    @oauth_data = session[:oauth_data]
    redirect_to sign_in_path, alert: "OAuth session expired. Please try again." unless @oauth_data
  end

  def confirm_link
    oauth_data = session.delete(:oauth_data)
    return redirect_to sign_in_path, alert: "OAuth session expired. Please try again." unless oauth_data

    user = User.find_by(email_address: oauth_data["email"])

    if user&.authenticate(params[:password])
      user.oauth_identities.create!(provider: oauth_data["provider"], uid: oauth_data["uid"])
      start_new_session_for(user)
      redirect_to root_path, notice: "Account linked successfully!"
    else
      session[:oauth_data] = oauth_data
      redirect_to auth_link_path, alert: "Invalid password. Please try again."
    end
  end

  private

  def extract_oauth_data(auth)
    {
      "provider" => auth.provider,
      "uid" => auth.uid,
      "name" => auth.info.name,
      "email" => auth.info.email
    }
  end
end
