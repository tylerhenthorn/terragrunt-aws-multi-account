delete-cache:
	find . -type d -name '.terragrunt-cache' -exec rm -rf {} \;
plan:
	terragrunt run-all plan
apply:
	terragrunt run-all apply
destroy:
	terragrunt run-all destroy