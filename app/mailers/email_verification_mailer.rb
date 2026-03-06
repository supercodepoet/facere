class EmailVerificationMailer < ApplicationMailer
  def verification_email(user)
    @user = user
    @token = user.generate_token_for(:email_verification)
    @verification_url = email_verification_url(token: @token)

    mail subject: "Verify your Facere account", to: user.email_address
  end
end
