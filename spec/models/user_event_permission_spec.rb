require 'rails_helper'

RSpec.describe UserEventPermission, type: :model do
  let(:mock_user) { instance_double(User, id: 1) }
  let(:mock_event) { instance_double(Event, id: 1) }
  let(:test_perm) { UserEventPermission.new }

  describe 'Validations' do
    subject { described_class.new }
    it { is_expected.to validate_presence_of(:user_id) }
    it { is_expected.to validate_presence_of(:event_id) }
    it do
      is_expected.to validate_inclusion_of(:permission_type).in_array(UserEventPermission::PERMISSION_TYPES)
                                                            .with_message('is invalid.')
    end
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:event) }
  end

  describe 'Associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:event) }
  end

  # custom check to ensure uniqueness validation works
  describe 'Uniqueness Validations' do
    before(:each) do
      user = User.create(name: 'test', username: 'tester', password: 'tester', email: 'a@gmail.com')
      event = Event.create(name: 'test', desc: 'test', date: DateTime.now, location: 'test', creator_id: user.id,
                           event_privacy: 'public', display_privacy: 'public', attendee_privacy: 'public')
      @user_event_permission = UserEventPermission.create(user_id: user.id, event_id: event.id,
                                                          permission_type: 'attend')
      @second_user_event_permission = UserEventPermission.new(user_id: user.id, event_id: event.id)
    end
    context 'when creating the first user_event permission' do
      it { expect(@user_event_permission.errors).to be_empty }
      it { expect(@user_event_permission).not_to be_new_record }
    end

    context 'when creating a second user_event permission with the same user_id and event_id' do
      context 'when permission_type is different' do
        it do
          @second_user_event_permission.permission_type = 'moderate'
          expect(@second_user_event_permission.save).to be true
        end

        context 'when first permission is attend and second is accept_invite' do
          it do
            @second_user_event_permission.permission_type = 'accept_invite'
            expect(@second_user_event_permission.save).to be false
          end
        end

        context 'when first permission is accept_invite and second is attend' do
          it do
            @user_event_permission.update(permission_type: 'accept_invite')
            @second_user_event_permission.permission_type = 'attend'
            expect(@second_user_event_permission.save).to be false
          end
        end
      end

      context 'when permission_type is the same' do
        it do
          @second_user_event_permission.permission_type = 'attend'
          expect(@second_user_event_permission.save).to be false
        end
      end
    end
  end

  describe '#generate_permission_status' do
    before(:each) do
      @test_perm = test_perm
      allow(@test_perm).to receive(:user).and_return(mock_user)
      allow(@test_perm).to receive(:event).and_return(mock_event)
    end
    describe 'action is create' do
      let(:action) { :create }
      it 'should return :alert if errors not empty' do
        allow(@test_perm).to receive(:errors).and_return([1])
        expect(@test_perm.generate_permission_status(action)).to eq(:alert)
      end
      it 'should return UserEventPermission if errors empty' do
        allow(@test_perm).to receive(:errors).and_return([])
        allow(@test_perm).to receive(:save).and_return(true)
        expect(@test_perm.generate_permission_status(action)).to eq(:notice)
      end
      it 'should call save on the UserEventPermission' do
        allow(@test_perm).to receive(:errors).and_return([])
        expect(@test_perm).to receive(:save)
        @test_perm.generate_permission_status(action)
      end
    end
    describe 'action is destroy' do
      let(:action) { :destroy }
      it 'should return :alert if errors not empty' do
        allow(@test_perm).to receive(:errors).and_return([1])
        expect(@test_perm.generate_permission_status(action)).to eq(:alert)
      end
      it 'should return :notice if errors empty' do
        allow(@test_perm).to receive(:errors).and_return([])
        allow(@test_perm).to receive(:destroy).and_return(true)
        expect(@test_perm.generate_permission_status(action)).to eq(:notice)
      end
      it 'should call destroy on the UserEventPermission' do
        allow(@test_perm).to receive(:errors).and_return([])
        expect(@test_perm).to receive(:destroy)
        @test_perm.generate_permission_status(action)
      end
    end
    describe 'action is not create or destroy' do
      let(:action) { :update }
      it do
        expect { @test_perm.generate_permission_status(action) }
          .to raise_error RuntimeError, 'Invalid permission status'
      end
    end
  end

  # test for validating identifier in a params object
  describe '#self.validate_identifier' do
    context 'when identifier is missing' do
      it do
        test_params = ActionController::Parameters.new(
          user_id: 1, event_id: 1
        )
        expect do
          UserEventPermission.validate_identifier(test_params)
        end.to raise_error ActionController::ParameterMissing
      end
    end
    context 'when identifier is present' do
      before(:each) do
        @test_params = ActionController::Parameters.new(
          user_id: 1, event_id: 1, identifier: test_identifier
        )
      end
      context 'when only 1 identifier is present' do
        context 'user_id' do
          let(:test_identifier) { { 'user_id' => 1 } }
          it { expect(UserEventPermission.validate_identifier(@test_params).to_h).to eq(test_identifier) }
        end
        context 'email' do
          let(:test_identifier) { { 'email' => 1 } }
          it { expect(UserEventPermission.validate_identifier(@test_params).to_h).to eq(test_identifier) }
        end
      end
      context 'when multiple identifiers are present' do
        let(:test_identifier) { { user_id: 1, email: 1 } }
        it do
          expect { UserEventPermission.validate_identifier(@test_params) }.to raise_error 'Invalid identifier'
        end
      end
    end
  end

  # test function for finding the identifier id
  # assumes that given params are a hash
  # returns user_id if only user_id is present
  # calls find_by on User if only email is present
  # raises error if both user_id and email are present or neither is present
  describe '#self.identifier_id' do
    context 'when only user_id is present' do
      it do
        test_params = ActionController::Parameters.new(user_id: 1)
        expect(UserEventPermission.identifier_id(test_params)).to eq(1)
      end
    end
    context 'when only email is present' do
      it do
        test_params = ActionController::Parameters.new(email: 1)
        allow(User).to receive(:find_by).and_return(instance_double(User, id: 1))
        expect(UserEventPermission.identifier_id(test_params)).to eq(1)
      end
    end
    context 'when both user_id and email are present' do
      it do
        test_params = ActionController::Parameters.new(user_id: 1, email: 1)
        expect do
          UserEventPermission.identifier_id(test_params)
        end.to raise_error RuntimeError
      end
    end
    context 'when neither user_id nor email is present' do
      it do
        test_params = ActionController::Parameters.new
        expect { UserEventPermission.identifier_id(test_params) }.to raise_error RuntimeError
      end
    end
  end

  # test invite target id
  describe '#self.invite_target_id' do
    context 'when identifier is not present' do
      it 'return current_user_id' do
        test_params = ActionController::Parameters.new
        current_user_id = 1
        expect(UserEventPermission.invite_target_id(test_params, current_user_id)).to eq(current_user_id)
      end
    end
    context 'when identifier is present' do
      before(:each) do
        @test_params = ActionController::Parameters.new(identifier: 1)
        allow(UserEventPermission).to receive(:validate_identifier).and_return(nil)
        allow(UserEventPermission).to receive(:identifier_id).and_return('hello')
      end
      it 'call validate_identifier and identifier_id' do
        expect(UserEventPermission).to receive(:identifier_id).with(nil)
        UserEventPermission.invite_target_id(@test_params, 1)
      end
      it 'call identifier_id' do
        expect(UserEventPermission).to receive(:validate_identifier).with(@test_params)
        UserEventPermission.invite_target_id(@test_params, 1)
      end

      it 'return identifier_id' do
        expect(UserEventPermission.invite_target_id(@test_params, 1)).to eq('hello')
      end
    end
  end

  # generate permission response
  # a lack of perms should be a in errors
  # input:
  # - symbol action (:create, :destroy)
  # if instance of permission is valid return sucess response with correct action verb
  # if valid is false and has errors then return errors
  # not sure if can be invalid and have no errors but what if
  # raise error if neither
  describe '#self.generate_permission_response' do
    before(:each) do
      @test_perm = test_perm
      allow(@test_perm).to receive(:errors).and_return(errors)
    end
    context 'when valid is true' do
      let(:valid) { true }
      let(:errors) { "doesn't matter" }
      it { expect(@test_perm.generate_permission_response(:create, valid)).to include 'Success' }
    end
    context 'when valid is false' do
      context 'and errors is not empty' do
        let(:valid) { false }
        let(:errors) { double('Errors', empty?: false, full_messages: ['bad']) }
        it { expect(@test_perm.generate_permission_response(:create, valid)).to eq('bad') }
      end
      context 'and errors is empty' do
        let(:valid) { false }
        let(:errors) { double('Errors', empty?: true) }
        it do
          expect { @test_perm.generate_permission_response(:create, valid) }
            .to raise_error RuntimeError, 'Invalid permission response'
        end
      end
    end
  end

  # validate given user has permissions to perform action on perm instance
  # input: curr_user, action (:create, :destroy)
  # obtain permissions current user has on perm instance
  # obtain required permissions for action and permission type

  # make sure to account for current_user being nil
  describe '#self.validate_permission' do
    let(:mock_event) { instance_double(Event, required_perms_for_action: req_perms) }
    let(:req_perms) { double('Perm', call: nil) }
    before(:each) do
      @test_perm = test_perm
      allow(@test_perm).to receive(:event).and_return(mock_event)
      allow(@test_perm).to receive(:user).and_return(mock_user)
      allow(@test_perm).to receive(:validate_held_vs_req).and_return('')
    end
    it do
      allow(User).to receive(:held_event_perms)
      expect(User).to receive(:held_event_perms).with('fake_user_id', nil)
      @test_perm.validate_permission('fake_user_id', 'fake_action')
    end
    context "when current user has same id as perm's user" do
      it do
        some_array = []
        allow(User).to receive(:held_event_perms).and_return(some_array)
        expect { @test_perm.validate_permission(mock_user, 'fake_action') }
          .to change { some_array.size }.from(0).to(1)
      end
    end
    context 'when current user has different id as perm\'s user' do
      it do
        some_array = []
        allow(User).to receive(:held_event_perms).and_return(some_array)
        expect { @test_perm.validate_permission('different', 'fake_action') }
          .to_not(change { some_array.size })
      end
    end
    it do
      allow(User).to receive(:held_event_perms)
      allow(@test_perm).to receive(:permission_type).and_return('fake_type')
      expect(mock_event).to receive(:required_perms_for_action).with(perm_type: 'fake_type', action: 'fake_action')
      @test_perm.validate_permission('fake_user_id', 'fake_action')
    end
    it do
      allow(User).to receive(:held_event_perms).and_return([])
      allow(@test_perm).to receive(:permission_type).and_return('fake_type')
      expect(@test_perm).to receive(:validate_held_vs_req).with([], req_perms)
      @test_perm.validate_permission('fake_user_id', 'fake_action')
    end
  end

  # validate held permissions are a subset of a required permission array
  # input: held_perms, array of arrays of req_perms
  # assumption: req perms is never nil
  # if held perms match any of the req perm arrays in full then valid
  # invalid otherwise
  describe '#self.validate_held_vs_req' do
    before(:each) do
      @test_perm = test_perm
      allow(@test_perm).to receive(:errors).and_return(double('error', add: nil))
    end
    context 'when held perms is nil' do
      let(:held_perms) { nil }
      let(:req_perms) { [['fake_perm']] }
      it { expect(@test_perm.validate_held_vs_req(held_perms, req_perms)).to be false }
      it do
        expect(@test_perm.errors).to receive(:add)
          .with(:base, 'You do not have permission to perform this action.')
        @test_perm.validate_held_vs_req(held_perms, req_perms)
      end
    end
    context 'when held perms is empty' do
      context 'req perms is empty' do
        let(:held_perms) { [] }
        let(:req_perms) { [[]] }
        it { expect(@test_perm.validate_held_vs_req(held_perms, req_perms)).to be true }
      end
      context 'req perms is not empty' do
        let(:held_perms) { [] }
        let(:req_perms) { [['fake_perm']] }
        it { expect(@test_perm.validate_held_vs_req(held_perms, req_perms)).to be false }
        it do
          expect(@test_perm.errors).to receive(:add)
            .with(:base, 'You do not have permission to perform this action.')
          @test_perm.validate_held_vs_req(held_perms, req_perms)
        end
      end
    end
    context 'when only 1 held perm' do
      let(:held_perms) { ['fake_perm'] }
      context 'req perms is empty' do
        let(:req_perms) { [[]] }
        it { expect(@test_perm.validate_held_vs_req(held_perms, req_perms)).to be true }
      end
      context 'req perms is not empty' do
        it { expect(@test_perm.validate_held_vs_req(held_perms, [['fake_perm']])).to be true }
        it { expect(@test_perm.validate_held_vs_req(held_perms, [%w[fake_perm fake]])).to be false }
        it { expect(@test_perm.validate_held_vs_req(held_perms, [['fake_perm'], %w[fake_perm fake]])).to be true }
      end
    end
    context 'when multiple held perms' do
      let(:held_perms) { %w[fake_perm fake_perm2] }
      context 'req perms is empty' do
        it { expect(@test_perm.validate_held_vs_req(held_perms, [[]])).to be true }
      end
      context 'one req perm' do
        it { expect(@test_perm.validate_held_vs_req(held_perms, [['fake_perm']])).to be true }
        it { expect(@test_perm.validate_held_vs_req(held_perms, [['fake_perm2']])).to be true }
        it { expect(@test_perm.validate_held_vs_req(held_perms, [%w[fake]])).to be false }
      end
      context 'multiple req perms' do
        it { expect(@test_perm.validate_held_vs_req(held_perms, [%w[fake_perm fake_perm2]])).to be true }
        it { expect(@test_perm.validate_held_vs_req(held_perms, [%w[fake_perm2 fake_perm]])).to be true }
        it { expect(@test_perm.validate_held_vs_req(held_perms, [['test'], %w[fake_perm fake_perm2]])).to be true }
        it { expect(@test_perm.validate_held_vs_req(held_perms, [%w[fake_perm2 fake_perm], ['test']])).to be true }
        it { expect(@test_perm.validate_held_vs_req(held_perms, [%w[fake_perm fake_perm2 fake]])).to be false }
      end
    end
  end

  describe '#execute_action_by_tar' do
    let(:valid) { true }
    before(:each) do
      @test_perm = test_perm
      allow(@test_perm).to receive(:validate_permission).and_return(valid)
      allow(@test_perm).to receive(:valid?).and_return(valid)
      allow(@test_perm).to receive(:generate_permission_response).and_return('fake_response')
      allow(@test_perm).to receive(:generate_permission_status).and_return('fake_status')
    end
    context 'when valid' do
      let(:valid) { true }
      it do
        expect(@test_perm).to receive(:validate_permission).with('fake_user_id', 'fake_action')
        @test_perm.execute_action_by_tar('fake_action', 'fake_user_id')
      end
    end
    context 'when invalid' do
      let(:valid) { false }
      it do
        expect(@test_perm).to receive(:valid?)
        @test_perm.execute_action_by_tar('fake_action', 'fake_user_id')
      end
      it do
        expect(@test_perm).to_not receive(:validate_permission)
        @test_perm.execute_action_by_tar('fake_action', 'fake_user_id')
      end
    end

    it do
      expect(@test_perm).to receive(:generate_permission_response).with('fake_action', valid)
      @test_perm.execute_action_by_tar('fake_action', 'fake_user_id')
    end
    it do
      expect(@test_perm).to receive(:generate_permission_status).with('fake_action')
      @test_perm.execute_action_by_tar('fake_action', 'fake_user_id')
    end
    it { expect(@test_perm.execute_action_by_tar('', '')).to eq(%w[fake_status fake_response]) }
  end

  describe '#self.destroy_permission' do
    describe 'calls the correct methods' do
      let(:params) { { event_id: 'some_id', permission_type: 'some_type' } }
      let(:nil_val) { false }
      let(:tar_id) { 'some_tar_id' }
      let(:curr_user) { double('user', id: 'some_user_id') }
      before(:each) do
        allow(UserEventPermission).to receive(:invite_target_id).and_return(tar_id)
        allow(UserEventPermission).to receive(:find_by)
          .and_return(double('pend_perm', nil?: nil_val, execute_action_by_tar: 'test'))
      end
      it do
        expect(UserEventPermission).to receive(:invite_target_id).with(params, curr_user.id)
        UserEventPermission.destroy_permission(params, curr_user)
      end
      it do
        expect(UserEventPermission).to receive(:find_by).with(event_id: 'some_id', permission_type: 'some_type',
                                                              user_id: tar_id)
        UserEventPermission.destroy_permission(params, curr_user)
      end
      it do
        perm = UserEventPermission.new
        allow(UserEventPermission).to receive(:find_by).and_return(perm)
        expect(perm).to receive(:execute_action_by_tar).with(:destroy, curr_user)
        UserEventPermission.destroy_permission(params, curr_user)
      end
      context 'when find_by does not find a permission' do
        let(:nil_val) { true }
        it do
          expect(UserEventPermission.destroy_permission(params, curr_user))
            .to eq([:alert, 'Permission does not exist.'])
        end
      end
    end
  end
  describe '#self.create_permission' do
    describe 'calls the correct methods' do
      let(:params) { { event_id: 'some_id', permission_type: 'some_type' } }
      let(:tar_id) { 'some_tar_id' }
      let(:curr_user) { double('user', id: 'some_user_id') }
      before(:each) do
        allow(UserEventPermission).to receive(:invite_target_id).and_return(tar_id)
        allow(UserEventPermission).to receive(:new)
          .and_return(double('perm', execute_action_by_tar: 'test'))
      end
      it do
        expect(UserEventPermission).to receive(:invite_target_id).with(params, curr_user.id)
        UserEventPermission.create_permission(params, curr_user)
      end
      it do
        expect(UserEventPermission).to receive(:new)
          .with(event_id: 'some_id', permission_type: 'some_type', user_id: tar_id)
        UserEventPermission.create_permission(params, curr_user)
      end
      it do
        perm = UserEventPermission.new
        allow(UserEventPermission).to receive(:new).and_return(perm)
        expect(perm).to receive(:execute_action_by_tar).with(:create, curr_user)
        UserEventPermission.create_permission(params, curr_user)
      end
    end
  end

  describe 'Integration Tests' do
    let(:priv_set) { 'public' }
    let(:event_perms) { [] }
    let(:nil_val) { false }
    let(:perm_type) { 'attend' }
    let(:curr_id) { test_user.id }
    let(:params_user) { { name: 'test', username: 'tester', password: 'tester', email: 'abc@gmail.com' } }
    let(:params_event) do
      { name: 'test', desc: 'te', date: DateTime.now, location: 'test', creator_id: test_user.id,
        event_privacy: priv_set, display_privacy: priv_set, attendee_privacy: priv_set }
    end
    let(:test_user) { User.create(params_user) }
    let(:test_event) { Event.create(params_event) }
    let(:current_user) { instance_double(User, id: curr_id, nil?: nil_val) }
    let(:params) do
      ActionController::Parameters.new({ event_id: test_event.id, permission_type: perm_type,
                                         identifier: { user_id: test_user.id } })
    end
    describe 'create_permission' do
      before(:each) do
        @user = test_user
        @event = test_event
        UserEventPermission.destroy_all
        allow(User).to receive(:held_event_perms).and_return(event_perms)
      end
      context 'no perms' do
        it do
          expect { UserEventPermission.create_permission(params, current_user) }
            .to_not(change { UserEventPermission.first })
        end
      end
      context 'perms: current_user' do
        let(:event_perms) { ['current_user'] }
        it do
          expect { UserEventPermission.create_permission(params, current_user) }
            .to change { UserEventPermission.first&.permission_type }.from(nil).to(perm_type)
        end
        it do
          UserEventPermission.create_permission(params, current_user)
          expect(UserEventPermission.create_permission(params, current_user)[0])
            .to eq(:alert)
        end
        context 'pirvate event' do
          let(:priv_set) { 'private' }
          it do
            expect(UserEventPermission.create_permission(params, current_user)[0])
              .to eq(:alert)
          end
          context 'perms: current_user, accept_invite' do
            let(:event_perms) { %w[current_user accept_invite] }
            it do
              expect { UserEventPermission.create_permission(params, current_user) }
                .to change { UserEventPermission.first&.permission_type }.from(nil).to(perm_type)
            end
          end
        end
      end
      context 'perms: owner' do
        let(:event_perms) { ['owner'] }
        it do
          expect(UserEventPermission.create_permission(params, current_user)[0])
            .to eq(:alert)
        end
      end
      context 'perms: current_user, owner' do
        let(:event_perms) { %w[current_user owner] }
        it do
          expect { UserEventPermission.create_permission(params, current_user) }
            .to change { UserEventPermission.first&.permission_type }.from(nil).to(perm_type)
        end
        it do
          UserEventPermission.create_permission(params, current_user)
          expect(UserEventPermission.create_permission(params, current_user)[0])
            .to eq(:alert)
        end
      end
      context 'when creating a moderator permission' do
        let(:perm_type) { 'moderate' }
        context 'when the user has no perms' do
          it do
            expect { UserEventPermission.create_permission(params, current_user) }
              .to_not(change { UserEventPermission.first&.permission_type })
          end
        end
        context 'when the user has a perm' do
          let(:event_perms) { ['owner'] }
          it do
            expect { UserEventPermission.create_permission(params, current_user) }
              .to change { UserEventPermission.first&.permission_type }.from(nil).to(perm_type)
          end
        end
      end
    end
    describe 'destroy_permission' do
      before(:each) do
        @user = test_user
        @event = test_event
        UserEventPermission.destroy_all
        allow(User).to receive(:held_event_perms).and_return(event_perms)
        @test_perm = UserEventPermission.create(event_id: @event.id,
                                                user_id: @user.id, permission_type: perm_type)
      end
      context 'no perms' do
        it do
          expect { UserEventPermission.destroy_permission(params, current_user) }
            .to_not(change { UserEventPermission.first })
        end
      end
      context 'perms: current_user' do
        let(:event_perms) { ['current_user'] }
        it do
          expect { UserEventPermission.destroy_permission(params, current_user) }
            .to change { UserEventPermission.first&.permission_type }.from(perm_type).to(nil)
        end
        it do
          UserEventPermission.destroy_permission(params, current_user)
          expect(UserEventPermission.destroy_permission(params, current_user)[0])
            .to eq(:alert)
        end
      end
      context 'perms: moderate' do
        let(:event_perms) { ['moderate'] }
        it do
          expect { UserEventPermission.destroy_permission(params, current_user) }
            .to change { UserEventPermission.first&.permission_type }.from(perm_type).to(nil)
        end
        it do
          UserEventPermission.destroy_permission(params, current_user)
          expect(UserEventPermission.destroy_permission(params, current_user)[0])
            .to eq(:alert)
        end
      end
      context 'perms: ATTEND' do
        let(:event_perms) { ['attend'] }

        it do
          expect(UserEventPermission.destroy_permission(params, current_user)[0])
            .to eq(:alert)
        end
      end
    end
  end
end
