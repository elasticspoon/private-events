# frozen_string_literal: true

# rubocop:disable RSpec/ImplicitSubject, RSpec/ImplicitExpect
require 'rails_helper'

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
    it {
      should have_many(:events_created)
        .class_name('Event').with_foreign_key('creator_id')
        .dependent(:destroy).inverse_of(:creator)
    }

    it { should have_many(:user_event_permissions).dependent(:destroy) }
    it { should have_many(:event_relations).through(:user_event_permissions).source(:event) }

    it {
      should have_many(:events_attended_perms)
        .conditions(permission_type: 'attend').class_name('UserEventPermission')
        .dependent(false).inverse_of(:user)
    }

    it { should have_many(:events_attended).through(:events_attended_perms).source(:event) }

    it {
      should have_many(:events_pending_perms)
        .conditions(permission_type: 'accept_invite').class_name('UserEventPermission')
        .dependent(false).inverse_of(:user)
    }

    it { should have_many(:events_pending).through(:events_pending_perms).source(:event) }
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

  describe '#can_edit?', subsets: :included do
    it 'returns true if the user has an owner permission for the event' do
      create(:permission, user:, event:, permission_type: 'owner')
      expect(user.can_edit?(event)).to be true
    end

    it 'returns false if the user does not have an owner permission for the event' do
      expect(user.can_edit?(event)).to be false
    end
  end

  describe '#held_event_perms', subsets: :included do
    it 'returns an empty array of permissions if no perms' do
      expect(user.held_event_perms(event.id, -1)).to be_empty
    end

    it 'adds current_user permission to the array if perm user_id matches current_user_id' do
      expect(user.held_event_perms(event.id, user.id)).to match ['current_user']
    end

    it 'returns an array of same size as number of permissions' do
      create(:permission, user:, event:, permission_type: 'attend')

      expect do
        create(:permission, user:, event:, permission_type: 'owner')
      end.to change { user.held_event_perms(event.id, -1).size }.from(1).to(2)
    end

    it 'returns an array of permissions as strings' do
      create(:permission, user:, event:, permission_type: 'attend')
      create(:permission, user:, event:, permission_type: 'owner')

      expect(user.held_event_perms(event.id, -1)).to all(be_a(String))
    end
  end
end
# rubocop:enable RSpec/ImplicitSubject, RSpec/ImplicitExpect
