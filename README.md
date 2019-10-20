# ![](static/klapp-back.png) klapp-example 

Research on cloud base high interaction honeypot 

# Running

1. `brew install terraform` install terraform CLI on OSX [other platforms](https://www.terraform.io/downloads.html)
2. `brew install awscli`  install aws CLI on OSX otherwise see: [guide](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html)
3. Get AWS API token `aws configure` 
4. Set terraform variables under [terraform.tfvars](https://github.com/splunk/klapp-example/blob/develop/terraform.tfvars.example)
5. `terraform init`
6. `terraform apply`

# Test
try logging into the `honeypot_ip` returned from terraform with any password to these [users](https://github.com/d1vious/klapp-example/blob/master/ansible/vars/vars.yml)

# Collecting Data
TODO