require "yaml"

module Kube
  module Templates
    # Applies a template of a kubernetes configuration with options for resque
    # workers and builds out deployments for all workers
    #
    # Example
    #
    # Given a kubernetes deployment configuration template:
    #
    #    # resque-template.yaml
    #    apiVersion: extensions/v1beta1
    #    kind: Deployment
    #    metadata:
    #      name: resque-${NAME}
    #    spec:
    #      replicas: ${REPLICAS}
    #      template:
    #        metadata:
    #          labels:
    #            service: rails
    #            app: my-app
    #            purpose: worker
    #            queues: ${QUEUES}
    #        spec:
    #          containers:
    #          - name: my-app
    #            image: us.gcr.io/project-id-1138/my-app-resque:latest
    #            env:
    #            - name: QUEUE
    #              value: ${QUEUES}
    #
    # And the following worker configuration
    #
    #    # resque-workers.yml
    #    defaults:
    #      replicas: 2
    #    workers:
    #      - queues: reports
    #        replicas: 4
    #        name: builder
    #      - queues: process_priority,process
    #
    # Use the `resque-k8s` command to create a series of YAML deployments
    # for kubernetes to consume. Then use `kubectl apply` command to configure
    # the cluster.
    #
    #    $ resque-k8s | kubectl apply -f -
    class Builder

      # Create a template handler for the template and configuration.
      #
      # template_file  The name or IO of the file that has the kubernetes deployment template.
      # config_file    The name or IO of the file that has the resque configuration.
      #
      # For either argument you can provide the path to the template file or
      # you can provide an `IO` object for the `Builder` to read. With an `IO`
      # object you are responsible for closing the stream.
      #
      # Examples:
      #     Kube::Templates::Builder.new("resque-template.yml", "resque-workers.yml")
      #
      #     File.open("resque-template.yml") do |template|
      #       File.open("resque-workers.yml") do |config|
      #         Kube::Templates::Builder.new(template, config))
      #       end
      #     end
      #
      # Note that if you want to provide a string value to the `Builder` you can
      # just use a `StringIO` instance.
      #
      #     Kube::Templates::Builder.new(StringIO.new(template), StringIO.new(config))
      def initialize(template_file, config_file)
        @template = readfile(template_file)
        @config   = YAML.load(readfile(config_file))
      end

      # Returns a string of YAML configurations, concatenated with "---" line,
      # for each configuration defined.
      #
      # The `config_file` must have a "workers" property which is a collection
      # of properties that are applied to the template. Template variables are
      # case insensitive, but configuration keys must all be lower case.
      #
      # You can also provide a "defaults" section that applies default values
      # for any worker that does not have a specific value defined.
      #
      # There is a special ${NAME} property that you can use in your template. If
      # not provided as a value, it will default to, roughly, the values for
      # the worker concatenated with "-".
      #
      # Example:
      #    # resque-workers.yml
      #    defaults:
      #      replicas: 2
      #    workers:
      #      - queues: reports
      #        replicas: 4
      #        name: builder
      #      - queues: process_priority,process
      #
      # For this configuration, `#build` would create two YAML configurations.
      # The first assigns these values in the template:
      #    ${QUEUES}   = "reports"
      #    ${REPLICAS} = 4
      #    ${NAME}     = "builder"
      # The second assigns these values in the template:
      #    ${QUEUES}   = "process_priority,process"
      #    ${REPLICAS} = 2
      #    ${NAME}     = "process-priority-process"
      #
      # Configurations are returned in the order defined in the `config_file`.
      def build
        defaults = @config["defaults"] || {}
        configs = @config["workers"].map do |worker|
          # TODO: We should #downcase the keys for the variables as well
          variables = defaults.merge(worker)
          @template.gsub(/\$\{([^}]+)\}/) do |match|
            key = Regexp.last_match[1].downcase
            if variables.key? key
              variables[key]
            elsif key == "name"
              # NB This doesn't handle utf-8 characters at all
              name_from_values(worker.values)
            else
              match
            end
          end
        end

        configs.join("---\n")
      end

      private

      def readfile(file)
        if file.is_a? String
          File.read(file)
        elsif file.respond_to?(:read)
          file.read
        else
          raise ArgumentError.new("Don't know how to read #{file.class}")
        end
      end

      def name_from_values(values)
        values.join("-").gsub(/[^-a-zA-Z0-9]/, "-").gsub(/--+/, "-").gsub(/\A-|-\Z/, "")
      end
    end
  end
end
