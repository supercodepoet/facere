require "test_helper"

class TwoFactorCredentialTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @secret = ROTP::Base32.random
    @credential = @user.create_two_factor_credential!(otp_secret: @secret, enabled: true)
  end

  teardown do
    @credential&.destroy
  end

  test "verify_code with valid code returns true" do
    totp = ROTP::TOTP.new(@secret, issuer: "Facere")
    code = totp.now
    assert @credential.verify_code(code)
  end

  test "verify_code with invalid code returns false" do
    assert_not @credential.verify_code("000000")
  end

  test "verify_code with blank code returns false" do
    assert_not @credential.verify_code("")
    assert_not @credential.verify_code(nil)
  end

  test "provisioning_uri returns valid otpauth URI" do
    uri = @credential.provisioning_uri(@user.email_address)
    assert uri.start_with?("otpauth://totp/")
    assert_includes uri, "Facere"
    assert_includes URI.decode_www_form_component(uri), @user.email_address
  end

  test "requires otp_secret" do
    credential = TwoFactorCredential.new(user: users(:two))
    assert_not credential.valid?
    assert_includes credential.errors[:otp_secret], "can't be blank"
  end

  test "requires unique user" do
    credential = TwoFactorCredential.new(user: @user, otp_secret: ROTP::Base32.random)
    assert_not credential.valid?
    assert_includes credential.errors[:user_id], "has already been taken"
  end
end
