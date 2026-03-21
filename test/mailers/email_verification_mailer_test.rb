require "test_helper"

class EmailVerificationMailerTest < ActionMailer::TestCase
  setup do
    @user = users(:unverified)
  end

  test "verification_email sends to user email" do
    mail = EmailVerificationMailer.verification_email(@user)

    assert_equal "Verify your Facere account", mail.subject
    assert_equal [ @user.email_address ], mail.to
  end

  test "verification_email includes verification link in html body" do
    mail = EmailVerificationMailer.verification_email(@user)

    assert_match "Verify Email Address", mail.html_part.body.to_s
    assert_match "email_verification", mail.html_part.body.to_s
  end

  test "verification_email includes verification link in text body" do
    mail = EmailVerificationMailer.verification_email(@user)

    assert_match "email_verification", mail.text_part.body.to_s
  end

  test "verification_email includes user name" do
    mail = EmailVerificationMailer.verification_email(@user)

    assert_match @user.name, mail.html_part.body.to_s
    assert_match @user.name, mail.text_part.body.to_s
  end
end
