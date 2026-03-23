module ListAuthorization
  extend ActiveSupport::Concern

  included do
    helper_method :current_list_role, :list_owner?, :list_editor?
  end

  private

  def authorize_list_access!
    head :not_found unless current_list_role.present?
  end

  def authorize_editor!
    head :not_found unless list_editor?
  end

  def authorize_owner!
    head :not_found unless list_owner?
  end

  def current_list_role
    @current_list_role ||= @todo_list&.role_for(Current.user)
  end

  def list_owner?
    current_list_role == "owner"
  end

  def list_editor?
    current_list_role.in?(%w[owner editor])
  end
end
