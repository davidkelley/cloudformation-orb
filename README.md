# CloudFormation CircleCI Orb

[![semantic-release](https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg)](https://github.com/semantic-release/semantic-release) [![Build Status](https://travis-ci.org/davidkelley/cloudformation-orb.svg?branch=master)](https://travis-ci.org/davidkelley/cloudformation-orb) [![Orb version](https://img.shields.io/endpoint.svg?url=https://badges.circleci.io/orb/davidkelley/cloudformation)](https://circleci.com/orbs/registry/orb/davidkelley/cloudformation) [![](https://images.microbadger.com/badges/image/davidkelley/cloudformation-orb.svg)](https://microbadger.com/images/davidkelley/cloudformation-orb "Docker Image") [![](https://images.microbadger.com/badges/version/davidkelley/cloudformation-orb.svg)](https://microbadger.com/images/davidkelley/cloudformation-orb "Docker Version")

Reproduces the functionality provided by AWS CodePipeline in CircleCI, for deploying CloudFormation templates.

To use this orb, include the orb in your `config.yml` file:

```yaml
orbs:
  - cloudformation: davidkelley/cloudformation@1.0.2
```

Given the above, you can then use the following commands:

```yaml
jobs:
  deployment:
    # Use the executor provided by the orb. This executor is based upon the
    # "circleci/node:12" image but also includes the AWS cli. If you have a
    # similar image, there's no reason why you couldn't use your own.
    executor: cloudformation/cloudformation
    steps:
      - checkout

      # This command reads parameters with a specific path prefix from SSM Parameter Store 
      # into the $BASH_ENV for CircleCI. This allows you to use these values as environment 
      # variables in subsequent steps. For example, if you have a parameter with the name
      # "/Project/Upload/ArtifactBucket", this would be set as $PROJECT_UPLOAD_ARTIFACT_BUCKET.
      # 
      # You can use then use these environment variables in later steps, as demonstrated
      # in the cloudformation/package-template example below.
      # 
      #   Note: To generate the variable key, we replace all slashes with underscores, 
      #   strip any "special characters" ("-" for example) and 
      #   convert camel-case to snake-case.
      - cloudformation/read-parameters:
          path: /Project

      # Package a cloudformation template, uploading local artifacts required
      # for deployment into an S3 bucket, under an optional prefix encrypted
      # with KMS.
      - cloudformation/package-template:
          # An AWS CloudFormation template file
          template-file: cloudformation.yml
          # The name of the S3 bucket that will be used to store uploaded artifacts
          # produced by packaging the template.
          s3-bucket: ${PROJECT_UPLOAD_ARTIFACT_BUCKET}
          # The S3 prefix to be applied to any uploaded artifacts.
          s3-prefix: /prefix/of/artifacts
          # The KMS encryption key used to encrypt uploaded artifacts. This is required.
          kms-key-id: alias/my-key
          # The location of the packaged cloudformation template file.
          output-template-file: /workspace/packaged.yml

      # Deploy a cloudformation stack. This command creates or updates
      # a stack and waits for the operation to complete.
      - cloudformation/deploy-and-wait:
          # An input json file generated by running a command similar to:
          # 
          #   `aws cloudformation create-stack --generate-cli-skeleton > cli-skeleton.json`
          input-json: cli-skeleton.json
          # An AWS CloudFormation template file
          template-file: cloudformation.yml
          # The name of the deployed CloudFormation Stack. This needs to be present
          # and CANNOT be specified inside the skeleton file.
          stack-name: name-of-the-cloudformation-stack

      # Saves the outputs of a CloudFormation stack to a JSON file.
      - cloudformation/save-outputs:
          # The name of the deployed CloudFormation Stack. This needs to be present
          # and CANNOT be specified inside the skeleton file.
          stack-name: name-of-the-cloudformation-stack
          # The path to the file where the stack outputs will be stored. If the 
          # CloudFormation contained an output named "Foobar" with value 
          # "arn:aws:::s3:bucket", the file would have the following contents:
          # 
          # {
          #   "Foobar": "arn:aws:::s3:bucket"
          # }
          output-json: /tmp/outputs.json

      # Merges one or more Key:Value JSON files, with a CloudFormation skeleton file.
      # This operation allows you to easily feed the outputs of one stack, into the parameters
      # of another stack.
      - cloudformation/merge-parameters:
          # A path to a file, glob or space-delimeted list of files to use as 
          # source JSON files. Note that files must be in a similar format to the
          # `output-json` file that is produced in the above example.
          source-json: /tmp/outputs.json
          # The JSON file that will be the target of all the merged source JSON
          # files. This file should be a CLI skeleton file produced by running:
          # 
          #   `aws cloudformation create-stack --generate-cli-skeleton > cli-skeleton.json`
          target-json: cli-skeleton.json

      # This command lists stack events that incate an error in table format when a
      # preceeding command has failed, using the `when: on_failed` condition.
      - cloudformation/list-stack-errors:
          # The name of the CloudFormation Stack to list events for.
          stack-name: name-of-the-cloudformation-stack

      # If an AWS CloudFormation stack exists, this command will delete the stack 
      # and wait for the operation to complete successfully. If the stack does not 
      # exist, then this command does nothing and exits.
      - cloudformation/delete-and-wait:
          # The name of the CloudFormation Stack to delete.
          stack-name: name-of-the-cloudformation-stack
```

To simplify the process of deploying multiple stacks at once, this orb also provides a job that helps to ease the configuration for deploying a CloudFormation stack.

```yaml
# Orchestrate or schedule a set of jobs, see https://circleci.com/docs/2.0/workflows/
workflows:
  deploy-my-templates:
    jobs:
      - cloudformation/deploy:
          # The name of the deployed CloudFormation Stack.
          stack-name: name-of-the-cloudformation-stack
          # If set, the workspace will be mounted at this location for the duration
          # of the job.
          workspace: /workspace
          # An AWS CloudFormation template file
          template-file: template.yml
          # An input json file generated by running a command similar to:
          # 
          #   `aws cloudformation create-stack --generate-cli-skeleton > cli-skeleton.json`
          # 
          # In this example, the `input-json` file is located inside the mounted workspace.
          input-json: /workspace/parameters.json
          # The path to the file where the stack outputs will be stored. If the 
          # CloudFormation contained an output named "Foobar" with value 
          # "arn:aws:::s3:bucket", the file would have the following contents:
          # 
          # {
          #   "Foobar": "arn:aws:::s3:bucket"
          # }
          # 
          # In this example, the outputs are being saved to the workspace, which is
          # persisted at the end of the job.
          output-json: /workspace/outputs.json
          # Define optional steps to run immediately before the deployment of the
          # stack. This is useful for merging parameters that may have been produced
          # from the outputs of previous deployments.
          before-deploy:
            # This command is documented above...
            - cloudformation/merge-parameters:
                source-json: keya.json keyb.json
                target-json: /workspace/skeleton.json
                destination-json: /workspace/parameters.json
          # Define optional steps to run immediately after the deployment of the
          # stack has completed successfully.
          after-deploy:
            - run:
                command: |
                  cat /workspace/outputs.json | jq
```