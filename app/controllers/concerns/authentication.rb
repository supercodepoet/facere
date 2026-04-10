module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :authenticated?
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private

  def authenticated?
    resume_session
  end

  def require_authentication
    resume_session || request_authentication
  end

  def resume_session
    Current.session ||= find_session_by_cookie
    enforce_email_verification if Current.session
    Current.session
  end

  def find_session_by_cookie
    if cookies.signed[:session_id]
      Session.find_by(id: cookies.signed[:session_id])
    end
  end

  def enforce_email_verification
    user = Current.session.user
    return if user.email_verified?
    return if user.within_verification_grace_period?

    redirect_to email_verification_path, alert: "Please verify your email address to continue." and return
  end

  def request_authentication
    session[:return_to_after_authenticating] = request.url
    redirect_to sign_in_path, notice: "Your session has expired. Please sign in again."
  end

  def after_authentication_url
    session.delete(:return_to_after_authenticating) || root_url
  end

  def start_new_session_for(user)
    user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |sess|
      Current.session = sess
      cookies.signed.permanent[:session_id] = {
        value: sess.id,
        httponly: true,
        same_site: :lax,
        secure: Rails.env.production?
      }
    end
  end

  def terminate_session
    Current.session&.destroy
    cookies.delete(:session_id)
  end
end
