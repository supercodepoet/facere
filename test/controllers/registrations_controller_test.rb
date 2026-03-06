require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "GET sign_up renders registration form" do
    get sign_up_path
    assert_response :success
  end

  test "POST sign_up creates user with valid params" do
    assert_difference "User.count", 1 do
      post sign_up_path, params: {
        user: {
          name: "New User",
          email_address: "newuser@example.com",
          password: "Password1!",
          password_confirmation: "Password1!",
          terms_accepted: "1"
        }
      }
    end

    user = User.find_by(email_address: "newuser@example.com")
    assert_not_nil user
    assert_equal "New User", user.name
    assert_not_nil user.email_verification_grace_expires_at
    assert_redirected_to root_path
    assert_equal "Welcome to Facere! Please check your email to verify your account.", flash[:notice]
  end

  test "POST sign_up sets terms_accepted_at when terms checkbox is checked" do
    post sign_up_path, params: {
      user: {
        name: "Terms User",
        email_address: "terms@example.com",
        password: "Password1!",
        password_confirmation: "Password1!",
        terms_accepted: "1"
      }
    }

    user = User.find_by(email_address: "terms@example.com")
    assert_not_nil user.terms_accepted_at
  end

  test "POST sign_up does not set terms_accepted_at when terms not checked" do
    assert_no_difference "User.count" do
      post sign_up_path, params: {
        user: {
          name: "No Terms User",
          email_address: "noterms@example.com",
          password: "Password1!",
          password_confirmation: "Password1!",
          terms_accepted: "0"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "POST sign_up creates session for new user" do
    assert_difference "Session.count", 1 do
      post sign_up_path, params: {
        user: {
          name: "Session User",
          email_address: "session@example.com",
          password: "Password1!",
          password_confirmation: "Password1!",
          terms_accepted: "1"
        }
      }
    end

    assert cookies[:session_id].present?
  end

  test "POST sign_up sends verification email" do
    assert_enqueued_emails 1 do
      post sign_up_path, params: {
        user: {
          name: "Email User",
          email_address: "email@example.com",
          password: "Password1!",
          password_confirmation: "Password1!",
          terms_accepted: "1"
        }
      }
    end
  end

  test "POST sign_up re-renders form with invalid params" do
    assert_no_difference "User.count" do
      post sign_up_path, params: {
        user: {
          name: "",
          email_address: "invalid",
          password: "short",
          password_confirmation: "mismatch",
          terms_accepted: "0"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "POST sign_up rejects duplicate email" do
    existing = users(:one)

    assert_no_difference "User.count" do
      post sign_up_path, params: {
        user: {
          name: "Duplicate User",
          email_address: existing.email_address,
          password: "Password1!",
          password_confirmation: "Password1!",
          terms_accepted: "1"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "POST sign_up rejects mismatched password confirmation" do
    assert_no_difference "User.count" do
      post sign_up_path, params: {
        user: {
          name: "Mismatch User",
          email_address: "mismatch@example.com",
          password: "Password1!",
          password_confirmation: "Different1!",
          terms_accepted: "1"
        }
      }
    end

    assert_response :unprocessable_entity
  end
end
