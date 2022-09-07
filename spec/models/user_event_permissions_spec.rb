# frozen_string_literal: true

# rubocop:disable RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups

require 'rails_helper'

RSpec.describe UserEventPermission, type: :model do
  subject { described_class.new }

  let(:user) { create(:user) }
  let(:event) { create(:event) }
  let(:permission) { create(:permission, user:, event:) }
  let(:user_held_perms) { [] }

  describe 'Validations' do
    it do
      expect(permission).to validate_inclusion_of(:permission_type)
        .in_array(UserEventPermission::PERMISSION_TYPES).with_message('is invalid.')
    end
  end

  describe 'Associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:event) }
  end

  # custom check to ensure uniqueness validation works
  context 'when creating a second user_event_permission with the same user_id and event_id' do
    before { permission }

    it 'allows a second permission of a different type' do
      permission_two = build(:permission, user:, event:, permission_type: 'owner')
      expect(permission_two).to be_valid
    end

    it 'does not allow a second permission of the same type' do
      permission_two = build(:permission, user:, event:, permission_type: 'attend')
      expect(permission_two).not_to be_valid
    end

    it 'does not allow an accept_invite if attend exists' do
      permission_two = build(:permission, user:, event:, permission_type: 'accept_invite')
      expect(permission_two).not_to be_valid
    end

    context 'first permission is accept_invite' do
      let(:permission) { create(:permission, user:, event:, permission_type: 'attend') }

      it 'does not allow an attend if accept_invite exists' do
        create(:permission, user:, event:, permission_type: 'accept_invite')
        permission_two = build(:permission, user:, event:, permission_type: 'attend')
        expect(permission_two).not_to be_valid
      end
    end
  end

  describe '#self.invite_target_id' do
    let(:params) do
      lambda { |identifier|
        ActionController::Parameters.new({ event_id: event.id, permission_type: 'attend', identifier: })
      }
    end
    let(:target_user) { create(:user) }
    let(:current_user) { create(:user) }

    it 'returns current_user.id if identifier is not provided' do
      expect(described_class.invite_target_id(params[nil], current_user.id)).to eq(current_user.id)
    end

    it 'returns nil if email identifier provided but not found' do
      expect(described_class.invite_target_id(params[{ email: :invalid }], current_user.id)).to be_nil
    end

    it 'returns id of user with matching email if valid email identifier provided' do
      expect(described_class.invite_target_id(params[{ email: target_user.email }], current_user.id))
        .to eq(target_user.id)
    end

    it 'raises error if multiple identifiers provided' do
      expect do
        described_class.invite_target_id(params[{ email: target_user.email, user_id: target_user.id }], current_user.id)
      end
        .to raise_error RuntimeError, /Invalid identifier/
    end

    it 'returns user_id if user_id identifier provided' do
      expect(described_class.invite_target_id(params[{ user_id: :some_id }], current_user.id)).to eq(:some_id)
    end
  end

  describe 'Integration Tests' do
    let(:event_perms) { [] }
    let(:perm_type) { 'attend' }
    let(:event) { create(:event, creator: user) }
    let(:params) do
      lambda { |perm_type|
        ActionController::Parameters.new({ event_id: event.id, permission_type: perm_type,
                                           identifier: { user_id: user.id } })
      }
    end

    before do
      event
      allow(user).to receive(:held_event_perms).and_return(user_held_perms)
      described_class.destroy_all
    end

    context 'when starting tests' do
      it 'no permissions exist' do
        expect(described_class.all).to be_empty
      end

      it 'one event exists' do
        expect(Event.count).to eq(1)
      end

      it 'one user exists' do
        expect(User.count).to eq(1)
      end
    end

    describe 'create_permission' do
      before do
        event
        described_class.destroy_all
        allow(user).to receive(:held_event_perms).and_return(event_perms)
      end

      context 'when starting test' do
        it 'no permissions exist' do
          expect(described_class.all).to be_empty
        end

        it 'one event exists' do
          expect(Event.count).to eq(1)
        end

        it 'one users exists' do
          expect(User.count).to eq(1)
        end
      end

      it 'no permissions created if user has no permissions' do
        described_class.create_permission(params['attend'], user)
        expect(user.user_event_permissions).to be_empty
      end

      it 'returns a notice and success response if a permission is succesfully created' do
        allow(user).to receive(:held_event_perms).and_return(['current_user'])
        response = described_class.create_permission(params['attend'], user)
        expect(response).to match_array([:notice, 'Successfully created permission.'])
      end

      it 'returns an array with an alert if a permission is not succesfully created' do
        response = described_class.create_permission(params['attend'], user)
        expect(response[0]).to eq(:alert)
      end

      it 'returns an array with an error message if a permission is not succesfully created' do
        response = described_class.create_permission(params['attend'], user)
        expect(response[1]).to be_a(String)
      end

      context 'when user has permissions: [current_user]' do
        let(:event_perms) { ['current_user'] }

        it 'creates attend permission' do
          described_class.create_permission(params['attend'], user)
          expect(user.user_event_permissions.pluck(:permission_type)).to match ['attend']
        end

        it 'does not create owner permission' do
          expect do
            described_class.create_permission(params['owner'], user)
          end.to raise_error RuntimeError, /Invalid perm type/
        end

        it 'does not create accept_invite permission' do
          described_class.create_permission(params['accept_invite'], user)
          expect(user.user_event_permissions).to be_empty
        end

        it 'does not create moderate permission' do
          described_class.create_permission(params['moderate'], user)
          expect(user.user_event_permissions).to be_empty
        end

        context 'when event is private' do
          let(:event) { create(:event, creator: user, event_privacy: 'private') }

          it 'does not create attend permission' do
            described_class.create_permission(params['attend'], user)
            expect(user.user_event_permissions).to be_empty
          end

          it 'creates attend permission if also has accept_invite' do
            allow(user).to receive(:held_event_perms).and_return(%w[accept_invite current_user])
            described_class.create_permission(params['attend'], user)
            expect(user.user_event_permissions.pluck(:permission_type)).to include('attend')
          end

          it 'removes accept_invite permission if attend if created' do
            allow(user).to receive(:held_event_perms).and_return(%w[accept_invite current_user])
            described_class.create_permission(params['attend'], user)
            expect(user.user_event_permissions.pluck(:permission_type)).not_to include('accept_invite')
          end
        end
      end

      context 'when user has permissions: [attend]' do
        let(:event_perms) { ['attend'] }

        it 'does not create owner permission' do
          expect do
            described_class.create_permission(params['owner'], user)
          end.to raise_error RuntimeError, /Invalid perm type/
        end

        it 'does not create accept_invite permission' do
          described_class.create_permission(params['accept_invite'], user)
          expect(user.user_event_permissions).to be_empty
        end

        it 'does not create moderate permission' do
          described_class.create_permission(params['moderate'], user)
          expect(user.user_event_permissions).to be_empty
        end
      end

      context 'when user has permissions: [owner]' do
        let(:event_perms) { ['owner'] }

        it 'does not create attend permission' do
          described_class.create_permission(params['attend'], user)
          expect(user.user_event_permissions).to be_empty
        end

        it 'does not create owner permission' do
          expect do
            described_class.create_permission(params['owner'], user)
          end.to raise_error RuntimeError, /Invalid perm type/
        end

        it 'creates accept_invite permission' do
          described_class.create_permission(params['accept_invite'], user)
          expect(user.user_event_permissions.pluck(:permission_type)).to match ['accept_invite']
        end

        it 'creates moderate permission' do
          described_class.create_permission(params['moderate'], user)
          expect(user.user_event_permissions.pluck(:permission_type)).to match ['moderate']
        end
      end

      context 'when user has permissions: [moderate]' do
        let(:event_perms) { ['moderate'] }

        it 'does not create attend permission' do
          described_class.create_permission(params['attend'], user)
          expect(user.user_event_permissions).to be_empty
        end

        it 'does not create owner permission' do
          expect do
            described_class.create_permission(params['owner'], user)
          end.to raise_error RuntimeError, /Invalid perm type/
        end

        it 'creates accept_invite permission' do
          described_class.create_permission(params['accept_invite'], user)
          expect(user.user_event_permissions.pluck(:permission_type)).to match ['accept_invite']
        end

        it 'does not create moderate permission' do
          described_class.create_permission(params['moderate'], user)
          expect(user.user_event_permissions).to be_empty
        end
      end
    end

    describe 'destroy_permission' do
      context 'general tests' do
        before { permission }

        it 'users starts with an attend permission' do
          expect(user.user_event_permissions.pluck(:permission_type)).to match ['attend']
        end

        it 'no permissions destroyed if user has no permissions' do
          described_class.destroy_permission(params['attend'], user)
          expect(user.user_event_permissions.pluck(:permission_type)).to match ['attend']
        end

        it 'returns a notice and success response if a permission is succesfully destroyed' do
          allow(user).to receive(:held_event_perms).and_return(['current_user'])
          response = described_class.destroy_permission(params['attend'], user)
          expect(response).to match_array([:notice, 'Successfully destroyed permission.'])
        end

        it 'returns an array with an alert if a permission is not succesfully destroyed' do
          response = described_class.destroy_permission(params['attend'], user)
          expect(response[0]).to eq(:alert)
        end

        it 'returns an array with an error message if a permission is not succesfully destroyed' do
          response = described_class.destroy_permission(params['attend'], user)
          expect(response[1]).to be_a(String)
        end
      end

      context 'when user has permissions: [attend]' do
        before { permission }

        let(:user_held_perms) { ['attend'] }

        it 'does not destroy attend permission' do
          described_class.destroy_permission(params['attend'], user)
          expect(user.user_event_permissions.pluck(:permission_type)).to match ['attend']
        end

        it 'destroys attend permission if user also has current_user permission' do
          allow(user).to receive(:held_event_perms).and_return(%w[attend current_user])
          described_class.destroy_permission(params['attend'], user)
          expect(user.user_event_permissions.pluck(:permission_type)).to be_empty
        end

        it 'does not destroy owner permission' do
          create(:permission, permission_type: 'owner', user:, event:)
          expect do
            described_class.destroy_permission(params['owner'], user)
          end.to raise_error RuntimeError, /Invalid perm type/
        end

        it 'does not destroy accept_invite permission' do
          create(:permission, permission_type: 'accept_invite', user:, event:)
          described_class.destroy_permission(params['accept_invite'], user)
          expect(user.user_event_permissions.pluck(:permission_type)).to match ['accept_invite']
        end

        it 'does not destroy moderate permission' do
          create(:permission, permission_type: 'moderate', user:, event:)
          described_class.destroy_permission(params['moderate'], user)
          expect(user.user_event_permissions.pluck(:permission_type)).to match ['moderate']
        end
      end

      context 'when user has permissions: [accept_invite]' do
        let(:user_held_perms) { ['accept_invite'] }

        it 'does not destroy attend permission' do
          permission
          described_class.destroy_permission(params['attend'], user)
          expect(user.user_event_permissions.pluck(:permission_type)).to match ['attend']
        end

        it 'does not destroy owner permission' do
          create(:permission, permission_type: 'owner', user:, event:)
          expect do
            described_class.destroy_permission(params['owner'], user)
          end.to raise_error RuntimeError, /Invalid perm type/
        end

        it 'does not destroy accept_invite permission' do
          create(:permission, permission_type: 'accept_invite', user:, event:)
          described_class.destroy_permission(params['accept_invite'], user)
          expect(user.user_event_permissions.pluck(:permission_type)).to match ['accept_invite']
        end

        it 'does not destroy moderate permission' do
          create(:permission, permission_type: 'moderate', user:, event:)
          described_class.destroy_permission(params['moderate'], user)
          expect(user.user_event_permissions.pluck(:permission_type)).to match ['moderate']
        end
      end

      context 'when user has permissions: [owner]' do
        let(:user_held_perms) { ['owner'] }

        it 'destroys attend permission' do
          permission
          described_class.destroy_permission(params['attend'], user)
          expect(user.user_event_permissions).to be_empty
        end

        it 'does not destroy owner permission' do
          create(:permission, permission_type: 'owner', user:, event:)
          expect do
            described_class.destroy_permission(params['owner'], user)
          end.to raise_error RuntimeError, /Invalid perm type/
        end

        it 'destroys accept_invite permission' do
          create(:permission, permission_type: 'accept_invite', user:, event:)
          described_class.destroy_permission(params['accept_invite'], user)
          expect(user.user_event_permissions).to be_empty
        end

        it 'destroys moderate permission' do
          create(:permission, permission_type: 'moderate', user:, event:)
          described_class.destroy_permission(params['moderate'], user)
          expect(user.user_event_permissions).to be_empty
        end
      end

      context 'when user has permissions: [moderate]' do
        let(:user_held_perms) { ['moderate'] }

        it 'destroys attend permission' do
          permission
          described_class.destroy_permission(params['attend'], user)
          expect(user.user_event_permissions).to be_empty
        end

        it 'does not destroy owner permission' do
          create(:permission, permission_type: 'owner', user:, event:)
          expect do
            described_class.destroy_permission(params['owner'], user)
          end.to raise_error RuntimeError, /Invalid perm type/
        end

        it 'destroys accept_invite permission' do
          create(:permission, permission_type: 'accept_invite', user:, event:)
          described_class.destroy_permission(params['accept_invite'], user)
          expect(user.user_event_permissions).to be_empty
        end

        it 'does not destroy moderate permission' do
          create(:permission, permission_type: 'moderate', user:, event:)
          described_class.destroy_permission(params['moderate'], user)
          expect(user.user_event_permissions.pluck(:permission_type)).to match ['moderate']
        end
      end
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers, RSpec/NestedGroups
