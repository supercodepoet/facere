require "test_helper"

class ListCollaboratorTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      name: "Test User",
      email_address: "collab_owner@example.com",
      password: "Password1!",
      password_confirmation: "Password1!",
      terms_accepted_at: Time.current,
      email_verified_at: Time.current
    )
    @collaborator = User.create!(
      name: "Collaborator",
      email_address: "collab_user@example.com",
      password: "Password1!",
      password_confirmation: "Password1!",
      terms_accepted_at: Time.current,
      email_verified_at: Time.current
    )
    @list = @user.todo_lists.create!(name: "Test List", color: "purple", template: "blank")
  end

  test "ROLES contains editor and viewer" do
    assert_equal %w[editor viewer], ListCollaborator::ROLES
  end

  test "belongs to todo_list" do
    collab = @list.list_collaborators.create!(user: @collaborator, role: "editor")
    assert_equal @list, collab.todo_list
  end

  test "belongs to user" do
    collab = @list.list_collaborators.create!(user: @collaborator, role: "editor")
    assert_equal @collaborator, collab.user
  end

  test "requires a valid role" do
    collab = @list.list_collaborators.build(user: @collaborator, role: "admin")
    assert_not collab.valid?
    assert collab.errors[:role].any?
  end

  test "role must be editor or viewer" do
    %w[editor viewer].each do |role|
      collab = @list.list_collaborators.build(user: @collaborator, role: role)
      assert collab.valid?, "Expected role '#{role}' to be valid"
    end
  end

  test "enforces uniqueness of user_id scoped to todo_list_id" do
    @list.list_collaborators.create!(user: @collaborator, role: "editor")
    duplicate = @list.list_collaborators.build(user: @collaborator, role: "viewer")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "is already a collaborator on this list"
  end

  test "cannot add list owner as collaborator" do
    collab = @list.list_collaborators.build(user: @user, role: "editor")
    assert_not collab.valid?
    assert_includes collab.errors[:user], "cannot be the list owner"
  end

  test "valid collaborator creation with editor role" do
    collab = @list.list_collaborators.build(user: @collaborator, role: "editor")
    assert collab.valid?
    assert collab.save
  end

  test "valid collaborator creation with viewer role" do
    collab = @list.list_collaborators.build(user: @collaborator, role: "viewer")
    assert collab.valid?
    assert collab.save
  end
end
