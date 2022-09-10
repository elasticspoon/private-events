# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Users::SignUp', type: :system do
  before { driven_by(:rack_test) }

  before(:each, browser: true) { driven_by(:selenium) }

  let(:user) { build(:user) }
  let(:existing_user) { create(:user) }

  describe 'sign_up wizard stage 1: Enter Email' do
    before { visit new_user_registration_path }

    it 'shows an error message if email is taken', visit: true do
      fill_in 'user_email', with: existing_user.email
      click_button 'Continue'
      expect(page.has_content?('account associated with the email')).to be true
    end

    it 'goes to step 2 wizard: sign up if email valid', visit: true do
      fill_in_email
      expect(page.has_field?('user_password')).to be true
    end

    # Page Basics
    it 'has a link to sign in', browser: true do
      click_link 'Sign in'
      expect(page.has_current_path?(new_user_session_path)).to be true
    end

    it 'has a link to index' do
      click_link 'Home'
      expect(page.has_current_path?(root_path)).to be true
    end
  end

  describe 'sign_up wizard stage 2: Create Account' do
    before { fill_in_email }

    it 'does not show errors when landing on valid email page (step 2 sign up)' do
      expect(page.has_css?('.field-error')).to be false
    end

    it 'shows errors when bad input on valid email page (step 2 sign up)' do
      click_button 'Create Account'
      expect(page.has_css?('.field-error')).to be true
    end

    it 'brings users back to step 1 if they reload the page' do
      visit new_user_registration_path
      expect(page.has_field?('user_password')).to be false
    end

    it 'brings users back to step 1 if they edit email' do
      click_link 'Edit'
      expect(page.has_field?('user_password')).to be false
    end

    # Page Basics
    it 'has a link to sign in', browser: true do
      click_link 'Log in'
      expect(page.has_current_path?(new_user_session_path)).to be true
    end

    it 'has a link to index' do
      click_link 'Home'
      expect(page.has_current_path?(root_path)).to be true
    end
  end

  describe 'full sign up user story' do
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

  describe 'page is reacheable' do
    it 'sign_up page can be reached from index' do
      visit root_path
      within '#header-nav' do
        click_link('Sign Up')
      end

      expect(page.has_current_path?(new_user_registration_path)).to be true
    end

    it 'sign_up page can be reached from sign_in page', browser: true do
      visit new_user_session_path
      click_on 'Sign up'
      expect(page.has_current_path?(new_user_registration_path)).to be true
    end

    it 'from an event page' do
      visit event_path(create(:event))
      within '#header-nav' do
        click_link('Sign Up')
      end

      expect(page.has_current_path?(new_user_registration_path)).to be true
    end
  end

  ####
  # Methods for sign up process
  ####
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

  def sign_up_user
    fill_in_email
    finish_sign_up
  end
end
