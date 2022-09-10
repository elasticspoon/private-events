require 'rails_helper'

RSpec.describe 'Users::Deletes', type: :system do
  before { sign_in user }

  let(:user) { create(:user) }

  describe 'delete user page' do
    before do
      driven_by(:rack_test)
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

  describe 'page reachable' do
    it 'delete user is reachable from the edit account page' do
      visit edit_user_registration_path
      click_button 'Account'
      click_link 'Close Account'
      expect(page.has_current_path?(users_edit_close_account_path)).to be true
    end
  end
end
