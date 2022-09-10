require 'rails_helper'

RSpec.describe 'Users', type: :system do
  before { driven_by(:rack_test) }

  before(:each, browser: true) { driven_by(:selenium) }

  describe 'when user is new' do
    let(:user) { build(:user) }
    let(:existing_user) { create(:user) }

    def fill_in_email
      visit new_user_registration_path
      fill_in 'user_email', with: user.email
      click_button 'Continue'
    end

    def finish_sign_up
      fill_in 'user_name', with: user.name
      fill_in 'user_username', with: user.username
      password = user.password
      fill_in 'user_password', with: password
      fill_in 'user_password_confirmation', with: password
      click_button 'Create Account'
    end

    describe 'step 1 wizard: email' do
      before { visit new_user_registration_path }

      it 'has a link to sign in', browser: true do
        visit new_user_registration_path
        click_link 'Sign in'
        expect(page.has_current_path?(new_user_session_path)).to be true
      end

      it 'shows an error message if email is taken', visit: true do
        fill_in 'user_email', with: existing_user.email
        click_button 'Continue'
        expect(page.has_content?('account associated with the email')).to be true
      end

      it 'goes to step 2 wizard: sign up if email valid', visit: true do
        fill_in_email
        expect(page.has_content?('Create an account')).to be true
      end
    end

    describe 'with valid inputs' do
      def sign_up_user
        fill_in_email
        finish_sign_up
      end

      it 'signs up a new user' do
        expect { sign_up_user }.to change(User, :count).by(1)
      end

      it 'redirects to the root path' do
        sign_up_user
        expect(page.has_current_path?(root_path, ignore_query: true)).to be true
      end

      it 'displays a success message' do
        sign_up_user
        expect(page.has_content?('signed up successfully')).to be true
      end

      it 'logs in the user' do
        sign_up_user
        expect(page.has_content?(user.email)).to be true
      end
    end

    it 'does not show errors when landing on valid email page (step 2 sign up)' do
      fill_in_email
      expect(page.has_css?('.field-error')).to be false
    end

    it 'shows errors when bad input on valid email page (step 2 sign up)' do
      fill_in_email
      click_button 'Create Account'
      expect(page.has_css?('.field-error')).to be true
    end
  end
end
