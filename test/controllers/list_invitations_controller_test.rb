require "test_helper"

class ListInvitationsControllerTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  setup do
    @owner = User.create!(
      name: "Owner",
      email_address: "inv_owner@example.com",
      password: "Password1!",
      password_confirmation: "Password1!",
      terms_accepted_at: Time.current,
      email_verified_at: Time.current
    )
    @editor = User.create!(
      name: "Editor",
      email_address: "inv_editor@example.com",
      password: "Password1!",
      password_confirmation: "Password1!",
      terms_accepted_at: Time.current,
      email_verified_at: Time.current
    )
    @viewer = User.create!(
      name: "Viewer",
      email_address: "inv_viewer@example.com",
      password: "Password1!",
      password_confirmation: "Password1!",
      terms_accepted_at: Time.current,
      email_verified_at: Time.current
    )
    @outsider = User.create!(
      name: "Outsider",
      email_address: "inv_outsider@example.com",
      password: "Password1!",
      password_confirmation: "Password1!",
      terms_accepted_at: Time.current,
      email_verified_at: Time.current
    )
    @list = @owner.todo_lists.create!(name: "Shared List", color: "purple", template: "blank")
    @item = @list.todo_items.create!(name: "Test Item", position: 0, status: "todo", priority: "none")
    @list.list_collaborators.create!(user: @editor, role: "editor")
    @list.list_collaborators.create!(user: @viewer, role: "viewer")
  end

  # --- Authentication ---

  test "create requires authentication" do
    assert_no_difference("ListInvitation.count") do
      post todo_list_invitations_url(@list), params: { invitation: { email: "new@example.com" } }
    end
    assert_response :redirect
  end

  # --- Authorization ---

  test "create on other user's list returns 404" do
    sign_in_as(@outsider)
    assert_no_difference("ListInvitation.count") do
      post todo_list_invitations_url(@list), params: { invitation: { email: "someone@example.com" } }
    end
    assert_response :not_found
  end

  test "only owner can create invitations, collaborator gets 404" do
    sign_in_as(@editor)
    assert_no_difference("ListInvitation.count") do
      post todo_list_invitations_url(@list), params: { invitation: { email: "someone@example.com" } }
    end
    assert_response :not_found
  end

  # --- Create ---

  test "create sends invitation email" do
    sign_in_as(@owner)
    assert_emails 1 do
      post todo_list_invitations_url(@list), params: { invitation: { email: "invited@example.com", role: "editor" } }
    end
    assert_response :redirect
    assert ListInvitation.find_by(email: "invited@example.com")
  end

  test "create with invalid email shows error" do
    sign_in_as(@owner)
    assert_no_difference("ListInvitation.count") do
      post todo_list_invitations_url(@list), params: { invitation: { email: "not-an-email" } }
    end
    assert_response :redirect
    follow_redirect!
    assert_match(/email/i, response.body)
  end

  test "create with duplicate pending invitation resends email without new record" do
    sign_in_as(@owner)
    @list.list_invitations.create!(
      email: "duplicate@example.com",
      role: "editor",
      invited_by: @owner,
      status: "pending",
      expires_at: 30.days.from_now
    )

    assert_no_difference("ListInvitation.count") do
      assert_emails 1 do
        post todo_list_invitations_url(@list), params: { invitation: { email: "duplicate@example.com", role: "editor" } }
      end
    end
    assert_response :redirect
  end

  test "create when at collaborator limit shows error" do
    sign_in_as(@owner)

    # Fill up to limit (already have 2 collaborators, add more to reach MAX)
    (TodoList::MAX_COLLABORATORS - 2).times do |i|
      filler = User.create!(
        name: "Filler #{i}",
        email_address: "filler_inv_#{i}@example.com",
        password: "Password1!",
        password_confirmation: "Password1!",
        terms_accepted_at: Time.current,
        email_verified_at: Time.current
      )
      @list.list_collaborators.create!(user: filler, role: "viewer")
    end

    assert_no_difference("ListInvitation.count") do
      post todo_list_invitations_url(@list), params: { invitation: { email: "overflow@example.com", role: "editor" } }
    end
    assert_response :redirect
    follow_redirect!
    assert_match(/maximum/, response.body)
  end

  test "create cannot invite list owner" do
    sign_in_as(@owner)
    assert_no_difference("ListInvitation.count") do
      post todo_list_invitations_url(@list), params: { invitation: { email: @owner.email_address, role: "editor" } }
    end
    assert_response :redirect
  end

  # --- Accept ---

  test "accept with valid token for signed-in user creates collaborator" do
    invitation = @list.list_invitations.create!(
      email: @outsider.email_address,
      role: "editor",
      invited_by: @owner,
      status: "pending",
      expires_at: 30.days.from_now
    )
    token = invitation.generate_token_for(:acceptance)

    sign_in_as(@outsider)
    assert_difference("ListCollaborator.count", 1) do
      get accept_invitation_url(token: token)
    end
    assert_response :redirect
    assert_equal "accepted", invitation.reload.status
  end

  test "accept with invalid token redirects with error" do
    sign_in_as(@outsider)
    get accept_invitation_url(token: "bogus-token")
    assert_response :redirect
    follow_redirect!
    assert_match(/no longer valid/, response.body)
  end

  test "accept with expired token redirects with error" do
    invitation = @list.list_invitations.create!(
      email: @outsider.email_address,
      role: "editor",
      invited_by: @owner,
      status: "pending",
      expires_at: 1.day.ago
    )
    token = invitation.generate_token_for(:acceptance)

    sign_in_as(@outsider)
    get accept_invitation_url(token: token)
    assert_response :redirect
    follow_redirect!
    assert_match(/no longer valid/, response.body)
  end

  test "accept when not signed in stores token in session and redirects to sign-in" do
    invitation = @list.list_invitations.create!(
      email: @outsider.email_address,
      role: "editor",
      invited_by: @owner,
      status: "pending",
      expires_at: 30.days.from_now
    )
    token = invitation.generate_token_for(:acceptance)

    get accept_invitation_url(token: token)
    assert_redirected_to sign_in_url
  end

  # --- Destroy ---

  test "destroy cancels pending invitation" do
    sign_in_as(@owner)
    invitation = @list.list_invitations.create!(
      email: "cancel_me@example.com",
      role: "editor",
      invited_by: @owner,
      status: "pending",
      expires_at: 30.days.from_now
    )

    delete todo_list_invitation_url(@list, invitation)
    assert_response :redirect
    assert_equal "cancelled", invitation.reload.status
  end

  test "destroy on non-pending invitation returns 404" do
    sign_in_as(@owner)
    invitation = @list.list_invitations.create!(
      email: "accepted@example.com",
      role: "editor",
      invited_by: @owner,
      status: "accepted",
      expires_at: 30.days.from_now
    )

    delete todo_list_invitation_url(@list, invitation)
    assert_response :not_found
  end
end
