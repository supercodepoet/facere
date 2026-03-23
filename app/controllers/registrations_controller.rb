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
      accept_pending_invitation_for(@user)
      redirect_to after_registration_url, notice: "Welcome to Facere! Please check your email to verify your account."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def accept_pending_invitation_for(user)
    token = session.delete(:pending_invitation_token)
    return unless token

    invitation = ListInvitation.find_by_token_for(:acceptance, token)
    return unless invitation&.pending?

    invitation.accept!(user)
  rescue ActiveRecord::RecordInvalid
    # Silently skip if acceptance fails (e.g., already a collaborator)
  end

  def after_registration_url
    if session[:pending_invitation_token].blank?
      root_path
    else
      root_path # invitation already accepted above
    end
  end

  def registration_params
    params.require(:user).permit(:name, :email_address, :password, :password_confirmation).tap do |p|
      p[:terms_accepted_at] = Time.current if params[:user][:terms_accepted] == "1"
    end
  end
end
