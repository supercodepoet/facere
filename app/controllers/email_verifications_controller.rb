class EmailVerificationsController < ApplicationController
  allow_unauthenticated_access only: :show
  rate_limit to: 5, within: 1.minute, only: :create, with: -> { redirect_to email_verification_path, alert: "Too many requests. Try again later." }

  layout "authentication"

  def show
    user = User.find_by_token_for(:email_verification, params[:token])

    if user
      user.update!(email_verified_at: Time.current, email_verification_grace_expires_at: nil)
      redirect_to root_path, notice: "Email verified successfully!"
    else
      redirect_to root_path, alert: "Verification link is invalid or has expired."
    end
  end

  def create
    EmailVerificationMailer.verification_email(Current.session.user).deliver_later
    redirect_to root_path, notice: "Verification email sent. Please check your inbox."
  end
end
