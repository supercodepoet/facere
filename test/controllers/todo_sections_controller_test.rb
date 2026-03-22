require "test_helper"

class TodoSectionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      name: "Test User",
      email_address: "sections_ctrl@example.com",
      password: "Password1!",
      password_confirmation: "Password1!",
      terms_accepted_at: Time.current,
      email_verified_at: Time.current
    )
    @todo_list = @user.todo_lists.create!(name: "Test List", color: "purple", template: "blank")
    @todo_section = @todo_list.todo_sections.create!(name: "Planning", position: 0)

    @other_user = User.create!(
      name: "Other User",
      email_address: "other_sections@example.com",
      password: "Password1!",
      password_confirmation: "Password1!",
      terms_accepted_at: Time.current,
      email_verified_at: Time.current
    )
    @other_list = @other_user.todo_lists.create!(name: "Other List", color: "blue", template: "blank")
    @other_section = @other_list.todo_sections.create!(name: "Other Section", position: 0)
  end

  # --- Authentication (all actions) ---

  test "create requires authentication" do
    assert_no_difference("TodoSection.count") do
      post todo_list_todo_sections_url(@todo_list), params: { todo_section: { name: "Sneaky" } }
    end
    assert_response :redirect
  end

  test "update requires authentication" do
    patch todo_list_todo_section_url(@todo_list, @todo_section), params: { todo_section: { name: "Hacked" } }
    assert_response :redirect
    assert_equal "Planning", @todo_section.reload.name
  end

  test "destroy requires authentication" do
    assert_no_difference("TodoSection.count") do
      delete todo_list_todo_section_url(@todo_list, @todo_section)
    end
    assert_response :redirect
  end

  test "archive requires authentication" do
    patch archive_todo_list_todo_section_url(@todo_list, @todo_section)
    assert_response :redirect
    assert_equal false, @todo_section.reload.archived
  end

  # --- Authorization (other user's sections return 404) ---

  test "update other user section returns 404" do
    sign_in_as(@user)
    patch todo_list_todo_section_url(@other_list, @other_section), params: { todo_section: { name: "Hacked" } }
    assert_response :not_found
    assert_equal "Other Section", @other_section.reload.name
  end

  test "destroy other user section returns 404" do
    sign_in_as(@user)
    assert_no_difference("TodoSection.count") do
      delete todo_list_todo_section_url(@other_list, @other_section)
    end
    assert_response :not_found
  end

  test "archive other user section returns 404" do
    sign_in_as(@user)
    patch archive_todo_list_todo_section_url(@other_list, @other_section)
    assert_response :not_found
    assert_equal false, @other_section.reload.archived
  end

  # --- Create ---

  test "create creates section with name and icon" do
    sign_in_as(@user)
    assert_difference("TodoSection.count", 1) do
      post todo_list_todo_sections_url(@todo_list), params: { todo_section: { name: "Design", icon: "fa-palette" } }, as: :turbo_stream
    end

    new_section = TodoSection.find_by(name: "Design")
    assert_not_nil new_section
    assert_equal @todo_list.id, new_section.todo_list_id
    assert_equal "fa-palette", new_section.icon
  end
end
