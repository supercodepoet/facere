require "application_system_test_case"

class PasswordResetTest < ApplicationSystemTestCase
  test "visiting forgot password page shows reset form" do
    visit new_password_path

    assert_text "Reset your password"
    assert_text "Enter your email"
    assert_text "Send Reset Link"
    assert_text "Back to Sign In"
  end

  test "forgot password page has link back to sign in" do
    visit new_password_path

    click_link "Back to Sign In"

    assert_current_path sign_in_path
  end
end
