require 'rails_helper'
require 'support/shared_examples_for_users_updates'

RSpec.describe 'Users::Updates', type: :system do
  let(:user) { create(:user) }

  include_examples 'users updates' do
    let(:start_path) { edit_user_registration_path }
  end

  describe 'edit user info function' do
    before do
      driven_by(:rack_test)
      sign_in user
      visit edit_user_registration_path
    end

    it 'changes the users name' do
      fill_in 'user_name', with: 'New Name'
      find('#update-user').click
      expect(user.reload.name).to eq('New Name')
    end

    it 'changes the users username' do
      fill_in 'user_username', with: 'New Name'
      find('#update-user').click
      expect(user.reload.username).to eq('New Name')
    end

    it 'changes the users email' do
      fill_in 'user_email', with: 'newemail@mail.com'
      find('#update-email').click
      expect(user.reload.email).to eq('newemail@mail.com')
    end

    it 'shows error when value is invalid' do
      fill_in 'user_username', with: 'a'
      find('#update-user').click
      expect(page.has_css?('.field-error')).to be true
    end
  end
end
