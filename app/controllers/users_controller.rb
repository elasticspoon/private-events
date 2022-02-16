class UsersController < ApplicationController
  before_action :find_user, only: :show
  def show; end

  private

  def find_user
    @user = User.includes(events_created: [:creator]).find(params[:id])
  end
end
