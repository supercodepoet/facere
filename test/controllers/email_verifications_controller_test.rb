require "test_helper"

class EmailVerificationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:unverified)
  end

  test "GET email_verification with valid token verifies email" do
    token = @user.generate_token_for(:email_verification)

    get email_verification_path(token: token)

    @user.reload
    assert @user.email_verified?
    assert_nil @user.email_verification_grace_expires_at
    assert_redirected_to root_path
    assert_equal "Email verified successfully!", flash[:notice]
  end

  test "GET email_verification with invalid token redirects with alert" do
    get email_verification_path(token: "invalid-token")

    assert_redirected_to root_path
    assert_equal "Verification link is invalid or has expired.", flash[:alert]
  end

  test "POST email_verification sends verification email" do
    sign_in_as(@user)

    assert_enqueued_emails 1 do
      post email_verification_path
    end

    assert_redirected_to root_path
    assert_equal "Verification email sent. Please check your inbox.", flash[:notice]
  end
end
