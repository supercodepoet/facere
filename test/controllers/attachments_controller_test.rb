require "test_helper"

class AttachmentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      name: "Attach Test",
      email_address: "attach_ctrl@example.com",
      password: "Password1!",
      password_confirmation: "Password1!",
      terms_accepted_at: Time.current,
      email_verified_at: Time.current
    )
    @list = @user.todo_lists.create!(name: "Test List", color: "purple", template: "blank")
    @item = @list.todo_items.create!(name: "Test Item", position: 0, status: "todo", priority: "none")

    @other_user = User.create!(
      name: "Other User",
      email_address: "other_attach@example.com",
      password: "Password1!",
      password_confirmation: "Password1!",
      terms_accepted_at: Time.current,
      email_verified_at: Time.current
    )
    @other_list = @other_user.todo_lists.create!(name: "Other List", color: "blue", template: "blank")
    @other_item = @other_list.todo_items.create!(name: "Other Item", position: 0, status: "todo", priority: "none")
  end

  test "create requires authentication" do
    post todo_list_todo_item_attachments_url(@list, @item), params: { files: [ fixture_file_upload("test.txt", "text/plain") ] }
    assert_response :redirect
  end

  test "create on other user item returns 404" do
    sign_in_as(@user)
    post todo_list_todo_item_attachments_url(@other_list, @other_item), params: { files: [ fixture_file_upload("test.txt", "text/plain") ] }
    assert_response :not_found
  end

  test "create attaches file" do
    sign_in_as(@user)
    assert_difference -> { @item.files.count }, 1 do
      post todo_list_todo_item_attachments_url(@list, @item), params: { files: [ fixture_file_upload("test.txt", "text/plain") ] }
    end
    assert_response :redirect
  end

  test "destroy requires authentication" do
    @item.files.attach(io: StringIO.new("test"), filename: "test.txt", content_type: "text/plain")
    attachment = @item.files.first
    delete todo_list_todo_item_attachment_url(@list, @item, attachment)
    assert_response :redirect
    assert @item.files.attached?
  end

  test "destroy removes attachment" do
    sign_in_as(@user)
    @item.files.attach(io: StringIO.new("test"), filename: "test.txt", content_type: "text/plain")
    attachment = @item.files.first
    delete todo_list_todo_item_attachment_url(@list, @item, attachment)
    assert_response :redirect
    assert_not @item.reload.files.attached?
  end
end
