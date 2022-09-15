require 'rails_helper'
require 'support/shared_examples_for_event_page_layout'

RSpec.describe 'Events::Shows', type: :system do
  before { driven_by(:rack_test) }

  before(:each, browser: true) { driven_by(:selenium) }

  let!(:user) { create(:user) }
  let!(:event) { create(:event, creator: user) }

  describe 'Events Show page' do
    describe 'Page content' do
      before { visit event_path(event) }

      include_examples 'event_layout' do
        let(:start_path) { event_path(event) }
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

      it 'has a link to edit event if user is event owner' do
        sign_in user
        visit event_path(event)
        click_link 'Click to switch to edit view'
        expect(page.has_current_path?(edit_event_path(event))).to be true
      end

      it 'has no link to edit event if user is not event owner' do
        visit event_path(event)
        expect(page.has_link?('Click to switch to edit view')).to be false
      end
    end

    describe 'user registration button for event', browser: true do
      context 'user is attending event' do
        before do
          create(:permission, user:, event:, permission_type: 'attend')

          sign_in user
          visit event_path(event)
        end

        it 'does not have a button to register' do
          expect(page.has_button?('Register')).to be false
        end

        it 'has a button to unregister' do
          expect(page.has_button?('Leave')).to be true
        end

        it 'button destroys the attendance' do
          click_button 'Leave'
          expect(UserEventPermission.where(user:, event:, permission_type: 'attend').count).to eq(0)
        end
      end

      context 'user is not attending event' do
        before do
          sign_in user
          visit event_path(event)
        end

        it 'has a button to register' do
          expect(page.has_button?('Register')).to be true
        end

        it 'does not have a button to unregister' do
          expect(page.has_button?('Leave')).to be false
        end

        it 'button creates an attendance' do
          click_button 'Register'
          expect(UserEventPermission.where(user:, event:, permission_type: 'attend').count).to eq(1)
        end
      end
    end
  end
end
