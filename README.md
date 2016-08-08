# Kube::Templates
[![Gem](https://img.shields.io/gem/v/formatador.svg?maxAge=2592000)](https://rubygems.org/gems/kube-templates)

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

`Kube::Templates::Builder` takes a template file and a configuration file, assigning values from the
configuration file and emitting a collection of deployments for kubernetes to run.

### Example

Create a deployment template. In this file you can have template variables (e.g. `${QUEUES}`) that 
will be replaced with values from your configuration. In the following we use three variables,
`${NAME}`, `${REPLICAS}`, and `${QUEUES}`.

    # resque-template.yaml
    apiVersion: extensions/v1beta1
    kind: Deployment
    metadata:
      name: resque-${NAME}
    spec:
      replicas: ${REPLICAS}
      template:
        metadata:
          labels:
            service: rails
            app: my-app
            purpose: worker
            queues: ${QUEUES}
        spec:
          containers:
          - name: my-app
            image: us.gcr.io/project-id-1138/my-app-resque:latest
            env:
            - name: QUEUE
              value: ${QUEUES}

Create a configuration file that defines your workers. In the following file we define two types 
of workers. One, with four replicas, listens onthe "reports" queue. A second listens on the 
"process_priority" and "process" queues. This second worker will have two replicas set as that
values it defined in the "defaults" section and it doesn't change it.

    # resque-workers.yml
    defaults:
      replicas: 2
    workers:
      - queues: reports
        replicas: 4
        name: builder
      - queues: process_priority,process
     
Note that while we can define the `NAME` variable, as we did for the first worker, we don't 
need to and the `Builder` will automatically generate a name from the values provided for 
the worker. So the second worker would have a name "process-priority-process"

Use the `resque-k8s` command to create a series of YAML deployments
for kubernetes to consume. You can pipe the output to less to see what it produces.

    $ resque-k8s | less

To apply this run the `kubectl apply` command with the value from the configuration.

    $ resque-k8s | kubectl apply -f -


## Other options

This is a very simple implementation. There are a number of solutions out there that propose to 
do something similar in the scope of larger efforts.

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
