require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
  end

  test "GET sign_in renders sign-in form" do
    get sign_in_path
    assert_response :success
  end

  test "POST sign_in with valid credentials creates session and redirects" do
    post sign_in_path, params: { email_address: @user.email_address, password: "Password1!" }

    assert_redirected_to root_path
    assert cookies[:session_id].present?
  end

  test "POST sign_in with invalid password shows security-aware error" do
    post sign_in_path, params: { email_address: @user.email_address, password: "wrong" }

    assert_redirected_to sign_in_path
    assert_equal "Invalid email or password.", flash[:alert]
  end

  test "POST sign_in with non-existent email shows same error" do
    post sign_in_path, params: { email_address: "nobody@example.com", password: "Password1!" }

    assert_redirected_to sign_in_path
    assert_equal "Invalid email or password.", flash[:alert]
  end

  test "POST sign_in increments failed login attempts" do
    assert_equal 0, @user.failed_login_attempts

    post sign_in_path, params: { email_address: @user.email_address, password: "wrong" }

    @user.reload
    assert_equal 1, @user.failed_login_attempts
  end

  test "POST sign_in locks account after 5 failed attempts" do
    5.times do
      post sign_in_path, params: { email_address: @user.email_address, password: "wrong" }
    end

    @user.reload
    assert @user.locked?
    assert_equal 5, @user.failed_login_attempts
    assert_equal 1, @user.lockout_count
  end

  test "POST sign_in shows lockout message when account is locked" do
    @user.update!(locked_until: 10.minutes.from_now)

    post sign_in_path, params: { email_address: @user.email_address, password: "Password1!" }

    assert_redirected_to sign_in_path
    assert_match "Account temporarily locked", flash[:alert]
  end

  test "POST sign_in resets failed attempts on successful login" do
    @user.update!(failed_login_attempts: 3)

    post sign_in_path, params: { email_address: @user.email_address, password: "Password1!" }

    @user.reload
    assert_equal 0, @user.failed_login_attempts
  end

  test "DELETE sign_out destroys session and redirects" do
    sign_in_as(@user)

    delete sign_out_path

    assert_redirected_to sign_in_path
  end
end
