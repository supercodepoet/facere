require "test_helper"

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
  end

  test "GET passwords/new renders reset request form" do
    get new_password_path
    assert_response :success
  end

  test "POST passwords with existing email sends reset email" do
    assert_enqueued_emails 1 do
      post passwords_path, params: { email_address: @user.email_address }
    end

    assert_redirected_to sign_in_path
    assert_match "password reset instructions", flash[:notice]
  end

  test "POST passwords with non-existing email shows same confirmation" do
    assert_enqueued_emails 0 do
      post passwords_path, params: { email_address: "nobody@example.com" }
    end

    assert_redirected_to sign_in_path
    assert_match "password reset instructions", flash[:notice]
  end

  test "GET passwords/:token/edit with valid token renders form" do
    get edit_password_path(@user.password_reset_token)
    assert_response :success
  end

  test "GET passwords/:token/edit with invalid token redirects with error" do
    get edit_password_path("invalid-token")
    assert_redirected_to new_password_path
    assert_match "invalid or has expired", flash[:alert]
  end

  test "PATCH passwords/:token updates password and redirects" do
    token = @user.password_reset_token

    assert_changes -> { @user.reload.password_digest } do
      patch password_path(token), params: { password: "NewPassword1!", password_confirmation: "NewPassword1!" }
    end

    assert_redirected_to sign_in_path
    assert_match "Password has been reset", flash[:notice]
  end

  test "PATCH passwords/:token with mismatched passwords shows error" do
    token = @user.password_reset_token

    assert_no_changes -> { @user.reload.password_digest } do
      patch password_path(token), params: { password: "NewPassword1!", password_confirmation: "Different1!" }
    end

    assert_redirected_to edit_password_path(token)
    assert_match "Passwords did not match", flash[:alert]
  end

  test "PATCH passwords/:token destroys all existing sessions" do
    @user.sessions.create!(user_agent: "Test", ip_address: "127.0.0.1")
    token = @user.password_reset_token

    assert_difference -> { @user.sessions.count }, -@user.sessions.count do
      patch password_path(token), params: { password: "NewPassword1!", password_confirmation: "NewPassword1!" }
    end
  end
end
