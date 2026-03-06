class RegistrationsController < ApplicationController
  allow_unauthenticated_access
  rate_limit to: 10, within: 1.minute, only: :create, with: -> { redirect_to sign_up_path, alert: "Too many attempts. Try again later." }

  layout "authentication"

  def new
    @user = User.new
  end

  def create
    @user = User.new(registration_params)
    @user.email_verification_grace_expires_at = 24.hours.from_now

    if @user.save
      start_new_session_for(@user)
      EmailVerificationMailer.verification_email(@user).deliver_later
      redirect_to root_path, notice: "Welcome to Facere! Please check your email to verify your account."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def registration_params
    params.require(:user).permit(:name, :email_address, :password, :password_confirmation).tap do |p|
      p[:terms_accepted_at] = Time.current if params[:user][:terms_accepted] == "1"
    end
  end
end
