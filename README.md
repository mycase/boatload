# Boatload

Boatload is a gem for enqueueing a bunch of work and then asynchronously processing it all in one go. Consider the following example:

You have a Rails app and you want to write something to Kafka for every request. It's important to make the network call to Kafka asynchronously because it might take a while and in the meantime you don't want to block the request from being served. At the same time, making a separate call to Kafka for each request served by your app is inefficient. Instead, you want to batch up a bunch of data and send it all at once.

This is a common use case for Kafka so the [ruby-kafka](https://github.com/zendesk/ruby-kafka) library provides an `AsyncProducer` class to do exactly that. This gem provides the same functionality but removes all the Kafka-specific stuff and allows you to define for yourself what "processing a batch" looks like. So if you want to write to some other datastore or do something else entirely, you're free to do so.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'boatload'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install boatload

## Usage

A basic example where we manually decide when to kick off a batch process:

```ruby
abp = Boatload::AsyncBatchProcessor.new { |items| puts items }

abp.push 1
abp.push 2
# ...

# This will call the process block asynchronously with all the items that have been pushed
abp.process
```

We can specify a `max_backlog_size` to automatically trigger a batch process once a certain number of items have been pushed:

```ruby
abp = Boatload::AsyncBatchProcessor.new(max_backlog_size: 5) { |items| puts items }

abp.push 1, 2, 3, 4

# A batch process will be triggered automatically once 5 is pushed
abp.push 5
```

We can also specify a `delivery_interval` to automatically trigger a batch process periodically:

```ruby
abp = Boatload::AsyncBatchProcessor.new(delivery_interval: 30) { |items| puts items }

abp.push 1, 2, 3

# Every 30 seconds, a batch process will automatically be triggered
```

For maximal robustitude, consider using `max_backlog_size` and `delivery_interval` in conjunction with one another.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/appfolio/boatload.

