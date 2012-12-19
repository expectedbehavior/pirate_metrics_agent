require 'pirate_metrics/version'
require 'pirate_metrics/system_timer'
require 'faraday'
require 'logger'
require 'thread'
require 'socket'


module PirateMetrics
  class Agent
    BACKOFF = 2.0
    MAX_RECONNECT_DELAY = 15
    MAX_BUFFER = 5000
    REPLY_TIMEOUT = 10
    CONNECT_TIMEOUT = 20
    EXIT_FLUSH_TIMEOUT = 5

    attr_accessor :host, :port, :synchronous, :queue
    attr_reader :connection, :enabled

    def self.logger=(l)
      @logger = l
    end

    def self.logger
      if !@logger
        @logger = Logger.new(STDERR)
        @logger.level = Logger::WARN
      end
      @logger
    end

    # Sets up a connection to the collector.
    #
    #  PirateMetrics::Agent.new(API_KEY)
    #  PirateMetrics::Agent.new(API_KEY, :collector => 'hostname:port')
    def initialize(api_key, options = {})
      # symbolize options keys
      options.replace(
        options.inject({}) { |m, (k, v)| m[(k.to_sym rescue k) || k] = v; m }
      )

      # defaults
      # host:        piratemetrics.com
      # port:        80
      # enabled:     true
      # synchronous: false
      @api_key         = api_key
      @host, @port     = options[:collector].to_s.split(':')
      @host            = options[:host] || 'https://piratemetrics.com'
      @port            = (options[:port] || 443).to_i
      @enabled         = options.has_key?(:enabled) ? !!options[:enabled] : true
      @synchronous     = !!options[:synchronous]
      @pid             = Process.pid
      @allow_reconnect = true

      setup_cleanup_at_exit if @enabled
    end

    # Store a customer metric
    #
    #  agent.acquisition!({ :email => 'test@example.com',
    #                       :occurred_at => user.created_at,
    #                       :level => 'Double Uranium'})
    [:acquisition, :activation, :retention, :revenue, :referral].each do |metric|
      define_method metric do |customer|
        begin
          payload = customer.is_a?(Array) ? customer : [customer]
          send_metric(metric, payload, @synchronous)
        rescue Exception => ex
          report_exception ex
          return nil
        end
      end
      define_method "#{metric}!" do |customer|
        begin
          payload = customer.is_a?(Array) ? customer : [customer]
          send_metric(metric, payload, true)
        rescue Exception => ex
          report_exception ex
          return nil
        end
      end
    end

    # Synchronously flush all pending metrics out to the server
    # By default will not try to reconnect to the server if a
    # connection failure happens during the flush, though you
    # may optionally override this behavior by passing true.
    #
    #  agent.flush
    def flush(allow_reconnect = false)
      queue_metric('flush', nil, {
        :synchronous => true,
        :allow_reconnect => allow_reconnect
      }) if running?
    end

    def enabled?
      @enabled
    end

    def logger=(logger)
      @logger = logger
    end

    def logger
      @logger || self.class.logger
    end

    # Stopping the agent will immediately stop all communication
    # to PirateMetrics.  If you call this and submit another metric,
    # the agent will start again.
    #
    # Calling stop will cause all metrics waiting to be sent to be
    # discarded.  Don't call it unless you are expecting this behavior.
    #
    # agent.stop
    #
    def stop
      if @thread
        @thread.kill
        @thread = nil
      end
    end

    # Called when a process is exiting to give it some extra time to
    # push events to the service. An at_exit handler is automatically
    # registered for this method, but can be called manually in cases
    # where at_exit is bypassed like Resque workers.
    def cleanup
      if running?
        logger.info "Cleaning up agent, queue size: #{@queue.size}, thread running: #{@thread.alive?}"
        @allow_reconnect = false
        queue_metric('exit')
        begin
          with_timeout(EXIT_FLUSH_TIMEOUT) { @thread.join }
        rescue Timeout::Error
          if @queue.size > 0
            logger.error "Timed out working agent thread on exit, dropping #{@queue.size} metrics"
          else
            logger.error "Timed out PirateMetrics Agent, exiting"
          end
        end
      end
    end

    private

    def with_timeout(time, &block)
      PirateMetricsTimeout.timeout(time) { yield }
    end

    def report_exception(e)
      logger.error "Exception occurred: #{e.message}\n#{e.backtrace.join("\n")}"
    end

    def send_metric(metric, payload, synchronous = false)
      if enabled?
        start_connection_worker if !running?
        if @queue.size < MAX_BUFFER
          @queue_full_warning = false
          logger.debug "Queueing: #{metric} -> #{payload.inspect}"
          queue_metric(metric, payload, { :synchronous => synchronous })
        else
          if !@queue_full_warning
            @queue_full_warning = true
            logger.warn "Queue full(#{@queue.size}), dropping commands..."
          end
          logger.debug "Dropping command, queue full(#{@queue.size}): #{metric}"
          nil
        end
      end
    end

    def queue_metric(metric, payload = nil, options = {})
      if @enabled
        options ||= {}
        if options[:allow_reconnect].nil?
          options[:allow_reconnect] = @allow_reconnect
        end
        synchronous = options.delete(:synchronous)
        if synchronous
          options[:sync_resource] ||= ConditionVariable.new
          @sync_mutex.synchronize {
            @queue << [metric, payload, options]
            options[:sync_resource].wait(@sync_mutex)
          }
        else
          @queue << [metric, payload, options]
        end
      end
      metric
    end

    def start_connection_worker
      if enabled?
        @pid = Process.pid
        @queue = Queue.new
        @sync_mutex = Mutex.new
        @failures = 0
        logger.info "Starting thread"
        @thread = Thread.new do
          sleep 0 #yield back before processing anything
          run_worker_loop
        end
      end
    end

    def run_worker_loop
      command_and_args = nil
      command_options = nil
      @piratemetrics = Faraday.new(:url => "#{@host}:#{@port}") do |faraday|
        faraday.request  :url_encoded
        faraday.adapter  Faraday.default_adapter
      end
      logger.info "connected to collector at #{host}:#{port}"
      @failures = 0
      loop do
        begin
          metric, payload, options = @queue.pop
          sync_resource = options && options[:sync_resource]
          case metric
          when 'exit'
            logger.info "Exiting, #{@queue.size} commands remain"
            return true
          when 'flush'
            release_resource = true
          else
            logger.debug "Sending: #{metric} -> #{payload.inspect}"
            result = @piratemetrics.post("/api/v1/#{metric}s", { :api_key => @api_key, :data => payload})
            logger.debug "Sent returned with status code #{result.status}"
          end
          metric = payload = options = nil
        rescue Exception => err
          queue_metric(metric, payload, options) if metric
          sleep MAX_RECONNECT_DELAY
        end
        if sync_resource
          @sync_mutex.synchronize do
            sync_resource.signal
          end
        end
      end
    rescue Exception => err
        if err.is_a?(EOFError)
          # nop
      elsif err.is_a?(Errno::ECONNREFUSED)
        logger.error "unable to connect to PirateMetrics."
      else
        report_exception(err)
      end
    end

    def setup_cleanup_at_exit
      at_exit do
        cleanup
      end
    end

    def running?
      !@thread.nil? && @pid == Process.pid
    end

  end
end
