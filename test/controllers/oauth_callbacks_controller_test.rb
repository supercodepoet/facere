require "test_helper"

class OAuthCallbacksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    OmniAuth.config.test_mode = true
  end

  teardown do
    OmniAuth.config.mock_auth[:google_oauth2] = nil
    OmniAuth.config.test_mode = false
  end

  test "existing OAuth identity signs in directly" do
    identity = oauth_identities(:google_one)
    mock_omniauth(:google_oauth2, uid: identity.uid, email: @user.email_address, name: @user.name)

    get "/auth/google_oauth2/callback"

    assert_redirected_to root_path
    assert cookies[:session_id].present?
  end

  test "new user with new email redirects to terms acceptance" do
    mock_omniauth(:google_oauth2, uid: "new-uid", email: "newgoogle@example.com", name: "Google User")

    get "/auth/google_oauth2/callback"

    assert_redirected_to auth_terms_path
  end

  test "existing email without OAuth link redirects to account linking" do
    mock_omniauth(:google_oauth2, uid: "new-uid-999", email: users(:two).email_address, name: users(:two).name)

    get "/auth/google_oauth2/callback"

    assert_redirected_to auth_link_path
  end

  test "terms acceptance page renders with OAuth data" do
    set_oauth_session("google_oauth2", "new-uid", "Google User", "newgoogle@example.com")

    get auth_terms_path

    assert_response :success
  end

  test "accept terms creates user and OAuth identity" do
    set_oauth_session("google_oauth2", "new-uid-terms", "Google User", "newterms@example.com")

    assert_difference [ "User.count", "OAuthIdentity.count" ], 1 do
      post auth_terms_path, params: { terms_accepted: "1" }
    end

    user = User.find_by(email_address: "newterms@example.com")
    assert_not_nil user
    assert_equal "Google User", user.name
    assert user.email_verified?
    assert_not_nil user.terms_accepted_at
    assert_redirected_to root_path
  end

  test "link account page renders with OAuth data" do
    set_oauth_session("google_oauth2", "link-uid", @user.name, @user.email_address)

    get auth_link_path

    assert_response :success
  end

  test "confirm link with correct password creates OAuth identity" do
    set_oauth_session("google_oauth2", "link-uid-confirm", users(:two).name, users(:two).email_address)

    assert_difference "OAuthIdentity.count", 1 do
      post auth_link_path, params: { password: "Password1!" }
    end

    assert_redirected_to root_path
    assert cookies[:session_id].present?
  end

  test "confirm link with wrong password redirects with error" do
    set_oauth_session("google_oauth2", "link-uid-wrong", users(:two).name, users(:two).email_address)

    assert_no_difference "OAuthIdentity.count" do
      post auth_link_path, params: { password: "wrong" }
    end

    assert_redirected_to auth_link_path
    assert_match "Invalid password", flash[:alert]
  end

  test "failure action redirects with error message" do
    get "/auth/failure", params: { message: "access_denied" }

    assert_redirected_to sign_in_path
    assert_match "Authentication failed", flash[:alert]
  end

  private

  def mock_omniauth(provider, uid:, email:, name:)
    OmniAuth.config.mock_auth[provider] = OmniAuth::AuthHash.new(
      provider: provider.to_s,
      uid: uid,
      info: { email: email, name: name }
    )
  end

  def set_oauth_session(provider, uid, name, email)
    # Use a GET to terms or link to set the session via the callback flow
    # Since we can't directly set session in integration tests, we mock the callback
    mock_omniauth(:google_oauth2, uid: uid, email: email, name: name)
    get "/auth/google_oauth2/callback"
  end
end
