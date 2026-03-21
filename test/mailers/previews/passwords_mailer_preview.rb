# Preview all emails at http://localhost:3000/rails/mailers/passwords_mailer
class PasswordsMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/passwords_mailer/reset
  def reset
    PasswordsMailer.reset(User.first || User.new(name: "Preview User", email_address: "preview@example.com"))
  end
end
