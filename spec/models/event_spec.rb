require 'rails_helper'
require 'general_helper'

RSpec.configure do |config|
  config.include GeneralHelper, subsets: :included
end

RSpec.describe Event, type: :model, subsets: :included do
  subject { described_class.new }
  let(:params_user) { { name: 'test', username: 'tester', password: 'tester', email: 'abc@gmail.com' } }
  let(:params_event) do
    { name: 'test', desc: 'te', date: DateTime.now, location: 'test', creator_id: test_user.id,
      event_privacy: priv_set, display_privacy: priv_set, attendee_privacy: priv_set }
  end
  let(:priv_set) { 'public' }
  # let(:test_perm_type) { 'attend' }
  let(:test_user) { User.create(params_user) }
  let(:test_event) { Event.create(params_event) }
  let(:test_perm) do
    generate_perms(test_user.id, test_event.id, test_perm_type)
  end
  let(:attend_perm) do
    [
      priv_set == 'public' ? [] : ['accept_invite'],
      'all_required'
    ]
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:date) }
    it { is_expected.to validate_presence_of(:location) }
    it { is_expected.to validate_presence_of(:creator_id) }
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

  context 'when new event is created' do
    it do
      test_user
      event = test_event
      event_permissions = event.user_event_permissions.map(&:permission_type)
      expect(event_permissions).to eq(['owner'])
    end
  end

  describe 'Testing filter methods' do
    before(:each) do
      test_user
      @event = test_event
    end
    context '#accepted_invites' do
      context 'when there are no accepted invites' do
        it { expect(@event.accepted_invites).to be_empty }
      end

      context 'when there are accepted invites' do
        let(:test_perm_type) { 'attend' }
        it {
          expect { test_perm }.to change { @event.accepted_invites.count }.by(1)
        }
      end
    end
    context '#pending_invites' do
      context 'when there are no pending invites' do
        it {
          expect(@event.pending_invites).to be_empty
        }
      end

      context 'when there are pending invites' do
        let(:test_perm_type) { 'accept_invite' }
        it do
          expect { test_perm }.to change { @event.pending_invites.count }.by(1)
        end
      end
    end
    context '#self.past' do
      context 'when there are no past events' do
        it do
          UserEventPermission.destroy_all
          Event.destroy_all
          expect(Event.past).to be_empty
        end
      end

      context 'when there are past events' do
        let(:params_event) do
          { name: 'test', desc: 'te', date: DateTime.now - 1.day, location: 'test', creator_id: test_user.id,
            event_privacy: priv_set, display_privacy: priv_set, attendee_privacy: priv_set }
        end
        it do
          expect { Event.create(params_event) }.to change { Event.past.count }.by(1)
        end
        it do
          expect(Event.create(params_event).past?).to be true
        end
      end
    end
    context '#self.future' do
      context 'when there are no future events' do
        it do
          UserEventPermission.destroy_all
          Event.destroy_all
          expect(Event.display_public).to be_empty
        end
      end

      context 'when there are future events' do
        let(:priv_set) { 'public' }
        before(:each) do
          UserEventPermission.destroy_all
          Event.destroy_all
        end
        it do
          expect { Event.create(params_event) }.to change { Event.display_public.count }.by(1)
        end
      end
    end
    context '#self.display_public' do
      context 'when there are no public events' do
        it { expect(Event.future).to be_empty }
      end

      context 'when there are future events' do
        let(:params_event) do
          { name: 'test', desc: 'te', date: DateTime.now + 1.day, location: 'test', creator_id: test_user.id,
            event_privacy: priv_set, display_privacy: priv_set, attendee_privacy: priv_set }
        end
        it do
          expect { Event.create(params_event) }.to change { Event.future.count }.by(1)
        end
        it do
          expect(Event.create(params_event).future?).to be true
        end
      end
    end
  end

  # add permutations of the permission settings
  # add checks for when no persmssions are given
  describe 'Permissions checks of a user for an event' do
    %w[public private protected].each do |privacy|
      context "when privacy setting is #{privacy}" do
        let(:priv_set) { privacy }
        before(:each) do
          @user = test_user
          @event = test_event
        end
        context 'when user is nil' do
          it { expect(@event.attending_viewable_by?(nil)).to be privacy == 'public' }
          it { expect(@event.viewable_by?(nil)).to be privacy == 'public' }
          it { expect(@event.joinable_by?(nil)).to be false }
        end
        context 'when user is not nil' do
          before(:each) do
            @user.user_event_permissions.destroy_all
            test_perm
          end

          context 'when user has no permissions' do
            let(:test_perm_type) { [] }
            it { expect(@event.attending_viewable_by?(@user)).to be privacy != 'private' }
            it { expect(@event.viewable_by?(@user)).to be privacy != 'private' }
            it { expect(@event.joinable_by?(@user)).to be privacy != 'private' }
          end
          %w[attend accept_invite].each do |uniq_perm|
            GeneralHelper.non_empty_array_subsets(['owner', 'moderate', uniq_perm]).each do |perm|
              context "when user perms: #{perm}" do
                let(:test_perm_type) { perm }
                it do
                  all_user_perms = @user.user_event_permissions.where(event_id: @event.id).map(&:permission_type)
                  expect(all_user_perms).to match_array perm
                end
                context '#attending_viewable_by?' do
                  it do
                    expected_value = perm.any? || privacy != 'private'
                    expect(@event.attending_viewable_by?(@user)).to be expected_value
                  end
                end
                context '#viewable_by' do
                  it do
                    expected_value = perm.any? || privacy != 'private'
                    expect(@event.viewable_by?(@user)).to be expected_value
                  end
                end
                context '#joinable_by?' do
                  it do
                    expect(@event.joinable_by?(@user)).to be !perm.include?('attend')
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  describe '#required_perms_for_action' do
    before(:each) do
      @user = test_user
      @event = test_event
    end
    context 'when perm type or action is bad' do
      [['attend', :invalid], ['invalid', :invalid], ['invalid', :create]]
        .each do |perm_type, action|
        context "when perm_type: #{perm_type}, action: #{action}" do
          it do
            expect { @event.required_perms_for_action(perm_type, action) }
              .to raise_error RuntimeError, "Invalid perm type: #{perm_type} or action: #{action}"
          end
        end
      end
    end
    context 'when perm type is good' do
      it do
        some_hash = {}
        allow(@event).to receive(:required_permissions).and_return(some_hash)
        allow(some_hash).to receive(:dig).and_return('some val')
        expect(some_hash).to receive(:dig).with('some_perm_type', 'some action')
        @event.required_perms_for_action('some action', 'some_perm_type')
      end
    end
  end

  # before event is saved, it has no permissions
  # when saved event has permissions
  # if private or protected perms to attend :accept_invite, :current_user
  # otherwise, just :current_user
  # describe 'required perms set on event creation' do
  #   before(:each) { @user = test_user }
  #   context 'before event is saved' do
  #     let(:test_event) { Event.new(params_event) }
  #     it { expect(test_event.required_permissions).to be_falsey }
  #   end
  #   context 'after event is saved' do
  #     before(:each) { @event = test_event }

  #     it { expect(@event.required_permissions).to_not be_falsey }
  #   end
  # end
end
