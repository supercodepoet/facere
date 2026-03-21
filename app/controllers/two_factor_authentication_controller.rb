class TwoFactorAuthenticationController < ApplicationController
  allow_unauthenticated_access only: %i[ verify confirm recovery_help ]
  layout "authentication"

  def new
    secret = ROTP::Base32.random
    session[:pending_otp_secret] = secret
    totp = ROTP::TOTP.new(secret, issuer: "Facere")
    @provisioning_uri = totp.provisioning_uri(Current.user.email_address)
    @qr_code = RQRCode::QRCode.new(@provisioning_uri).as_svg(
      module_size: 4,
      standalone: true,
      use_path: true
    )
    @secret = secret
  end

  def create
    secret = session.delete(:pending_otp_secret)
    return redirect_to new_two_factor_path, alert: "Setup session expired. Please try again." unless secret

    totp = ROTP::TOTP.new(secret, issuer: "Facere")

    if totp.verify(params[:code].to_s, drift_behind: 15, drift_ahead: 15).present?
      credential = Current.user.create_two_factor_credential!(otp_secret: secret, enabled: true)
      @recovery_codes = RecoveryCode.generate_for(Current.user)
      render :recovery_codes
    else
      session[:pending_otp_secret] = secret
      redirect_to new_two_factor_path, alert: "Invalid verification code. Please try again."
    end
  end

  def destroy
    user = Current.user

    unless user.authenticate(params[:password])
      redirect_to new_two_factor_path, alert: "Invalid password." and return
    end

    unless user.two_factor_credential&.verify_code(params[:code])
      redirect_to new_two_factor_path, alert: "Invalid verification code." and return
    end

    user.two_factor_credential.destroy!
    user.recovery_codes.destroy_all
    redirect_to root_path, notice: "Two-factor authentication has been disabled."
  end

  def verify
    redirect_to sign_in_path unless session[:pending_2fa_user_id]
  end

  def confirm
    user = User.find_by(id: session[:pending_2fa_user_id])
    return redirect_to sign_in_path unless user

    if user.two_factor_credential&.verify_code(params[:code])
      session.delete(:pending_2fa_user_id)
      start_new_session_for(user)
      redirect_to after_authentication_url
    elsif try_recovery_code(user, params[:code])
      session.delete(:pending_2fa_user_id)
      start_new_session_for(user)
      redirect_to after_authentication_url, notice: "Signed in with recovery code. Consider generating new codes."
    else
      redirect_to verify_two_factor_path, alert: "Invalid verification code."
    end
  end

  def recovery_codes
    @recovery_codes = RecoveryCode.generate_for(Current.user)
  end

  def recovery_help
  end

  private

  def try_recovery_code(user, code)
    return false if code.blank?

    user.recovery_codes.where(used_at: nil).find_each do |rc|
      if rc.matches?(code.to_s.strip)
        rc.consume!
        return true
      end
    end

    false
  end
end
