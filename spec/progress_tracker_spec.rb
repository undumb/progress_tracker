Bundler.require(:default, :development)

require 'rspec'
require 'mock_redis'
require 'progress_tracker'

# FAKE REDIS!
Progress::Tracker.redis = MockRedis.new

shared_examples "a ProgressTracker::Tracker instance" do
  let(:setter_base) { Progress::Tracker.new(:paired_thing) }
  let(:getter) { Progress::Tracker.new(:paired_thing) }

  it "remembers the current progress" do
    setter.progress 50
    expect(_result(getter, :progress)).to eql(50)
  end


  it "remembers the latest message" do
    msg = "So long, and thanks for all the fish."

    setter.status msg
    expect(_result(getter, :status)).to eql(msg)
  end


  it "remembers several things at once" do
    things = { progress: 42, message: "Share and enjoy." }
    setter.update things

    expect(getter[:_base]).to eql(things)
  end

  it "remembers arbitrary keys / values" do
    setter.update foo: "bar!"
    expect(getter[:_base]).to eql(foo: "bar!")
  end
end


describe Progress::Tracker do

  # make sure we're clearing out fake-redis after each test
  after(:each) do
    Progress::Tracker.redis.flushdb
  end

  # shortcut for accessing deep hash keys
  def _result(pt, field, key = :_default)
    pt.to_hash[key][field]
  end

  let(:pt) { Progress::Tracker.new(:derp) }

  it "must be initialized with at least a simple key" do
    expect { Progress::Tracker.new }.to raise_error
    expect { Progress::Tracker.new(:derp) }.not_to raise_error
  end


  it "can be initialized using a class / id compound key" do
    expect(Progress::Tracker.new(:thing, 100)).not_to raise_error
  end


  it "returns sane defaults" do
    expect(pt.to_hash).to eql({ _base: { progress: 0, message: "" } })
  end

  it "can track mutliple sub-objects" do
    pt.track :foo
    pt.track :bar, 100

    expect(pt.to_hash).to have_key(:foo)
    expect(pt.to_hash).to have_key(:bar_100)
  end


  context "when operating on the base object" do
    it_behaves_like "a ProgressTracker::Tracker instance" do
      let(:setter) { setter_base }
    end
  end


  context "when operating on a simple sub-object" do
    it_behaves_like "a ProgressTracker::Tracker instance" do
      before(:each) { setter_base.track :derp }
      let(:setter) { setter_base.derp }
    end
  end

  context "when tracking a compound-key sub-object" do
    it_behaves_like "a ProgressTracker::Tracker instance" do
      before(:each) { setter_base.track :derp, 100 }
      let(:setter) { setter_base.derp(100) }
    end
  end

  it "can go to json, too!"
end