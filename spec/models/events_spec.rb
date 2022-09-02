# rubocop:disable RSpec/NestedGroups

require 'rails_helper'

RSpec.describe Event, type: :model do
  subject { described_class.new }

  let(:user) { create(:user) }
  let(:event) { create(:event) }
  let(:permission) { create(:permission, user:, event:) }

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:date) }
    it { is_expected.to validate_presence_of(:location) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:desc) }
    it { is_expected.to validate_inclusion_of(:event_privacy).in_array(Event::AVAILIABLE_SETTINGS) }
    it { is_expected.to validate_inclusion_of(:display_privacy).in_array(Event::AVAILIABLE_SETTINGS) }
    it { is_expected.to validate_inclusion_of(:attendee_privacy).in_array(Event::AVAILIABLE_SETTINGS) }
  end

  describe 'Associations' do
    it { is_expected.to have_many(:user_event_permissions) }
    it { is_expected.to have_many(:user_relations) }
    it { is_expected.to belong_to(:creator) }
  end

  describe 'Callbacks' do
    it 'creates owner permission when event is created' do
      event = build(:event, creator: user)
      expect { event.save }.to change { event.user_event_permissions.map(&:permission_type) }.from([]).to(['owner'])
    end
  end

  describe 'Testing filter methods' do
    describe '#accepted_invites' do
      it 'returns an empty array when event has no accepted invites' do
        expect(event.accepted_invites).to be_empty
      end

      it 'returns an array of accepted invites' do
        permission = create(:permission, user:, event:)
        expect(event.accepted_invites).to include(permission)
      end
    end

    describe '#pending_invites' do
      it 'returns an empty array when event has no accepted invites' do
        expect(event.accepted_invites).to be_empty
      end

      it 'returns an array of accepted invites' do
        permission = create(:permission, user:, event:, permission_type: 'accept_invite')
        expect(event.pending_invites).to include(permission)
      end
    end

    describe 'self.past' do
      it 'returns an empty array when there are no past events' do
        expect(described_class.past).to be_empty
      end

      it 'returns an array of past events' do
        event = create(:event, date: DateTime.yesterday)
        expect(described_class.past).to include(event)
      end
    end

    describe 'self.future' do
      it 'returns an empty array when there are no future events' do
        expect(described_class.future).to be_empty
      end

      it 'returns an array of future events' do
        event = create(:event, date: DateTime.tomorrow)
        expect(described_class.future).to include(event)
      end
    end
  end

  describe 'Stub Factory Methods' do
    let(:user) { build_stubbed(:user) }
    let(:event) { build_stubbed(:event) }
    let(:permission) { build_stubbed(:permission, user:, event:) }

    describe '#past?' do
      it 'returns true when event is in the past' do
        event = build_stubbed(:event, date: DateTime.yesterday)
        expect(event).to be_past
      end

      it 'returns true when event is now' do
        event = build_stubbed(:event, date: DateTime.now)
        expect(event).to be_past
      end

      it 'returns false when event is in the future' do
        event = build_stubbed(:event, date: DateTime.tomorrow)
        expect(event).not_to be_past
      end
    end

    describe '#future?' do
      it 'returns true when event is in the past' do
        event = build_stubbed(:event, date: DateTime.tomorrow)
        expect(event).to be_future
      end

      it 'returns false when event is in the future' do
        event = build_stubbed(:event, date: DateTime.yesterday)
        expect(event).not_to be_future
      end
    end

    describe '#price' do
      it 'returns the price of the event, currently a placeholder: free' do
        expect(event.price).to eq('Free')
      end
    end

    describe '#image_url' do
      it 'returns the image url of the event, currently a placeholder: some string' do
        expect(event.image_url).to be_a(String)
      end
    end
  end

  describe 'Create Factory Methods' do
    describe '#attending_viewable_by?' do
      context 'when attendee_privacy is public' do
        let(:event) { build_stubbed(:event, attendee_privacy: 'public') }

        it 'returns true when user is nil' do
          expect(event.attending_viewable_by?(nil)).to be true
        end
      end

      context 'when attendee_privacy is protected' do
        let(:event) { build_stubbed(:event, attendee_privacy: 'protected') }

        it 'returns false when user is nil' do
          expect(event.attending_viewable_by?(nil)).to be false
        end

        it 'returns true for any user' do
          expect(event.attending_viewable_by?(user)).to be true
        end
      end

      context 'when attendee_privacy is private' do
        let(:event) { create(:event, attendee_privacy: 'private') }

        it 'returns false when user is nil' do
          expect(event.attending_viewable_by?(nil)).to be false
        end

        it 'returns false when user has no permissions' do
          expect(event.attending_viewable_by?(user)).to be false
        end

        it 'returns false when user has not accepted the invite' do
          create(:permission, user:, event:, permission_type: 'accept_invite')
          expect(event.attending_viewable_by?(user)).to be false
        end

        it 'returns true when user has owner permission' do
          create(:permission, user:, event:, permission_type: 'owner')
          expect(event.attending_viewable_by?(user)).to be true
        end

        it 'returns true when user has moderate permission' do
          create(:permission, user:, event:, permission_type: 'moderate')
          expect(event.attending_viewable_by?(user)).to be true
        end

        it 'returns true when user has attend permission' do
          create(:permission, user:, event:, permission_type: 'attend')
          expect(event.attending_viewable_by?(user)).to be true
        end
      end
    end

    describe '#viewable_by?' do
      context 'when display_privacy is public' do
        let(:event) { build_stubbed(:event, display_privacy: 'public') }

        it 'returns true when user is nil' do
          expect(event.viewable_by?(nil)).to be true
        end
      end

      context 'when display_privacy is protected' do
        let(:event) { build_stubbed(:event, display_privacy: 'protected') }

        it 'returns false when user is nil' do
          expect(event.viewable_by?(nil)).to be false
        end

        it 'returns true for any user' do
          expect(event.viewable_by?(user)).to be true
        end
      end

      context 'when display_privacy is private' do
        let(:event) { create(:event, display_privacy: 'private') }

        it 'returns false when user is nil' do
          expect(event.viewable_by?(nil)).to be false
        end

        it 'returns false when user has no permissions' do
          expect(event.viewable_by?(user)).to be false
        end

        it 'returns false when user has not accepted the invite' do
          create(:permission, user:, event:, permission_type: 'accept_invite')
          expect(event.viewable_by?(user)).to be false
        end

        it 'returns true when user has owner permission' do
          create(:permission, user:, event:, permission_type: 'owner')
          expect(event.viewable_by?(user)).to be true
        end

        it 'returns true when user has moderate permission' do
          create(:permission, user:, event:, permission_type: 'moderate')
          expect(event.viewable_by?(user)).to be true
        end

        it 'returns true when user has attend permission' do
          create(:permission, user:, event:, permission_type: 'attend')
          expect(event.viewable_by?(user)).to be true
        end
      end
    end

    describe '#joinable_by?' do
      let(:event) { create(:event, event_privacy: 'public') }

      it 'returns false when user is nil' do
        expect(event.joinable_by?(nil)).to be false
      end

      it 'returns false when user already has attend permission' do
        create(:permission, user:, event:, permission_type: 'attend')
        expect(event.joinable_by?(user)).to be false
      end

      context 'when event is public' do
        it 'returns true' do
          expect(event.joinable_by?(user)).to be true
        end
      end

      context 'when event is protected' do
        let(:event) { create(:event, event_privacy: 'protected') }

        it 'returns true' do
          expect(event.joinable_by?(user)).to be true
        end
      end

      context 'when event is private' do
        let(:event) { create(:event, event_privacy: 'private') }

        it 'returns false when user has no permissions' do
          expect(event.joinable_by?(user)).to be false
        end

        it 'returns true if user has accept_invite permission' do
          create(:permission, user:, event:, permission_type: 'accept_invite')
          expect(event.joinable_by?(user)).to be true
        end

        it 'returns true if user has owner permission' do
          create(:permission, user:, event:, permission_type: 'owner')
          expect(event.joinable_by?(user)).to be true
        end

        it 'returns true if user has moderate permission' do
          create(:permission, user:, event:, permission_type: 'moderate')
          expect(event.joinable_by?(user)).to be true
        end
      end
    end

    describe 'editable_by?' do
      it 'returns false when user is nil' do
        expect(event.editable_by?(nil)).to be false
      end

      it 'returns false when user has no perms' do
        expect(event.editable_by?(user)).to be false
      end

      it 'returns true when user has owner permission' do
        create(:permission, user:, event:, permission_type: 'owner')
        expect(event.editable_by?(user)).to be true
      end

      it 'returns false when user has only moderate permission' do
        create(:permission, user:, event:, permission_type: 'moderate')
        expect(event.editable_by?(user)).to be false
      end
    end

    # TODO: Fix coupling here
    describe '#required_perms_for action' do
      it 'calls required_perms_for_action with action and perm_type arguments' do
        event = instance_double(described_class, required_perms_for_action: {})
        event.required_perms_for_action(action: :create, perm_type: 'moderate')
        expect(event).to have_received(:required_perms_for_action).with(action: :create, perm_type: 'moderate').once
      end

      it 'raises an error if action - perm_type combo is invalid' do
        action = :invalid
        perm_type = 'attend'
        allow(event).to receive(:required_permissions).and_return({})
        expect { event.required_perms_for_action(action:, perm_type:) }
          .to raise_error RuntimeError, "Invalid perm type: #{perm_type} or action: #{action}"
      end
    end
  end
end

# rubocop:enable RSpec/NestedGroups