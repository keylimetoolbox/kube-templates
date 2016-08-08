require "spec_helper"

describe Kube::Templates::Builder do

  subject { Kube::Templates::Builder.new(StringIO.new(template), StringIO.new(config)) }

  let(:config) { <<-EOS
defaults:
  replicas: 2
workers:
  - queues: report_file
    name: builder
  - queues: process_priority,process
    replicas: 4

  EOS
  }
  let(:template) { <<-EOS
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

  EOS
  }

  context "initialization" do
    it "accepts a template file name or configuration file name" do
      Kube::Templates::Builder.new(File.expand_path("../../../fixtures/empty.yml", __FILE__), File.expand_path("../../../fixtures/empty.yml", __FILE__))
    end

    it "accepts an IO object for the template file or configuration file" do
      Kube::Templates::Builder.new(StringIO.new(template), StringIO.new(config))
    end
  end

  context "#build" do
    let(:deployments) { subject.build.split("---") }

    it "creates a configuration for each stated worker" do
      expect(deployments.count).to eq 2
      expect(deployments[0]).to include "report_file"
      expect(deployments[1]).to include "process"
    end

    it "assigns the variables correctly in each instance" do
      expect(deployments[0]).to include "queues: report_file"
      expect(deployments[0]).not_to include "queues: process_priority,process"

      expect(deployments[1]).to include "replicas: 4"
      expect(deployments[1]).to include "queues: process_priority,process"
      expect(deployments[1]).not_to include "queues: report_file"
    end

    it "applies default values when not specified in the worker config" do
      expect(deployments[0]).to include "replicas: 2"
      expect(deployments[1]).to include "replicas: 4"
    end

    it "applies the NAME value when provided" do
      expect(deployments[0]).to include "name: resque-builder"
    end

    it "generates an appropriate NAME when not provided" do
      expect(deployments[1]).to match /^\s+name: resque-process-priority-process$/
    end
  end
end
