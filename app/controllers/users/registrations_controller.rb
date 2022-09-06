# rubocop:disable Metrics/AbcSize, Metrics/MethodLength
# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  # before_action :configure_sign_up_params, only: [:create]
  before_action :configure_account_update_params, only: [:update]
  prepend_before_action :authenticate_scope!, only: %i[update close_account close_account_action update_password]
  prepend_before_action :set_minimum_password_length, only: %i[update_password]

  # GET /resource/sign_up
  # def new
  #   render 'new', locals: { resource: User.new }
  #   super
  # end
  def close_account; end

  def close_account_action
    valid_params = sanitize_close_account_params
    resource = current_user
    if valid_params[:close] == 'CLOSE' && current_user.valid_password?(valid_params[:password])
      resource.destroy
      Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name)
      set_flash_message! :notice, :destroyed
      yield resource if block_given?
      respond_with_navigational(resource) { redirect_to after_sign_out_path_for(resource_name) }
    else
      redirect_to users_edit_close_account_path, alert: 'Invalid. Please try again.'
    end
  end

  def update_password; end

  def create
    build_resource(sign_up_params)

    resource.save
    yield resource if block_given?
    if resource.persisted?
      if resource.active_for_authentication?
        set_flash_message! :notice, :signed_up
        sign_up(resource_name, resource)
        respond_with resource, location: after_sign_up_path_for(resource)
      else
        set_flash_message! :notice, :"signed_up_but_#{resource.inactive_message}"
        expire_data_after_sign_in!
        respond_with resource, location: after_inactive_sign_up_path_for(resource)
      end
    else
      clean_up_passwords resource
      set_minimum_password_length

      # respond_with resource
      if resource.errors[:email].empty?
        render 'valid_email', locals: { resource: }
      else
        render 'new', locals: { resource: }
      end
    end
  end

  # GET /resource/edit
  # def edit
  #   super
  # end

  # PUT /resource
  # def update
  #   super
  # end

  def update
    self.resource = resource_class.to_adapter.get!(send(:"current_#{resource_name}").to_key)
    prev_unconfirmed_email = resource.unconfirmed_email if resource.respond_to?(:unconfirmed_email)

    resource_updated = update_resource(resource, account_update_params)

    yield resource if block_given?
    if resource_updated
      set_flash_message_for_update(resource, prev_unconfirmed_email)
      bypass_sign_in resource, scope: resource_name if sign_in_after_change_password?
      respond_with resource, location: edit_registration_path(resource)
    else
      clean_up_passwords resource
      set_minimum_password_length
      respond_with resource
    end
  end

  # DELETE /resource
  # def destroy
  #   super
  # end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  # def cancel
  #   super
  # end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_up_params
  #   devise_parameter_sanitizer.permit(:sign_up, keys: [:attribute])
  # end

  # If you have extra params to permit, append them to the sanitizer.
  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update,
                                      keys: %i[email name username password password_confirmation])
  end

  # The path used after sign up.
  # def after_sign_up_path_for(resource)
  #   super(resource)
  # end

  # The path used after sign up for inactive accounts.
  # def after_inactive_sign_up_path_for(resource)
  #   super(resource)
  # end

  private

  def sanitize_params
    params.require(:user).permit(:email)
  end

  def sanitize_close_account_params
    params.permit(:password, :close)
  end

  def build_user
    User.new(sanitize_params)
  end

  def find_user
    @user = User.includes(events_created: [:creator]).find(params[:id])
  end

  def update_resource(resource, params)
    resource.update(params)
  end
end

# rubocop:enable Metrics/AbcSize, Metrics/MethodLength
