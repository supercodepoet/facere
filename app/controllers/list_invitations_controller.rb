class ListInvitationsController < ApplicationController
  include ListAuthorization

  before_action :set_todo_list, only: %i[create destroy]
  before_action :authorize_owner!, only: %i[create destroy]

  allow_unauthenticated_access only: :accept

  def create
    email = invitation_params[:email]&.strip&.downcase

    if @todo_list.at_collaborator_limit?
      redirect_to todo_list_path(@todo_list), alert: "This list has reached the maximum of #{TodoList::MAX_COLLABORATORS} collaborators."
      return
    end

    # If there's already a pending invitation for this email, resend it
    existing = @todo_list.list_invitations.active.find_by(email: email)
    if existing
      CollaborationMailer.invitation_email(existing).deliver_now
      redirect_to todo_list_path(@todo_list), notice: "Invitation resent to #{email}"
      return
    end

    @invitation = @todo_list.list_invitations.build(invitation_params)
    @invitation.invited_by = Current.user

    if @invitation.save
      CollaborationMailer.invitation_email(@invitation).deliver_now
      redirect_to todo_list_path(@todo_list), notice: "Invitation sent to #{@invitation.email}"
    else
      redirect_to todo_list_path(@todo_list), alert: @invitation.errors.full_messages.first
    end
  end

  def accept
    invitation = ListInvitation.find_by_token_for(:acceptance, params[:token])

    if invitation.nil? || !invitation.pending?
      redirect_to root_path, alert: "This invitation is no longer valid."
      return
    end

    unless authenticated?
      session[:pending_invitation_token] = params[:token]
      redirect_to sign_in_path, notice: "Please sign in to accept the invitation."
      return
    end

    invitation.accept!(Current.user)
    redirect_to todo_list_path(invitation.todo_list), notice: "You now have access to \"#{invitation.todo_list.name}\"!"
  rescue ActiveRecord::RecordInvalid => e
    redirect_to root_path, alert: e.record.errors.full_messages.first
  end

  def destroy
    invitation = @todo_list.list_invitations.find_by!(id: params[:id], status: "pending")
    invitation.update!(status: "cancelled")
    redirect_to todo_list_path(@todo_list), notice: "Invitation cancelled."
  end

  private

  def set_todo_list
    @todo_list = Current.user.todo_lists.find(params[:todo_list_id])
  end

  def invitation_params
    permitted = params.require(:invitation).permit(:email)
    role = params.dig(:invitation, :role)
    permitted[:role] = role if ListInvitation::ROLES.include?(role)
    permitted
  end
end
