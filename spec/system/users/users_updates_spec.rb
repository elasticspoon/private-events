require 'rails_helper'

RSpec.describe 'Users::Updates', type: :system do
  before { driven_by(:rack_test) }

  before(:each, browser: true) { driven_by(:selenium) }

  let(:user) { create(:user) }

  before { sign_in user }

  describe 'edit user info page', browser: true do
    before { visit edit_user_registration_path }

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

  describe 'change password page', browser: true do
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

  describe 'page reachable', browser: true do
    it 'edit user is reachable from the index page' do
      visit root_path
      click_button user.email
      click_link 'Account Settings'
      expect(page.has_current_path?(edit_user_registration_path)).to be true
    end

    it 'edit user is reachable from the event page' do
      visit event_path(create(:event))
      click_button user.email
      click_link 'Account Settings'
      expect(page.has_current_path?(edit_user_registration_path)).to be true
    end

    it 'edit password is reachable from edit user' do
      visit edit_user_registration_path
      click_button 'Account'
      click_link 'Password'
      expect(page.has_current_path?(users_edit_update_password_path)).to be true
    end
  end

  ##############################
  ### Helper Methods
  ##############################
end
