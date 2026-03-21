require "test_helper"

class TwoFactorAuthenticationControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as(@user)
  end

  test "GET two_factor/new renders setup page with QR code" do
    get new_two_factor_path
    assert_response :success
  end

  test "POST two_factor with valid code enables 2FA" do
    # GET new generates a secret and stores it in the session
    get new_two_factor_path
    assert_response :success

    # Extract the secret displayed on the setup page for manual entry
    secret = response.body.match(/([A-Z2-7]{32})/)[1]
    totp = ROTP::TOTP.new(secret, issuer: "Facere")

    assert_difference "TwoFactorCredential.count", 1 do
      post two_factor_path, params: { code: totp.now }
    end

    assert @user.reload.two_factor_enabled?
    assert_response :success
    assert_includes response.body, "Save Your Recovery Codes"
  end

  test "GET two_factor/verify renders code entry form" do
    sign_out
    # Set up pending 2FA
    secret = ROTP::Base32.random
    @user.create_two_factor_credential!(otp_secret: secret, enabled: true)

    post sign_in_path, params: { email_address: @user.email_address, password: "Password1!" }
    assert_redirected_to verify_two_factor_path

    get verify_two_factor_path
    assert_response :success
  end

  test "POST two_factor/verify with valid TOTP completes sign-in" do
    sign_out
    secret = ROTP::Base32.random
    @user.create_two_factor_credential!(otp_secret: secret, enabled: true)

    post sign_in_path, params: { email_address: @user.email_address, password: "Password1!" }
    follow_redirect!

    totp = ROTP::TOTP.new(secret, issuer: "Facere")
    post confirm_two_factor_path, params: { code: totp.now }

    assert_redirected_to root_path
    assert cookies[:session_id].present?
  end

  test "POST two_factor/verify with invalid code shows error" do
    sign_out
    secret = ROTP::Base32.random
    @user.create_two_factor_credential!(otp_secret: secret, enabled: true)

    post sign_in_path, params: { email_address: @user.email_address, password: "Password1!" }

    post confirm_two_factor_path, params: { code: "000000" }

    assert_redirected_to verify_two_factor_path
    assert_match "Invalid verification code", flash[:alert]
  end

  test "POST two_factor/verify with valid recovery code completes sign-in" do
    sign_out
    secret = ROTP::Base32.random
    @user.create_two_factor_credential!(otp_secret: secret, enabled: true)
    codes = RecoveryCode.generate_for(@user)

    post sign_in_path, params: { email_address: @user.email_address, password: "Password1!" }

    post confirm_two_factor_path, params: { code: codes.first }

    assert_redirected_to root_path
  end

  test "GET two_factor/recovery_help renders help page" do
    sign_out

    get two_factor_recovery_help_path
    assert_response :success
  end

  teardown do
    @user.two_factor_credential&.destroy
    @user.recovery_codes.destroy_all
  end
end
