require "test_helper"

class NotifyPeopleControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      name: "Notify Test",
      email_address: "notify_ctrl@example.com",
      password: "Password1!",
      password_confirmation: "Password1!",
      terms_accepted_at: Time.current,
      email_verified_at: Time.current
    )
    @list = @user.todo_lists.create!(name: "Test List", color: "purple", template: "blank")
    @item = @list.todo_items.create!(name: "Test Item", position: 0, status: "todo", priority: "none")

    @other_user = User.create!(
      name: "Other User",
      email_address: "other_notify@example.com",
      password: "Password1!",
      password_confirmation: "Password1!",
      terms_accepted_at: Time.current,
      email_verified_at: Time.current
    )
    @other_list = @other_user.todo_lists.create!(name: "Other List", color: "blue", template: "blank")
    @other_item = @other_list.todo_items.create!(name: "Other Item", position: 0, status: "todo", priority: "none")
  end

  test "create requires authentication" do
    assert_no_difference("NotifyPerson.count") do
      post todo_list_todo_item_notify_people_url(@list, @item)
    end
    assert_response :redirect
  end

  test "create on other user item returns 404" do
    sign_in_as(@user)
    assert_no_difference("NotifyPerson.count") do
      post todo_list_todo_item_notify_people_url(@other_list, @other_item)
    end
    assert_response :not_found
  end

  test "create adds current user to notify list" do
    sign_in_as(@user)
    assert_difference("NotifyPerson.count", 1) do
      post todo_list_todo_item_notify_people_url(@list, @item)
    end
    assert_response :redirect
    assert_equal @user.id, @item.notify_people.last.user_id
  end

  test "create duplicate fails gracefully" do
    NotifyPerson.create!(todo_item: @item, user: @user)
    sign_in_as(@user)
    assert_no_difference("NotifyPerson.count") do
      post todo_list_todo_item_notify_people_url(@list, @item)
    end
    assert_response :redirect
  end

  test "destroy removes from notify list" do
    np = NotifyPerson.create!(todo_item: @item, user: @user)
    sign_in_as(@user)
    assert_difference("NotifyPerson.count", -1) do
      delete todo_list_todo_item_notify_person_url(@list, @item, np)
    end
    assert_response :redirect
  end
end
