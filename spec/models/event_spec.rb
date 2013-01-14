require 'spec_helper'

describe Event do  
  before do
    @event = create(:event)
    @user = create(:user)
  end

  it { should belong_to(:location) }
  it { should have_many(:volunteer_rsvps) }
  it { should have_many(:volunteers).through(:volunteer_rsvps) }
  it { should have_many(:event_organizers) }
  it { should have_many(:organizers).through(:event_organizers) }
  it { should have_many(:event_sessions) }

  it { should validate_presence_of(:title) }
  it "validates that there is at least one event session" do
    event = Event.new(title: "Foo")
    event.should_not be_valid

    event.event_sessions << EventSession.new(starts_at: Time.now, ends_at: 2.hours.from_now)
    event.should be_valid
  end

  describe "#volunteering?" do
    it "is true when a user is volunteering at an event" do
      VolunteerRsvp.create(event_id: @event.id, user_id: @user.id, attending: true)
      @event.volunteering?(@user).should == true
    end

    it "is false when a user is not volunteering at an event" do
      @event.volunteering?(@user).should == false
    end
  end

  describe "#rsvp_for_user" do
    it "should return the volunteer_rsvp for a user" do
      @event.rsvp_for_user(@user).should == @event.volunteer_rsvps.find_by_user_id(@user.id)
    end
  end

  describe ".upcoming" do
    before do
      @event_past = build(:event_with_no_sessions)
      @event_past.event_sessions << create(:event_session, starts_at: 4.weeks.ago, ends_at: 3.weeks.ago)
      @event_past.save!

      @event_future = build(:event_with_no_sessions)
      @event_future.event_sessions << create(:event_session, starts_at: 3.weeks.from_now, ends_at: 4.weeks.from_now)
      @event_future.save!

      @event_in_progress = build(:event_with_no_sessions)
      @event_in_progress.event_sessions << create(:event_session, starts_at: 2.days.ago, ends_at: 2.days.from_now)
      @event_in_progress.save!
    end
  
    it "includes events that haven't yet started" do
      Event.upcoming.should include(@event_future)
    end
  
    it "includes events in progress" do
      Event.upcoming.should include(@event_in_progress)
    end

    it "doesn't include events that have already ended" do
      Event.upcoming.should_not include(@event_past)
    end
  end
end