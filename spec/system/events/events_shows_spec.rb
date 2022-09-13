require 'rails_helper'

RSpec.describe 'Events::Shows', type: :system do
  before { driven_by(:rack_test) }

  before(:each, browser: true) { driven_by(:selenium) }

  let!(:user) { create(:user) }
  let!(:event) { create(:event, creator: user) }

  describe 'Events Show page' do
    describe 'Page content' do
      before { visit event_path(event) }

      it 'has link to create event' do
        expect(page.has_link?('Create an event')).to be true
      end

      it 'has link to events index' do
        click_link 'Home'
        expect(page.has_current_path?(root_path)).to be true
      end

      it 'has correct event name' do
        expect(page.has_content?(event.name.titleize)).to be true
      end

      it 'has correct event date' do
        expect(page.has_content?(event.date.strftime('%a'))).to be true
        expect(page.has_content?(event.date.strftime('%-d'))).to be true
        expect(page.has_content?(event.date.strftime('%B'))).to be true
      end

      it 'has correct event description' do
        expect(page.has_content?(event.desc)).to be true
      end

      it 'has correct event location' do
        expect(page.has_content?(event.location)).to be true
      end
    end

    context 'when user is not logged in' do
      before { visit event_path(event) }

      it 'has link to log in' do
        within '#header-nav' do
          click_link 'Log In'
        end
        expect(page.has_current_path?(new_user_session_path)).to be true
      end

      it 'has a link to sign up' do
        within '#header-nav' do
          click_link 'Sign Up'
        end
        expect(page.has_current_path?(new_user_registration_path)).to be true
      end
    end

    context 'when user is logged in' do
      before do
        sign_in user
        visit event_path(event)
      end

      it 'has a link to edit user profile', browser: true do
        click_button user.email
        click_link 'Account Settings'
        expect(page.has_current_path?(edit_user_registration_path)).to be true
      end

      it 'has a link to log out', browser: true do
        click_button user.email
        click_button 'Log Out'
        expect(page.find('#header-nav').has_link?('Log In')).to be true
      end

      it 'has link to create event that works' do
        click_link 'Create an event'
        expect(page.has_current_path?(new_event_path)).to be true
      end
    end
  end
end
