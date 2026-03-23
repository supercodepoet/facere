require "test_helper"

class TodoListCollaborationTest < ActiveSupport::TestCase
  setup do
    @owner = User.create!(
      name: "Owner",
      email_address: "list_collab_owner@example.com",
      password: "Password1!",
      password_confirmation: "Password1!",
      terms_accepted_at: Time.current
    )
    @collaborator = User.create!(
      name: "Collaborator",
      email_address: "list_collab_user@example.com",
      password: "Password1!",
      password_confirmation: "Password1!",
      terms_accepted_at: Time.current
    )
    @outsider = User.create!(
      name: "Outsider",
      email_address: "list_collab_outsider@example.com",
      password: "Password1!",
      password_confirmation: "Password1!",
      terms_accepted_at: Time.current
    )
    @list = @owner.todo_lists.create!(name: "Test List", color: "purple", template: "blank")
  end

  test "role_for returns owner for list owner" do
    assert_equal "owner", @list.role_for(@owner)
  end

  test "role_for returns editor for editor collaborator" do
    @list.list_collaborators.create!(user: @collaborator, role: "editor")
    assert_equal "editor", @list.role_for(@collaborator)
  end

  test "role_for returns viewer for viewer collaborator" do
    @list.list_collaborators.create!(user: @collaborator, role: "viewer")
    assert_equal "viewer", @list.role_for(@collaborator)
  end

  test "role_for returns nil for outsider" do
    assert_nil @list.role_for(@outsider)
  end

  test "role_for returns nil for nil user" do
    assert_nil @list.role_for(nil)
  end

  test "all_members includes owner and collaborators" do
    @list.list_collaborators.create!(user: @collaborator, role: "editor")
    members = @list.all_members
    assert_includes members, @owner
    assert_includes members, @collaborator
    assert_not_includes members, @outsider
  end

  test "at_collaborator_limit? returns false when under limit" do
    assert_not @list.at_collaborator_limit?
  end

  test "at_collaborator_limit? returns true when at limit" do
    TodoList::MAX_COLLABORATORS.times do |i|
      user = User.create!(
        name: "User #{i}",
        email_address: "list_collab_limit_#{i}@example.com",
        password: "Password1!",
        password_confirmation: "Password1!",
        terms_accepted_at: Time.current
      )
      @list.list_collaborators.create!(user: user, role: "editor")
    end
    assert @list.at_collaborator_limit?
  end

  test "shared_lists returns lists user collaborates on" do
    @list.list_collaborators.create!(user: @collaborator, role: "editor")
    assert_includes @collaborator.shared_lists, @list
    assert_not_includes @outsider.shared_lists, @list
  end

  test "destroying list cascades to collaborators and invitations" do
    @list.list_collaborators.create!(user: @collaborator, role: "editor")
    @list.list_invitations.create!(
      invited_by: @owner,
      email: "someone@example.com",
      role: "editor"
    )
    assert_difference([ "ListCollaborator.count", "ListInvitation.count" ], -1) do
      @list.destroy!
    end
  end
end
