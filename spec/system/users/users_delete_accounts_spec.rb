require 'rails_helper'
require 'support/shared_examples_for_users_updates'

RSpec.describe 'Users::Deletes', type: :system do
  let(:user) { create(:user) }

  include_examples 'users updates' do
    let(:start_path) { users_edit_close_account_path }
  end

  describe 'delete user page' do
    before do
      driven_by(:rack_test)
      sign_in user
      visit users_edit_close_account_path
    end

    it 'deletes the user' do
      fill_in 'close', with: 'CLOSE'
      fill_in 'password', with: user.password
      click_button 'Close Account'
      expect(User.count).to eq(0)
    end

    it 'shows error when value is invalid' do
      fill_in 'close', with: 'a'
      fill_in 'password', with: 'a'
      click_button 'Close Account'
      expect(page.has_content?('Invalid')).to be true
    end
  end
end
