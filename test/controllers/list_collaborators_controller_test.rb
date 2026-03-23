require "test_helper"

class ListCollaboratorsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = User.create!(
      name: "Owner",
      email_address: "collab_owner@example.com",
      password: "Password1!",
      password_confirmation: "Password1!",
      terms_accepted_at: Time.current,
      email_verified_at: Time.current
    )
    @editor = User.create!(
      name: "Editor",
      email_address: "collab_editor@example.com",
      password: "Password1!",
      password_confirmation: "Password1!",
      terms_accepted_at: Time.current,
      email_verified_at: Time.current
    )
    @viewer = User.create!(
      name: "Viewer",
      email_address: "collab_viewer@example.com",
      password: "Password1!",
      password_confirmation: "Password1!",
      terms_accepted_at: Time.current,
      email_verified_at: Time.current
    )
    @outsider = User.create!(
      name: "Outsider",
      email_address: "collab_outsider@example.com",
      password: "Password1!",
      password_confirmation: "Password1!",
      terms_accepted_at: Time.current,
      email_verified_at: Time.current
    )
    @list = @owner.todo_lists.create!(name: "Shared List", color: "purple", template: "blank")
    @item = @list.todo_items.create!(name: "Test Item", position: 0, status: "todo", priority: "none")
    @editor_collab = @list.list_collaborators.create!(user: @editor, role: "editor")
    @viewer_collab = @list.list_collaborators.create!(user: @viewer, role: "viewer")
  end

  # --- Authentication ---

  test "index requires authentication" do
    get todo_list_collaborators_url(@list)
    assert_response :redirect
  end

  # --- Index Authorization ---

  test "index requires owner role" do
    sign_in_as(@owner)
    get todo_list_collaborators_url(@list)
    assert_response :redirect
  end

  test "index as editor returns 404" do
    sign_in_as(@editor)
    get todo_list_collaborators_url(@list)
    assert_response :not_found
  end

  test "index as viewer returns 404" do
    sign_in_as(@viewer)
    get todo_list_collaborators_url(@list)
    assert_response :not_found
  end

  # --- Update ---

  test "update changes collaborator role" do
    sign_in_as(@owner)
    patch todo_list_collaborator_url(@list, @editor_collab), params: { collaborator: { role: "viewer" } }
    assert_response :redirect
    assert_equal "viewer", @editor_collab.reload.role
  end

  test "update requires owner role" do
    sign_in_as(@editor)
    patch todo_list_collaborator_url(@list, @viewer_collab), params: { collaborator: { role: "editor" } }
    assert_response :not_found
    assert_equal "viewer", @viewer_collab.reload.role
  end

  # --- Destroy ---

  test "destroy removes collaborator" do
    sign_in_as(@owner)
    assert_difference("ListCollaborator.count", -1) do
      delete todo_list_collaborator_url(@list, @editor_collab)
    end
    assert_response :redirect
  end

  test "destroy requires owner role" do
    sign_in_as(@editor)
    assert_no_difference("ListCollaborator.count") do
      delete todo_list_collaborator_url(@list, @viewer_collab)
    end
    assert_response :not_found
  end

  test "destroy preserves comments from removed collaborator" do
    sign_in_as(@owner)
    comment = @item.comments.create!(body: "Editor comment", user: @editor)

    delete todo_list_collaborator_url(@list, @editor_collab)
    assert_response :redirect
    assert Comment.exists?(comment.id), "Comment should be preserved after collaborator removal"
  end

  # --- Leave ---

  test "leave allows collaborator to remove themselves" do
    sign_in_as(@editor)
    assert_difference("ListCollaborator.count", -1) do
      delete todo_list_leave_url(@list)
    end
    assert_response :redirect
  end

  test "leave redirects to lists index" do
    sign_in_as(@editor)
    delete todo_list_leave_url(@list)
    assert_redirected_to todo_lists_url
  end
end
