require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "valid user with all required attributes" do
    user = User.new(
      name: "Test User",
      email_address: "test@example.com",
      password: "Password1!",
      password_confirmation: "Password1!",
      terms_accepted_at: Time.current
    )
    assert user.valid?
  end

  test "requires name" do
    user = User.new(name: nil)
    assert_not user.valid?
    assert_includes user.errors[:name], "can't be blank"
  end

  test "name cannot exceed 255 characters" do
    user = User.new(name: "a" * 256)
    assert_not user.valid?
    assert user.errors[:name].any? { |e| e.include?("too long") }
  end

  test "requires email address" do
    user = User.new(email_address: nil)
    assert_not user.valid?
    assert_includes user.errors[:email_address], "can't be blank"
  end

  test "requires unique email address" do
    existing = users(:one)
    user = User.new(
      name: "Duplicate",
      email_address: existing.email_address,
      password: "Password1!",
      password_confirmation: "Password1!",
      terms_accepted_at: Time.current
    )
    assert_not user.valid?
    assert_includes user.errors[:email_address], "has already been taken"
  end

  test "rejects invalid email format" do
    user = User.new(email_address: "not-an-email")
    assert_not user.valid?
    assert user.errors[:email_address].any? { |e| e.include?("invalid") }
  end

  test "normalizes email address" do
    user = User.new(email_address: "  Test@Example.COM  ")
    assert_equal "test@example.com", user.email_address
  end

  test "requires password of at least 8 characters" do
    user = User.new(password: "Short1!")
    assert_not user.valid?
    assert user.errors[:password].any? { |e| e.include?("too short") }
  end

  test "requires uppercase letter in password" do
    user = User.new(password: "password1!")
    assert_not user.valid?
    assert user.errors[:password].any? { |e| e.include?("must include") }
  end

  test "requires lowercase letter in password" do
    user = User.new(password: "PASSWORD1!")
    assert_not user.valid?
    assert user.errors[:password].any? { |e| e.include?("must include") }
  end

  test "requires digit in password" do
    user = User.new(password: "Password!!")
    assert_not user.valid?
    assert user.errors[:password].any? { |e| e.include?("must include") }
  end

  test "requires special character in password" do
    user = User.new(password: "Password11")
    assert_not user.valid?
    assert user.errors[:password].any? { |e| e.include?("must include") }
  end

  test "requires terms acceptance on create" do
    user = User.new(
      name: "Test User",
      email_address: "newuser@example.com",
      password: "Password1!",
      password_confirmation: "Password1!",
      terms_accepted_at: nil
    )
    assert_not user.valid?
    assert_includes user.errors[:terms_accepted_at], "can't be blank"
  end

  test "does not require password when password_digest exists and no new password given" do
    user = users(:one)
    user.name = "Updated Name"
    assert user.valid?
  end

  test "email_verified? returns true when email_verified_at is set" do
    user = users(:one)
    assert user.email_verified?
  end

  test "email_verified? returns false when email_verified_at is nil" do
    user = users(:two)
    assert_not user.email_verified?
  end

  test "within_verification_grace_period? returns true when email is verified" do
    user = users(:one)
    assert user.within_verification_grace_period?
  end

  test "within_verification_grace_period? returns true during grace period" do
    user = users(:unverified)
    assert user.within_verification_grace_period?
  end

  test "within_verification_grace_period? returns false after grace period expires" do
    user = users(:unverified)
    user.email_verification_grace_expires_at = 1.hour.ago
    assert_not user.within_verification_grace_period?
  end

  test "within_verification_grace_period? returns false when no grace period set" do
    user = users(:two)
    assert_not user.within_verification_grace_period?
  end

  test "generates email verification token" do
    user = users(:one)
    token = user.generate_token_for(:email_verification)
    assert_not_nil token
    found = User.find_by_token_for(:email_verification, token)
    assert_equal user, found
  end

  test "generates password reset token" do
    user = users(:one)
    token = user.generate_token_for(:password_reset)
    assert_not_nil token
    found = User.find_by_token_for(:password_reset, token)
    assert_equal user, found
  end

  test "two_factor_enabled? returns false without credential" do
    user = users(:one)
    assert_not user.two_factor_enabled?
  end

  test "destroys dependent sessions" do
    user = users(:one)
    user.sessions.create!
    assert_difference "Session.count", -user.sessions.count do
      user.destroy
    end
  end

  test "has lockout constants" do
    assert_equal 5, User::MAX_FAILED_ATTEMPTS
    assert_equal 15.minutes, User::LOCKOUT_DURATION
    assert_equal 2, User::LOCKOUT_ESCALATION_FACTOR
  end
end
