require 'rails_helper'
require 'general_helper'

RSpec.configure do |config|
  config.include GeneralHelper, subsets: :included
end

RSpec.describe User, type: :model do
  subject { described_class.new }

  let(:params_user) { { name: 'test', username: 'tester', password: 'tester', email: 'abc@gmail.com' } }
  let(:params_event) do
    { name: 'test', desc: 'te', date: DateTime.now, location: 'test', creator_id: test_user.id,
      event_privacy: priv_set, display_privacy: priv_set, attendee_privacy: priv_set }
  end
  let(:priv_set) { 'public' }
  let(:test_user) { User.create(params_user) }
  let(:test_event) { Event.create(params_event) }
  let(:test_perm) do
    generate_perms(test_user.id, test_event.id, test_perm_type)
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_least(3).is_at_most(20) }
    it { is_expected.to validate_presence_of(:username) }
    it { is_expected.to validate_uniqueness_of(:username) }
    it { is_expected.to validate_length_of(:username).is_at_least(5) }
  end

  describe 'Associations' do
    it { is_expected.to have_many(:events_created) }
    it { is_expected.to have_many(:user_event_permissions) }
    it { is_expected.to have_many(:event_relations) }
  end

  describe 'Event Filters', subsets: :included do
    before(:each) do
      @user = test_user
      @event = test_event
    end
    describe '#events_attended' do
      context 'when a attend perm is created' do
        let(:test_perm_type) { 'attend' }
        it do
          expect { test_perm }.to change { test_user.events_attended.count }.from(0).to(1)
        end
      end
      context 'when a non-attend perm is created' do
        let(:test_perm_type) { 'accept_invite' }
        it do
          expect { test_perm }.to_not(change { test_user.events_attended.count })
        end
      end
    end
    describe '#event_pending' do
      context 'when a attend perm is created' do
        let(:test_perm_type) { 'accept_invite' }
        it do
          expect { test_perm }.to change { test_user.events_pending.count }.from(0).to(1)
        end
      end
      context 'when a non-attend perm is created' do
        let(:test_perm_type) { 'attend' }
        it do
          expect { test_perm }.to_not(change { test_user.events_pending.count })
        end
      end
    end
  end

  describe '#attending?', subsets: :included do
    before(:each) do
      @user = test_user
      @event = test_event
    end
    context 'when a attend perm is created' do
      let(:test_perm_type) { 'attend' }
      it do
        expect { test_perm }.to change { test_user.attending?(test_event) }.from(false).to(true)
      end
    end
    context 'when attend is removed' do
      let(:test_perm_type) { 'attend' }
      it do
        test_perm
        expect { @event.user_event_permissions.destroy_all }
          .to change { test_user.attending?(test_event) }.from(true).to(false)
      end
    end
    context 'when a non-attend perm is created' do
      let(:test_perm_type) { 'accept_invite' }
      it do
        expect { test_perm }.to_not(change { test_user.attending?(test_event) })
      end
    end
  end

  describe '#invite?', subsets: :included do
    before(:each) do
      @user = test_user
      @event = test_event
    end
    context 'when a accept_invite perm is created' do
      let(:test_perm_type) { 'accept_invite' }
      it do
        expect { test_perm }.to change { test_user.invite?(test_event) }.from(false).to(true)
      end
    end
    context 'when accept_invite is removed' do
      let(:test_perm_type) { 'accept_invite' }
      it do
        test_perm
        expect { @event.user_event_permissions.destroy_all }
          .to change { test_user.invite?(test_event) }.from(true).to(false)
      end
    end
    context 'when a non-accept_invite perm is created' do
      let(:test_perm_type) { 'moderate' }
      it do
        expect { test_perm }.to_not(change { test_user.invite?(test_event) })
      end
    end
  end

  describe '#can_moderate?', subsets: :included do
    before(:each) do
      @user = test_user
      @event = test_event
      @event.user_event_permissions.destroy_all
    end
    context 'when a moderate perm is created' do
      let(:test_perm_type) { 'moderate' }
      it do
        expect { test_perm }.to change { test_user.can_moderate?(test_event) }.from(false).to(true)
      end
    end
    context 'when a owner perm is created' do
      let(:test_perm_type) { 'owner' }
      it do
        expect { test_perm }.to change { test_user.can_moderate?(test_event) }.from(false).to(true)
      end
    end
    context 'when both owner and moderate perms are created' do
      let(:test_perm_type) { %w[owner moderate] }
      it do
        expect { test_perm }.to change { test_user.can_moderate?(test_event) }.from(false).to(true)
      end
    end

    context 'when has both owner and moderate' do
      let(:test_perm_type) { %w[owner moderate] }
      before(:each) do
        test_perm
      end
      context 'when one perm is removed' do
        it do
          expect { @user.user_event_permissions.first.destroy }
            .to_not(change { test_user.can_moderate?(test_event) })
        end
      end
      context 'when all perms are removed' do
        it do
          expect { @user.user_event_permissions.destroy_all }
            .to change { test_user.can_moderate?(test_event) }.from(true).to(false)
        end
      end
    end
    context 'when a non-moderate perm is created' do
      let(:test_perm_type) { 'attend' }
      it do
        expect { test_perm }.to_not(change { test_user.can_moderate?(test_event) })
      end
    end
  end

  describe '#can_join?', subsets: :included do
    before(:each) do
      @user = test_user
      @event = test_event
      @event.user_event_permissions.destroy_all
    end
    # can join if no attending permission exists
    context 'event is public' do
      let(:priv_set) { 'public' }
      context 'when no attend perm exists' do
        let(:test_perm_type) { [] }
        it { expect(@user.can_join?(@event)).to be true }
      end
      context 'when attend perm exists' do
        let(:test_perm_type) { 'attend' }
        it do
          test_perm
          expect(@user.can_join?(@event)).to be false
        end
      end
    end
    # can join if no attending permission exists
    context 'event is protected' do
      let(:priv_set) { 'protected' }
      context 'when no attend perm exists' do
        let(:test_perm_type) { [] }
        it { expect(@user.can_join?(@event)).to be true }
      end
      context 'when attend perm exists' do
        let(:test_perm_type) { 'attend' }
        it do
          test_perm
          expect(@user.can_join?(@event)).to be false
        end
      end
    end
    # can join if no attending permission exists AND
    # user has accept_invite perm, owner perm or moderate perm
    context 'event is private' do
      let(:priv_set) { 'private' }
      before(:each) { test_perm }
      context 'when attend perm exists' do
        let(:test_perm_type) { 'attend' }
        it { expect(@user.can_join?(@event)).to be false }
      end
      describe 'attend takes precedence over all other perms' do
        let(:test_perm_type) { %w[owner moderate] }
        it do
          expect do
            @user.user_event_permissions.create(event_id: @event.id, permission_type: 'attend')
          end.to change { @user.can_join?(@event) }.from(true).to(false)
        end
      end
      context 'when accept_invite perm exists' do
        let(:test_perm_type) { 'accept_invite' }
        it { expect(@user.can_join?(@event)).to be true }
      end
      context 'when owner perm exists' do
        let(:test_perm_type) { 'owner' }
        it { expect(@user.can_join?(@event)).to be true }
      end
      context 'when moderate perm exists' do
        let(:test_perm_type) { 'moderate' }
        it { expect(@user.can_join?(@event)).to be true }
      end
    end
  end

  describe '#self.held_event_perms', subsets: :included do
    before(:each) do
      @user = test_user
      @event = test_event
    end
    context 'when user is nil' do
      it { expect(User.held_event_perms(nil, @event)).to be_nil }
    end
    context 'when user is not nil' do
      let(:permission_type) { double('permission_type', permission_type: nil) }
      let(:to_a) { double('to_a', to_a: [permission_type]) }
      let(:where) { double('where', where: to_a) }
      it do
        allow(@user).to receive(:user_event_permissions).and_return(where)
        expect(@user).to receive(:user_event_permissions)
        User.held_event_perms(@user, @event)
      end
    end
  end
end
