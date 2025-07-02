package test

import (
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestMultipassVM tests the Multipass VM Terraform configuration
func TestMultipassVM(t *testing.T) {
	t.Parallel()

	// Construct the terraform options with default retryable errors to handle the most common
	// retryable errors in terraform testing.
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		// Set the path to the Terraform code that will be tested.
		TerraformDir: "../../terraform/local-multipass-vm",

		// Variables to pass to our Terraform code using -var options
		Vars: map[string]interface{}{
			"vm_name": "test-vm",
			"cpus":    2,
			"memory":  "2G",
			"disk":    "10G",
		},

		// Disable colors in Terraform commands so it's easier to parse stdout/stderr
		NoColor: true,
	})

	// Clean up resources with "terraform destroy" at the end of the test.
	defer terraform.Destroy(t, terraformOptions)

	// Run "terraform init" and "terraform apply". Fail the test if there are any errors.
	terraform.InitAndApply(t, terraformOptions)

	// Run `terraform output` to get the values of output variables
	vmName := terraform.Output(t, terraformOptions, "multipass_vm_name")

	// Verify the VM name is what we expect
	assert.Equal(t, "test-vm", vmName)

	// Additional verification: Check if VM actually exists
	// Note: This would require multipass CLI to be available in the test environment
	// For now, we'll just verify the terraform output
}

// TestMultipassVMWithCloudInit tests the Multipass VM with cloud-init configuration
func TestMultipassVMWithCloudInit(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../terraform/local-multipass-vm",
		Vars: map[string]interface{}{
			"vm_name":         "test-vm-cloudinit",
			"cpus":            4,
			"memory":          "4G",
			"disk":            "20G",
			"cloud_init_file": "cloud-init.yaml",
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	// Test that terraform plan succeeds
	terraform.InitAndPlan(t, terraformOptions)

	// Apply the configuration
	terraform.Apply(t, terraformOptions)

	// Get outputs
	vmName := terraform.Output(t, terraformOptions, "multipass_vm_name")
	assert.Equal(t, "test-vm-cloudinit", vmName)
}

// TestMultipassVMValidation tests input validation
func TestMultipassVMValidation(t *testing.T) {
	terraformOptions := &terraform.Options{
		TerraformDir: "../../terraform/local-multipass-vm",
		Vars: map[string]interface{}{
			"vm_name": "", // Invalid empty name
			"cpus":    0,  // Invalid CPU count
			"memory":  "0G",
			"disk":    "0G",
		},
		NoColor: true,
	}

	// This should fail during plan phase due to validation
	_, err := terraform.InitAndPlanE(t, terraformOptions)
	assert.Error(t, err, "Expected validation error for invalid inputs")
}

// TestTerraformSyntax tests that all Terraform files have valid syntax
func TestTerraformSyntax(t *testing.T) {
	terraformDirs := []string{
		"../../terraform/local-multipass-vm",
		"../../terraform/oci-vm",
		"../../terraform/local-microk8s",
	}

	for _, dir := range terraformDirs {
		t.Run(dir, func(t *testing.T) {
			terraformOptions := &terraform.Options{
				TerraformDir: dir,
				NoColor:      true,
			}

			// Test that terraform init and validate succeed
			terraform.Init(t, terraformOptions)
			terraform.Validate(t, terraformOptions)
		})
	}
}
