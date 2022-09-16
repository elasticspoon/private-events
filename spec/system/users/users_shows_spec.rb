require 'rails_helper'
require 'support/shared_examples_for_event_page_layout'
require 'support/shared_examples_for_event_join_icon'

RSpec.describe 'Users::Shows', type: :system do
  before { driven_by(:rack_test) }

  before(:each, browser: true) { driven_by(:selenium) }

  let!(:user) { create(:user) }
  let(:event) { build_stubbed(:event) }

  include_examples 'event_layout' do
    let(:start_path) { user_path(user) }
  end
  include_examples 'join event button' do
    let(:start_path) { user_path(user) }
  end

  describe 'page contents' do
    before do
      event
      visit user_path(user)
    end

    it 'has correct user name' do
      expect(page.has_content?(user.username.titleize)).to be true
    end

    it 'has corrent number of events' do
      expect(page.has_content?(user.events_created.count)).to be true
    end

    describe 'shows events user has created' do
      context 'when user has created a future event' do
        let(:event) { create(:event, creator: user, date: 1.day.from_now) }

        it 'shows the event' do
          within '#future-events' do
            expect(page.has_content?(event.name.titleize)).to be true
          end
        end

        it 'shows the event count' do
          expect(page.has_content?('Upcoming (1)')).to be true
        end
      end

      context 'when user has created a past event' do
        let(:event) { create(:event, creator: user, date: 1.day.ago) }

        it 'shows the event', browser: true do
          click_button 'Past (1)'
          within '#past-events' do
            expect(page.has_content?(event.name.titleize)).to be true
          end
        end

        it 'shows the event count' do
          expect(page.has_content?('Past (1)')).to be true
        end
      end

      context 'when user has created no events' do
        let(:event) { nil }

        it 'shows the event count future' do
          visit user_path(user)
          expect(page.has_content?('Upcoming (0)')).to be true
        end

        it 'shows the event count past' do
          visit user_path(user)
          expect(page.has_content?('Past (0)')).to be true
        end
      end
    end
  end
end
