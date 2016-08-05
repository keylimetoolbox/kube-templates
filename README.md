# Kube::Templates

Simple template system for Kubernetes deployments.

We built this to handle deploying resque workers as containers. For each of our Rails
apps we may have 50 or more resque workers running that code base, listening to different
queues. This simplified the deployment by allowing us to provide a single Deployment template
and then generate lots of deployment configurations with the right settings for the queues
for the workers to listen to and the number of replicas.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "kube-templates"
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install kube-templates

## Usage




## Other options
- There is currently a proposal to 
  [support this in Kubernetes](https://github.com/kubernetes/kubernetes/blob/master/docs/proposals/templates.md).

- [kb8or](https://github.com/UKHomeOffice/kb8or) includes something like this with many more continuous deployment
  features

- Kubernetes [Helm](https://helm.sh/) does this with its [charts](https://github.com/kubernetes/helm/tree/master/docs/examples/alpine).

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can 
also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. 

To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, 
which will create a git tag for the version, push git commits and tags, and push the `.gem` file to 
[rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/keylimetoolbox/kube-templates.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
