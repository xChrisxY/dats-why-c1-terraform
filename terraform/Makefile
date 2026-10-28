.PHONY: help init plan apply destroy fmt validate lint clean

ENVIRONMENT ?= dev
TF_DIR := environments/$(ENVIRONMENT)
BACKEND_DIR := _setup/backend

# Colors
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m

help: ## Show this help
	@echo "$(GREEN)Dat's Why - Terraform Automation$(NC)"
	@echo ""
	@echo "Usage: make [command] ENVIRONMENT=dev|staging|prod"
	@echo ""
	@echo "Commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2}'


backend-init: ## Initialize backend (S3 + DynamoDB)
	@echo "$(GREEN)Initializing backend...$(NC)"
	cd $(BACKEND_DIR) && terraform init

backend-apply: ## Create backend resources
	@echo "$(GREEN)Creating backend resources...$(NC)"
	cd $(BACKEND_DIR) && terraform apply

backend-output: ## Show backend configuration
	@echo "$(GREEN)Backend configuration:$(NC)"
	cd $(BACKEND_DIR) && terraform output backend_config


init: ## Initialize Terraform for environment
	@echo "$(GREEN)Initializing $(ENVIRONMENT)...$(NC)"
	@if [ -z "$$TF_BACKEND_BUCKET" ]; then \
		echo "$(RED)Error: TF_BACKEND_BUCKET not set$(NC)"; \
		echo "Run: export TF_BACKEND_BUCKET=your-bucket-name"; \
		exit 1; \
	fi
	cd $(TF_DIR) && terraform init \
		-backend-config="bucket=$$TF_BACKEND_BUCKET" \
		-backend-config="key=$(ENVIRONMENT)/terraform.tfstate" \
		-backend-config="region=us-east-1" \
		-backend-config="dynamodb_table=dats-why-terraform-locks" \
		-backend-config="encrypt=true"

plan: ## Plan infrastructure changes
	@echo "$(GREEN)Planning $(ENVIRONMENT)...$(NC)"
	cd $(TF_DIR) && terraform plan -out=tfplan

apply: ## Apply infrastructure changes
	@echo "$(GREEN)Applying $(ENVIRONMENT)...$(NC)"
	cd $(TF_DIR) && terraform apply tfplan

apply-auto: ## Apply without confirmation (use with caution)
	@echo "$(YELLOW)Auto-applying $(ENVIRONMENT)...$(NC)"
	cd $(TF_DIR) && terraform apply -auto-approve

destroy: ## Destroy infrastructure (use with caution!)
	@echo "$(RED)Destroying $(ENVIRONMENT)...$(NC)"
	@read -p "Are you sure? [y/N] " confirm && [ "$$confirm" = "y" ]
	cd $(TF_DIR) && terraform destroy


fmt: ## Format all Terraform files
	@echo "$(GREEN)Formatting...$(NC)"
	terraform fmt -recursive .

fmt-check: ## Check formatting without changes
	@echo "$(GREEN)Checking format...$(NC)"
	terraform fmt -recursive -check .

validate: ## Validate Terraform configuration
	@echo "$(GREEN)Validating $(ENVIRONMENT)...$(NC)"
	cd $(TF_DIR) && terraform validate

lint: fmt-check validate ## Run all linting checks
	@echo "$(GREEN)All checks passed!$(NC)"

output: ## Show Terraform outputs
	@echo "$(GREEN)Outputs for $(ENVIRONMENT):$(NC)"
	cd $(TF_DIR) && terraform output

state-list: ## List resources in state
	cd $(TF_DIR) && terraform state list

clean: ## Clean Terraform files
	@echo "$(YELLOW)Cleaning...$(NC)"
	find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	find . -name "*.tfplan" -delete 2>/dev/null || true
	find . -name "lambda_placeholder.zip" -delete 2>/dev/null || true

console: ## Open Terraform console
	cd $(TF_DIR) && terraform console

graph: ## Generate dependency graph
	cd $(TF_DIR) && terraform graph | dot -Tpng > graph.png
	@echo "$(GREEN)Graph saved to $(TF_DIR)/graph.png$(NC)"
