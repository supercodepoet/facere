require "test_helper"

class PasswordsMailerTest < ActionMailer::TestCase
  setup do
    @user = users(:one)
  end

  test "reset email sends to user email" do
    mail = PasswordsMailer.reset(@user)

    assert_equal "Reset your Facere password", mail.subject
    assert_equal [ @user.email_address ], mail.to
  end

  test "reset email includes reset link in html body" do
    mail = PasswordsMailer.reset(@user)

    assert_match "Reset Password", mail.html_part.body.to_s
    assert_match "edit", mail.html_part.body.to_s
  end

  test "reset email includes reset link in text body" do
    mail = PasswordsMailer.reset(@user)

    assert_match "passwords", mail.text_part.body.to_s
  end

  test "reset email includes 2-hour expiry notice" do
    mail = PasswordsMailer.reset(@user)

    assert_match "2 hours", mail.html_part.body.to_s
    assert_match "2 hours", mail.text_part.body.to_s
  end

  test "reset email includes user name" do
    mail = PasswordsMailer.reset(@user)

    assert_match @user.name, mail.html_part.body.to_s
    assert_match @user.name, mail.text_part.body.to_s
  end
end
