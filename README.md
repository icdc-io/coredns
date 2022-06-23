# Coredns
A simple way to control your dns records managed by [coredns-etcd application](https://coredns.io/plugins/etcd/)

## Requirements
ruby >= 2.7

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'coredns'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install coredns

## Usage

### Connection object
```ruby

> coredns = CoreDns::Etcd.new('your.etcd.server.url.example')
> coredns
=> 
#<CoreDns::Etcd:0x00007f09c2ba7d40
 @api_url="http://your.etcd.server.url.example:2379/v3",
 @endpoint="your.etcd.server.url.example",
 @logger=
  #<Logger:0x00007f09c2ba7cf0
   @default_formatter=#<Logger::Formatter:0x00007f09c2ba7c50 @datetime_format=nil>,
   @formatter=nil,
   @level=0,
   @logdev=#<Logger::LogDevice:0x00007f09c2ba7bb0 @binmode=false, @dev=#<IO:<STDOUT>>, @filename=nil, @mon_data=#<Monitor:0x00007f09c2ba7b88>, @mon_data_owner_object_id=49820, @shift_age=nil, @shift_period_suffix=nil, @shift_size=nil>,
   @progname=nil>,
 @port=2379,
 @postfix="x",
 @prefix="skydns",
 @version="v3">
```

You can specify custom postfix, prefix, api version and port using enviroment variables:
```
ENV["COREDNS_PREFIX"], default is "skydns"
ENV["COREDNS_POSTFIX"], default is "x"
ENV["COREDNS_PORT"], default is 2379
ENV["COREDNS_VERSION"], default is "v3" (also tested v3beta)
```

### DNS Zones
```ruby
# List dns zones
> coredns.zone('').list
=> []

# Show information about selected dns zone
> coredns.zone('your.zone').show
=> {"name"=>"your.zone", "metadata"=>{"zone"=>true, ...additional metadata information... }}

# List of subzones
> coredns.zone('your.zone').subzones

# Get parent dns zone
> coredns.zone('sub1.your.zone').parent_zone

# Create a new dns zone

> coredns.zone('new.your.zone').add({metadata: {...additional metadata infromation...}})

# Delete existing dns zone
> coredns.zone('new.your.zone').delete

# List dns zone records

> coredns.zone('your.zone').records
```

### DNS domains
```ruby
# Add a new domain
> coredns.domain('domain1.your.zone').add({params})
# Whitelist of availalbe params:
# host mail port priority text ttl group metadata


# Get information about domain
> coredns.domain('domain1.your.zone').show

# Delete domain
> coredns.domain('domain1.your.zone').delete
```
