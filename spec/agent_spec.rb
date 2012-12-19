require 'spec_helper'

def wait
  sleep 0.1 # FIXME: hack
end

PirateMetrics::Agent.logger.level = Logger::FATAL
describe PirateMetrics::Agent, "disabled" do
  before do
    @server = TestServer.new
    @agent = @server.fresh_agent(:enabled => false)
  end

  after do
    @agent.stop
    @agent = nil
    @server.stop
  end

  it "should not connect to the server" do
    wait
    @server.connect_count.should == 0
  end

  it "should not connect to the server after receiving a metric" do
    wait
    @agent.acquisition({:email => 'test@example.com'})
    wait
    @server.connect_count.should == 0
  end

  it "should no op on flush without reconnect" do
    1.upto(100) { |i| @agent.acquisition({:email => "test#{i}@example.com"}) }
    @agent.flush(false)
    wait
    @server.metrics.should be_empty
  end

  it "should no op on flush with reconnect" do
    1.upto(100) { |i| @agent.acquisition({:email => "test#{i}@example.com"}) }
    @agent.flush(true)
    wait
    @server.metrics.should be_empty
  end

  it "should no op on an empty flush" do
    @agent.flush(true)
    wait
    @server.metrics.should be_empty
  end
end

describe PirateMetrics::Agent, "enabled" do
  before do
    @server = TestServer.new
    @agent = @server.fresh_agent
  end

  after do
    @agent.stop
    @agent = nil
    @server.stop
  end

  it "should send an api key" do
    @agent.acquisition({:email => "test@example.com"})
    wait
    @server.last_api_key == "test_token"
  end
end

describe PirateMetrics::Agent, "acquisitions" do
  before do
    @server = TestServer.new
    @agent = @server.fresh_agent
  end

  after do
    @agent.stop
    @agent = nil
    @server.stop
  end

  it "should not connect to the server" do
    wait
    @server.connect_count.should == 0
  end

  it "should report an acquisition using the hash form" do
    @agent.acquisition({:email => "test@example.com"})
    wait
    @server.acquisitions.last.should == { "email" => "test@example.com"}
  end

  it "should report an acquisition using the array form" do
    @agent.acquisition([{:email => "test1@example.com"}, { :email => "test2@example.com"}])
    wait
    @server.acquisitions.first.should == { "email" => "test1@example.com"}
    @server.acquisitions.last.should == { "email" => "test2@example.com"}
  end

  it "should be able to report acquisitions synchronously" do
    @agent.acquisition!({:email => "test@example.com"})
    wait
    @server.acquisitions.last.should == { "email" => "test@example.com"}
  end
end

describe PirateMetrics::Agent, "activations" do
  before do
    @server = TestServer.new
    @agent = @server.fresh_agent
  end

  after do
    @agent.stop
    @agent = nil
    @server.stop
  end

  it "should not connect to the server" do
    wait
    @server.connect_count.should == 0
  end

  it "should report an activation using the hash form" do
    @agent.activation({:email => "test@example.com"})
    wait
    @server.activations.last.should == { "email" => "test@example.com"}
  end

  it "should report an activation using the array form" do
    @agent.activation([{:email => "test1@example.com"}, { :email => "test2@example.com"}])
    wait
    @server.activations.first.should == { "email" => "test1@example.com"}
    @server.activations.last.should == { "email" => "test2@example.com"}
  end

  it "should be able to report activations synchronously" do
    @agent.activation!({:email => "test@example.com"})
    wait
    @server.activations.last.should == { "email" => "test@example.com"}
  end
end

describe PirateMetrics::Agent, "retentions" do
  before do
    @server = TestServer.new
    @agent = @server.fresh_agent
  end

  after do
    @agent.stop
    @agent = nil
    @server.stop
  end

  it "should not connect to the server" do
    wait
    @server.connect_count.should == 0
  end

  it "should report an retention using the hash form" do
    @agent.retention({:email => "test@example.com"})
    wait
    @server.retentions.last.should == { "email" => "test@example.com"}
  end

  it "should report an retention using the array form" do
    @agent.retention([{:email => "test1@example.com"}, { :email => "test2@example.com"}])
    wait
    @server.retentions.first.should == { "email" => "test1@example.com"}
    @server.retentions.last.should == { "email" => "test2@example.com"}
  end

  it "should be able to report retentions synchronously" do
    @agent.retention!({:email => "test@example.com"})
    wait
    @server.retentions.last.should == { "email" => "test@example.com"}
  end
end

describe PirateMetrics::Agent, "revenues" do
  before do
    @server = TestServer.new
    @agent = @server.fresh_agent
  end

  after do
    @agent.stop
    @agent = nil
    @server.stop
  end

  it "should not connect to the server" do
    wait
    @server.connect_count.should == 0
  end

  it "should report an revenue using the hash form" do
    @agent.revenue({:email => "test@example.com", :amount_in_cents => "1000"})
    wait
    @server.revenues.last.should == { "email" => "test@example.com", "amount_in_cents" => "1000"}
  end

  it "should report an revenue using the array form" do
    @agent.revenue([{:email => "test1@example.com", :amount_in_cents => "1000"}, { :email => "test2@example.com", :amount_in_cents => "2000"}])
    wait
    @server.revenues.first.should == { "email" => "test1@example.com", "amount_in_cents" => "1000"}
    @server.revenues.last.should == { "email" => "test2@example.com", "amount_in_cents" => "2000"}
  end

  it "should be able to report revenues synchronously" do
    @agent.revenue!({:email => "test@example.com", :amount_in_cents => "1000"})
    wait
    @server.revenues.last.should == { "email" => "test@example.com", "amount_in_cents" => "1000"}
  end
end


describe PirateMetrics::Agent, "referrals" do
  before do
    @server = TestServer.new
    @agent = @server.fresh_agent
  end

  after do
    @agent.stop
    @agent = nil
    @server.stop
  end

  it "should not connect to the server" do
    wait
    @server.connect_count.should == 0
  end

  it "should report an referral using the hash form" do
    @agent.referral({:customer_email => "test@example.com", :referree_email => "ref@example.com"})
    wait
    @server.referrals.last.should == { "customer_email" => "test@example.com", "referree_email" => "ref@example.com"}
  end

  it "should report an referral using the array form" do
    @agent.referral([{:customer_email => "test1@example.com", :referree_email => "ref@example.com"}, { :customer_email => "test2@example.com", :referree_email => "ref2@example.com"}])
    wait
    @server.referrals.first.should == { "customer_email" => "test1@example.com", "referree_email" => "ref@example.com"}
    @server.referrals.last.should == { "customer_email" => "test2@example.com", "referree_email" => "ref2@example.com"}
  end

  it "should be able to report referrals synchronously" do
    @agent.referral!({:customer_email => "test@example.com", :referree_email => "ref@example.com"})
    wait
    @server.referrals.last.should == { "customer_email" => "test@example.com", "referree_email" => "ref@example.com"}
  end
end

describe PirateMetrics::Agent, "agent queueing, synchronicity, reliability" do
  before do
    @server = TestServer.new
    @agent = @server.fresh_agent
  end

  after do
    @agent.stop
    @agent = nil
    @server.stop
  end

  it "should discard data that overflows the buffer" do
    with_constants('PirateMetrics::Agent::MAX_BUFFER' => 3) do
      5.times do |i|
        @agent.acquisition({ :email => "test#{i}@example.com"})
      end
      wait
      @server.acquisitions.should include({ "email" => "test0@example.com"})
      @server.acquisitions.should include({ "email" => "test1@example.com"})
      @server.acquisitions.should include({ "email" => "test2@example.com"})
      @server.acquisitions.should_not include({ "email" => "test3@example.com"})
      @server.acquisitions.should_not include({ "email" => "test4@example.com"})
    end
  end

  it "should send all data in synchronous mode" do
    with_constants('PirateMetrics::Agent::MAX_BUFFER' => 3) do
      5.times do |i|
        @agent.acquisition!({ :email => "test#{i}@example.com"})
      end
      @agent.instance_variable_get(:@queue).size.should == 0
      wait
      @server.acquisitions.should include({ "email" => "test0@example.com"})
      @server.acquisitions.should include({ "email" => "test1@example.com"})
      @server.acquisitions.should include({ "email" => "test2@example.com"})
      @server.acquisitions.should include({ "email" => "test3@example.com"})
      @server.acquisitions.should include({ "email" => "test4@example.com"})
    end
  end

  it "should send all data in synchronous mode (agent-level)" do
    with_constants('PirateMetrics::Agent::MAX_BUFFER' => 3) do
      @agent.synchronous = true
      5.times do |i|
        @agent.acquisition({ :email => "test#{i}@example.com"})
      end
      @agent.instance_variable_get(:@queue).size.should == 0
      wait
      @server.acquisitions.should include({ "email" => "test0@example.com"})
      @server.acquisitions.should include({ "email" => "test1@example.com"})
      @server.acquisitions.should include({ "email" => "test2@example.com"})
      @server.acquisitions.should include({ "email" => "test3@example.com"})
      @server.acquisitions.should include({ "email" => "test4@example.com"})
    end
  end

  it "should automatically reconnect when forked" do
    wait
    @agent.acquisition({ :email => "test0@example.com"})
    fork do
      @agent.acquisition({ :email => "test1@example.com"})
    end
    wait
    @agent.acquisition({ :email => "test2@example.com"})
    wait
    @server.acquisitions.should include({ "email" => "test0@example.com"})
    @server.acquisitions.should include({ "email" => "test1@example.com"})
    @server.acquisitions.should include({ "email" => "test2@example.com"})
  end

  it "should never let an exception reach the user" do
    @agent.stub!(:send_metric).and_raise(Exception.new("Test Exception"))
    @agent.acquisition({ :email => "test@example.com"}).should be_nil
    wait
    @agent.activation({ :email => "test@example.com"}).should be_nil
    wait
  end

  it "should allow outgoing metrics to be stopped" do
    tm = Time.now
    @agent.acquisition({ :email => "testbad@example.com"})
    @agent.stop
    wait
    @agent.acquisition({ :email => "testgood@example.com"})
    wait
    @server.acquisitions.should_not include({ "email" => "testbad@example.com"})
    @server.acquisitions.should include({ "email" => "testgood@example.com"})
  end

  it "should allow flushing pending values to the server" do
    1.upto(100) { |i| @agent.acquisition({ :email => "test#{i}@example.com"}) }
    @agent.instance_variable_get(:@queue).size.should >= 100
    @agent.flush
    @agent.instance_variable_get(:@queue).size.should ==  0
    wait
    @server.acquisitions.size.should == 100
  end

  it "should no op on an empty flush" do
    @agent.flush(true)
    wait
    @server.connect_count.should == 0
  end
end

describe PirateMetrics::Agent, "connection problems" do
  after do
    @agent.stop
    @server.stop
  end

  it "should automatically reconnect on disconnect" do
    @server = TestServer.new
    @agent = @server.fresh_agent
    @agent.acquisition({ :email => "test1@example.com"})
    wait
    @server.disconnect_all
    wait
    @agent.acquisition({ :email => "test2@example.com"})
    wait
    @server.connect_count.should == 2
    @server.acquisitions.last.should == { "email" => "test2@example.com"}
  end

  it "should buffer commands when server is down" do
    @server = TestServer.new(:listen => false)
    @agent = @server.fresh_agent
    wait
    @agent.retention({ :email => "test@example.com"})
    wait
    @agent.queue.size.should == 1
  end

  it "should send commands in a short-lived process" do
    @server = TestServer.new
    @agent = @server.fresh_agent
    if pid = fork { @agent.acquisition({ :email => "test@example.com"}) }
      Process.wait(pid)
      @server.acquisitions.size.should == 1
    end
  end

  it "should send commands in a process that bypasses at_exit when using #cleanup" do
    @server = TestServer.new
    @agent = @server.fresh_agent
    if pid = fork do
        @agent.acquisition({ :email => "test1@example.com"})
        @agent.acquisition({ :email => "test2@example.com"})
        @agent.cleanup
        exit!
      end
      Process.wait(pid)
      @server.acquisitions.size.should == 2
    end
  end
end

describe PirateMetrics::Agent, "enabled with sync option" do
  before do
    @server = TestServer.new
    @agent = @server.fresh_agent({ :synchronous => true})
  end

  after do
    @agent.stop
    @server.stop
  end

  it "should send all data in synchronous mode" do
    with_constants('PirateMetrics::Agent::MAX_BUFFER' => 3) do
      5.times do |i|
        @agent.acquisition({ :email => "test#{i}@example.com"})
      end
      wait # let the server receive the commands
      @server.acquisitions.should include({ "email" => "test0@example.com"})
      @server.acquisitions.should include({ "email" => "test1@example.com"})
      @server.acquisitions.should include({ "email" => "test2@example.com"})
      @server.acquisitions.should include({ "email" => "test3@example.com"})
      @server.acquisitions.should include({ "email" => "test4@example.com"})
    end
  end
end

