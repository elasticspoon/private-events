class UsersController < ApplicationController
  before_action :find_user, only: :show
  def show; end

  def sign_up
    render 'sign_up', locals: { resource: User.new }
  end

  def check_email
    if User.find_by(email: sanitize_params[:email])
      resource = build_user
      resource.errors.add(:email, 'taken')
      render 'sign_up', locals: { resource: }
    else
      render 'sign_up_full', locals: { resource: build_user }
    end
  end

  private

  def sanitize_params
    params.require(:user).permit(:email)
  end

  def build_user
    User.new(sanitize_params)
  end

  def find_user
    @user = User.includes(events_created: [:creator]).find(params[:id])
  end
end
