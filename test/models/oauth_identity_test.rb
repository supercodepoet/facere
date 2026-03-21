require "test_helper"

class OAuthIdentityTest < ActiveSupport::TestCase
  test "valid with required attributes" do
    identity = OAuthIdentity.new(user: users(:one), provider: "google_oauth2", uid: "unique-123")
    assert identity.valid?
  end

  test "requires provider" do
    identity = OAuthIdentity.new(provider: nil)
    assert_not identity.valid?
    assert_includes identity.errors[:provider], "can't be blank"
  end

  test "requires provider in allowed list" do
    identity = OAuthIdentity.new(provider: "twitter")
    assert_not identity.valid?
    assert identity.errors[:provider].any? { |e| e.include?("not included") }
  end

  test "allows all supported providers" do
    %w[google_oauth2 facebook apple].each do |provider|
      identity = OAuthIdentity.new(user: users(:two), provider: provider, uid: "uid-#{provider}")
      assert identity.valid?, "Expected #{provider} to be valid"
    end
  end

  test "requires uid" do
    identity = OAuthIdentity.new(uid: nil)
    assert_not identity.valid?
    assert_includes identity.errors[:uid], "can't be blank"
  end

  test "requires uid uniqueness scoped to provider" do
    existing = oauth_identities(:google_one)
    identity = OAuthIdentity.new(user: users(:two), provider: existing.provider, uid: existing.uid)
    assert_not identity.valid?
    assert_includes identity.errors[:uid], "has already been taken"
  end

  test "allows same uid for different providers" do
    existing = oauth_identities(:google_one)
    identity = OAuthIdentity.new(user: users(:two), provider: "facebook", uid: existing.uid)
    assert identity.valid?
  end

  test "belongs to user" do
    identity = oauth_identities(:google_one)
    assert_equal users(:one), identity.user
  end
end
