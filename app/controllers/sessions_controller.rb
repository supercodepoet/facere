class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 1.minute, only: :create, with: -> { redirect_to sign_in_path, alert: "Too many attempts. Try again later." }

  layout "authentication", only: %i[ new create ]

  def new
  end

  def create
    user = User.find_by(email_address: params[:email_address])

    if user&.locked?
      redirect_to sign_in_path, alert: "Account temporarily locked. Try again in #{user.lockout_remaining_minutes} minutes."
      return
    end

    if user&.authenticate(params[:password])
      user.reset_failed_login_attempts!

      if user.two_factor_enabled?
        session[:pending_2fa_user_id] = user.id
        redirect_to verify_two_factor_path
        return
      end

      start_new_session_for(user)
      accepted_list = accept_pending_invitation_for(user)
      redirect_to (accepted_list ? todo_list_path(accepted_list) : after_authentication_url)
    else
      user&.increment_failed_login_attempts!
      redirect_to sign_in_path, alert: "Invalid email or password."
    end
  end

  private

  def accept_pending_invitation_for(user)
    token = session.delete(:pending_invitation_token)
    return unless token

    invitation = ListInvitation.find_by_token_for(:acceptance, token)
    return unless invitation&.pending?
    return unless user.email_address == invitation.email

    invitation.accept!(user)
    invitation.todo_list
  rescue ActiveRecord::RecordInvalid
    nil
  end

  public

  def destroy
    terminate_session
    redirect_to sign_in_path, status: :see_other
  end
end
