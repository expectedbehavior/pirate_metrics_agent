require 'rack'

class TestServer
  attr_accessor :host, :port, :connect_count, :metrics, :last_api_key

  def initialize(options={})
    default_options = {
      :listen => true,
      :authenticate => true,
      :response => true,
    }
    @options = default_options.merge(options)

    @connect_count = 0
    @connections = []
    @metrics = Hash.new{ |h,k| h[k] = Array.new}
    @last_api_key = ""
    @host = 'http://localhost'
    @main_thread = nil
    @response = options[:response]
    listen if @options[:listen]
  end

  def listen
    @port ||= 10001
    @server = TCPServer.new(@port)
    @main_thread = Thread.new do
      begin
        loop do
          begin
            client = @server.accept
            @connections << client
            @connect_count += 1

            while command = client.readline
              if command.start_with? 'POST'
                metric = command[/v1\/(.*)\sHTTP/, 1]
              end
              if command.start_with? "Content-Length: "
                content_length = command.gsub("Content-Length: ", "").to_i
              end
              break if command == "\r\n"
            end
            content = client.read(content_length)
            payload = Rack::Utils.parse_nested_query(content)
            @metrics[metric] += payload["data"]
            @last_api_key = payload[:api_key]

            headers = ["HTTP/1.1 200 OK"].join("\r\n")
            client.puts headers
            client.close
          rescue Exception => e
            puts "Error in test server: #{e.inspect}"
          end
        end
      end
    end

  rescue Errno::EADDRINUSE => err
    puts "#{err.inspect} failed to get port #{@port}"
    puts err.message
    @port += 1
    retry
  end

  def host_and_port
    "#{host}:#{port}"
  end

  def stop
    @stopping = true
    disconnect_all
    @main_thread.kill if @main_thread
    @main_thread = nil
    begin
      @server.close if @server
    rescue Exception => e
    end
  end

  def disconnect_all
    @connections.each { |c|
      c.close rescue false
    }
    @connections = []
  end

  def fresh_agent(options = { })
    PirateMetrics::Agent.new('test_token', { :host => host, :port => port, :enabled => true}.merge(options))
  end

  [:acquisitions, :activations, :retentions, :referrals, :revenues].each do |metric|
    define_method metric do
      @metrics[metric.to_s]
    end
  end
end
