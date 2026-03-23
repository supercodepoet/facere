require "test_helper"

class ListInvitationTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      name: "Test User",
      email_address: "invite_owner@example.com",
      password: "Password1!",
      password_confirmation: "Password1!",
      terms_accepted_at: Time.current,
      email_verified_at: Time.current
    )
    @collaborator = User.create!(
      name: "Collaborator",
      email_address: "invite_collab@example.com",
      password: "Password1!",
      password_confirmation: "Password1!",
      terms_accepted_at: Time.current,
      email_verified_at: Time.current
    )
    @list = @user.todo_lists.create!(name: "Test List", color: "purple", template: "blank")
  end

  test "ROLES contains editor and viewer" do
    assert_equal %w[editor viewer], ListInvitation::ROLES
  end

  test "STATUSES contains pending accepted cancelled expired" do
    assert_equal %w[pending accepted cancelled expired], ListInvitation::STATUSES
  end

  test "belongs to todo_list" do
    invitation = @list.list_invitations.create!(
      email: "someone@example.com",
      role: "editor",
      invited_by: @user
    )
    assert_equal @list, invitation.todo_list
  end

  test "belongs to invited_by user" do
    invitation = @list.list_invitations.create!(
      email: "someone@example.com",
      role: "editor",
      invited_by: @user
    )
    assert_equal @user, invitation.invited_by
  end

  test "requires email presence" do
    invitation = @list.list_invitations.build(email: "", role: "editor", invited_by: @user)
    assert_not invitation.valid?
    assert invitation.errors[:email].any?
  end

  test "requires valid email format" do
    invitation = @list.list_invitations.build(email: "not-an-email", role: "editor", invited_by: @user)
    assert_not invitation.valid?
    assert invitation.errors[:email].any?
  end

  test "requires a valid role" do
    invitation = @list.list_invitations.build(email: "someone@example.com", role: "admin", invited_by: @user)
    assert_not invitation.valid?
    assert invitation.errors[:role].any?
  end

  test "requires a valid status" do
    invitation = @list.list_invitations.build(
      email: "someone@example.com",
      role: "editor",
      invited_by: @user,
      status: "unknown"
    )
    assert_not invitation.valid?
    assert invitation.errors[:status].any?
  end

  test "normalizes email by stripping whitespace and downcasing" do
    invitation = @list.list_invitations.create!(
      email: "  SomeOne@Example.COM  ",
      role: "editor",
      invited_by: @user
    )
    assert_equal "someone@example.com", invitation.email
  end

  test "cannot invite the list owner" do
    invitation = @list.list_invitations.build(
      email: @user.email_address,
      role: "editor",
      invited_by: @user
    )
    assert_not invitation.valid?
    assert_includes invitation.errors[:email], "cannot invite the list owner"
  end

  test "no existing collaborator validation" do
    @list.list_collaborators.create!(user: @collaborator, role: "editor")
    invitation = @list.list_invitations.build(
      email: @collaborator.email_address,
      role: "viewer",
      invited_by: @user
    )
    assert_not invitation.valid?
    assert_includes invitation.errors[:email], "is already a collaborator on this list"
  end

  test "set_defaults callback sets expires_at on create" do
    invitation = @list.list_invitations.create!(
      email: "someone@example.com",
      role: "editor",
      invited_by: @user
    )
    assert_not_nil invitation.expires_at
    assert_in_delta 30.days.from_now, invitation.expires_at, 5.seconds
  end

  test "generates_token_for acceptance and finds by token" do
    invitation = @list.list_invitations.create!(
      email: "tokentest@example.com",
      role: "editor",
      invited_by: @user
    )
    token = invitation.generate_token_for(:acceptance)
    assert_not_nil token

    found = ListInvitation.find_by_token_for(:acceptance, token)
    assert_equal invitation, found
  end

  test "active scope returns only pending and not expired invitations" do
    active_invitation = @list.list_invitations.create!(
      email: "active@example.com",
      role: "editor",
      invited_by: @user
    )
    expired_invitation = @list.list_invitations.create!(
      email: "expired@example.com",
      role: "editor",
      invited_by: @user,
      expires_at: 1.day.ago
    )
    accepted_invitation = @list.list_invitations.create!(
      email: "accepted@example.com",
      role: "editor",
      invited_by: @user,
      status: "accepted"
    )

    active = @list.list_invitations.active
    assert_includes active, active_invitation
    assert_not_includes active, expired_invitation
    assert_not_includes active, accepted_invitation
  end

  test "accept! creates a list collaborator and updates status" do
    invitation = @list.list_invitations.create!(
      email: @collaborator.email_address,
      role: "editor",
      invited_by: @user
    )

    assert_difference "ListCollaborator.count", 1 do
      invitation.accept!(@collaborator)
    end

    invitation.reload
    assert_equal "accepted", invitation.status
    assert_not_nil invitation.accepted_at

    collab = @list.list_collaborators.find_by(user: @collaborator)
    assert_not_nil collab
    assert_equal "editor", collab.role
  end

  test "accept! raises when at collaborator limit" do
    TodoList::MAX_COLLABORATORS.times do |i|
      other_user = User.create!(
        name: "User #{i}",
        email_address: "limituser#{i}@example.com",
        password: "Password1!",
        password_confirmation: "Password1!",
        terms_accepted_at: Time.current,
        email_verified_at: Time.current
      )
      @list.list_collaborators.create!(user: other_user, role: "viewer")
    end

    invitation = @list.list_invitations.create!(
      email: @collaborator.email_address,
      role: "editor",
      invited_by: @user
    )

    assert_raises(ActiveRecord::RecordInvalid) do
      invitation.accept!(@collaborator)
    end
  end

  test "expired? returns true when expires_at is in the past" do
    invitation = @list.list_invitations.create!(
      email: "exptest@example.com",
      role: "editor",
      invited_by: @user,
      expires_at: 1.day.ago
    )
    assert invitation.expired?
  end

  test "expired? returns false when expires_at is in the future" do
    invitation = @list.list_invitations.create!(
      email: "exptest2@example.com",
      role: "editor",
      invited_by: @user
    )
    assert_not invitation.expired?
  end

  test "pending? returns true when status is pending and not expired" do
    invitation = @list.list_invitations.create!(
      email: "pendtest@example.com",
      role: "editor",
      invited_by: @user
    )
    assert invitation.pending?
  end

  test "pending? returns false when expired" do
    invitation = @list.list_invitations.create!(
      email: "pendtest2@example.com",
      role: "editor",
      invited_by: @user,
      expires_at: 1.day.ago
    )
    assert_not invitation.pending?
  end

  test "mark_expired! sets status to expired" do
    invitation = @list.list_invitations.create!(
      email: "markexp@example.com",
      role: "editor",
      invited_by: @user
    )
    invitation.mark_expired!
    invitation.reload
    assert_equal "expired", invitation.status
  end
end
