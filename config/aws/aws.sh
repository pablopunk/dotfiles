# AWS Profile configuration
# Configure AWS CLI with profile
[[ -s "$HOME/.aws/credentials" ]] && export AWS_PROFILE=testing_developer
# Source aws config if it exists and AWS CLI is available
[[ -s "$HOME/.aws/config" ]] && [[ -n "$AWS_CLI_COMPLETE" ]] || export AWS_CLI_COMPLETE=1
