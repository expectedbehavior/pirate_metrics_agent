# Pirate Metrics Agent

Get to know your customers

## Setup & Usage

Add the gem to your Gemfile.

```sh
gem 'pirate_metrics_agent'
```

Visit [piratemetrics.com](https://piratemetrics.com) and create an account, then  initialize the agent with your API key, found on the main project page.

```sh
PM = PirateMetrics::Agent.new('YOUR_API_KEY', :enabled => Rails.env.production?)
```

You'll  probably want something like the above, only enabling the agent in production mode so you don't have development and production data writing to the same value. Or you can setup two projects, so that you can verify stats in one, and release them to production in another.

Now you can begin to use Pirate Metrics to track your application.

```sh
PM.acquisition({ :email => 'joe@example.com'})    # new user acquisition
```

**Note**: For your app's safety, the agent is meant to isolate your app from any problems our service might suffer. If it is unable to connect to the service, it will discard data after reaching a low memory threshold.

## Backfilling

You almost certainly have events that occurred before you signed up for Pirate Metrics.  To get all of your users into the proper context, Pirate Metrics allows you to backfill data.

When backfilling, you may send tens of thousands of metrics per second, and the command buffer may start discarding data it isn't able to send fast enough. Using the ! form of the various API calls will force them to be synchronous.

**Warning**: You should only use synchronous mode for backfilling data as any issues with the Pirate Metrics service issues will cause this code to halt until it can reconnect.

```sh
acquisition_data = []
User.find_in_batches(:batch_size => 100) do |users|
  users.each do |user|
    acquisition_data << {:email => user.email, :occurred_at => user.created_at}
  end
  PM.acquisition!(acquisition_data)
  acquisition_data.clear                        
end
```
## Agent Control

Need to quickly disable the agent? set :enabled to false on initialization and you don't need to change any application code.

## Tracking metrics in Resque jobs (and Resque-like scenarios)

If you plan on tracking metrics in Resque jobs, you will need to explicitly cleanup after the agent when the jobs are finished.  You can accomplish this by adding `after_perform` and `on_failure` hooks to your Resque jobs.  See the Resque [hooks documentation](https://github.com/defunkt/resque/blob/master/docs/HOOKS.md) for more information.

You're required to do this because Resque calls `exit!` when a worker has finished processing, which bypasses Ruby's `at_exit` hooks.  The Pirate Metrics Agent installs an `at_exit` hook to flush any pending metrics to the servers, but this hook is bypassed by the `exit!` call; any other code you rely that uses `exit!` should call `PM.cleanup` to ensure any pending metrics are correctly sent to the server before exiting the process.

## Troubleshooting & Help

We are here to help. Email us at [support@piratemetrics.com](mailto:support@piratemetrics.com).
