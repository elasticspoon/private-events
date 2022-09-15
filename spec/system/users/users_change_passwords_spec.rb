require 'rails_helper'

RSpec.describe 'Users::ChangePasswords', type: :system do
  before { driven_by(:rack_test) }

  before(:each, browser: true) { driven_by(:selenium) }

  let(:user) { create(:user) }

  before { sign_in user }

  describe 'change password function' do
    before { visit users_edit_update_password_path }

    it 'changes user password' do
      fill_in 'user_password', with: 'newpassword'
      fill_in 'user_password_confirmation', with: 'newpassword'
      click_button 'Save'
      expect(user.reload.valid_password?('newpassword')).to be true
    end

    it 'shows error when value is invalid' do
      fill_in 'user_password', with: 'a'
      fill_in 'user_password_confirmation', with: 'a'
      click_button 'Save'
      expect(page.has_css?('.field-error')).to be true
    end
  end

  describe 'valid page' do
  end
end
