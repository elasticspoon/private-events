# rubocop:disable RSpec/NestedGroups

# frozen_string_literal: true

require 'rails_helper'
require 'general_helper'

RSpec.configure do |config|
  config.include GeneralHelper, subsets: :included
end

RSpec.describe User, type: :model do
  subject { create(:user) }

  let(:user) { subject }
  let(:event) { create(:event) }

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_least(3).is_at_most(30) }
    it { is_expected.to validate_presence_of(:username) }
    it { is_expected.to validate_uniqueness_of(:username) }
    it { is_expected.to validate_length_of(:username).is_at_least(5) }
  end

  describe 'Associations' do
    it { is_expected.to have_many(:events_created) }
    it { is_expected.to have_many(:user_event_permissions) }
    it { is_expected.to have_many(:event_relations) }
  end

  describe 'Event Filters' do
    describe '#events_attended' do
      it 'returns events the user has an attend permission for' do
        create(:permission, user:, event:, permission_type: 'attend')
        expect(user.events_attended).to include(event)
      end

      it 'returns no events when the user has no attend permission' do
        create(:permission, user:, event:, permission_type: 'accept_invite')
        expect(user.events_attended).not_to include(event)
      end
    end

    describe '#event_pending' do
      it 'returns events the user has an accept_invite permission for' do
        create(:permission, user:, event:, permission_type: 'accept_invite')
        expect(user.events_pending).to include(event)
      end

      it 'returns no events when the user has no accept_invite permission' do
        create(:permission, user:, event:, permission_type: 'attend')
        expect(user.events_pending).not_to include(event)
      end
    end
  end

  describe '#attending?', subsets: :included do
    it 'returns true if the user has an attend permission for the event' do
      create(:permission, user:, event:, permission_type: 'attend')
      expect(user.attending?(event)).to be true
    end

    it 'returns false if the user does not have an attend permission for the event' do
      expect(user.attending?(event)).to be false
    end
  end

  describe '#invite?', subsets: :included do
    it 'returns true if the user has an attend permission for the event' do
      create(:permission, user:, event:, permission_type: 'accept_invite')
      expect(user.invite?(event)).to be true
    end

    it 'returns false if the user does not have an attend permission for the event' do
      expect(user.invite?(event)).to be false
    end
  end

  describe '#can_moderate?', subsets: :included do
    it 'returns true if the user has an moderate permission for the event' do
      create(:permission, user:, event:, permission_type: 'moderate')
      expect(user.can_moderate?(event)).to be true
    end

    it 'returns true if the user has an owner permission for the event' do
      create(:permission, user:, event:, permission_type: 'owner')
      expect(user.can_moderate?(event)).to be true
    end

    it 'returns true if the user has both owner and moderate permission for the event' do
      create(:permission, user:, event:, permission_type: 'owner')
      create(:permission, user:, event:, permission_type: 'moderate')
      expect(user.can_moderate?(event)).to be true
    end

    it 'returns false if the user does not have an moderate or owner permission for the event' do
      expect(user.can_moderate?(event)).to be false
    end
  end

  describe '#can_join?', subsets: :included do
    context 'when event is public' do
      let(:event) { create(:event, event_privacy: 'public') }

      it 'returns true if user does not have attend permission already' do
        expect(user.can_join?(event)).to be true
      end

      it 'returns false if user has attend permission already' do
        create(:permission, user:, event:, permission_type: 'attend')
        expect(user.can_join?(event)).to be false
      end
    end

    context 'when event is protected' do
      let(:event) { create(:event, event_privacy: 'protected') }

      it 'returns true if user does not have attend permission already' do
        expect(user.can_join?(event)).to be true
      end

      it 'returns false if user has attend permission already' do
        create(:permission, user:, event:, permission_type: 'attend')
        expect(user.can_join?(event)).to be false
      end
    end

    context 'when event is private' do
      let(:event) { create(:event, event_privacy: 'private') }

      context 'when user has attend permission already' do
        before { create(:permission, user:, event:, permission_type: 'attend') }

        it { expect(user.can_join?(event)).to be false }

        it 'returns false even with owner and moderate permissions' do
          create(:permission, user:, event:, permission_type: 'owner')
          create(:permission, user:, event:, permission_type: 'moderate')
          expect(user.can_join?(event)).to be false
        end
      end

      it 'returns true if user has accept_invite permission' do
        create(:permission, user:, event:, permission_type: 'accept_invite')
        expect(user.can_join?(event)).to be true
      end

      it 'returns true if user has owner permission' do
        create(:permission, user:, event:, permission_type: 'owner')
        expect(user.can_join?(event)).to be true
      end

      it 'returns true if user has moderate permission' do
        create(:permission, user:, event:, permission_type: 'moderate')
        expect(user.can_join?(event)).to be true
      end

      it 'returns false if user has no permissions' do
        expect(user.can_join?(event)).to be false
      end
    end
  end

  describe '#self.held_event_perms', subsets: :included do
    it 'returns an empty array when user is nil' do
      expect(described_class.held_event_perms(nil, event)).to be_nil
    end

    context 'when user is not nil' do
      it 'returns an empty array of permissions if no perms' do
        expect(described_class.held_event_perms(user, event)).to be_empty
      end

      it 'returns an array of same size as number of permissions' do
        create(:permission, user:, event:, permission_type: 'attend')

        expect do
          create(:permission, user:, event:, permission_type: 'owner')
        end.to change { described_class.held_event_perms(user, event).size }.from(1).to(2)
      end

      it 'returns an array of permissions as strings' do
        create(:permission, user:, event:, permission_type: 'attend')
        create(:permission, user:, event:, permission_type: 'owner')

        expect(described_class.held_event_perms(user, event)).to all(be_a(String))
      end
    end
  end
end
# rubocop:enable RSpec/NestedGroups
