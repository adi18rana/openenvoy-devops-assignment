# Terraform Scalable Web App Deployment

## Top 3 Problems with Original main.tf

1. **Hardcoded values:**  
   The original `main.tf` used hardcoded AMI ID, VPC ID, and subnet ID, making the code brittle and not portable across environments or regions.

2. **Insecure Security Group:**  
   The original security group allowed unrestricted SSH and HTTP from anywhere, exposing the instance directly to the internet without proper network isolation.

3. **Single-Instance Non-scalable Architecture:**  
   Only one EC2 instance was deployed with a public IP, leading to a single point of failure and poor scalability.

---

## Chosen Architecture: ALB + ASG

- **High Availability:**  
  The architecture deploys an Auto Scaling Group (ASG) across multiple private subnets in different Availability Zones, ensuring the app remains available if instances or an AZ fail.

- **Scalability:**  
  ASG allows dynamic scaling of instances based on load, enabling the app to handle more traffic efficiently.

- **Security:**  
  Instances are deployed in private subnets, accessible only through the Application Load Balancer (ALB). The ALB has a security group allowing inbound HTTP from all, while the instance security group only allows inbound traffic from the ALB.

- **Load Balancing and Health Checks:**  
  ALB distributes incoming traffic evenly across healthy instances, improving responsiveness and fault tolerance.

Compared to the original single EC2 instance approach, this design removes single points of failure, improves security posture, and supports horizontal scaling.

---

## Production-ready Features Added to Module and Configuration

- **Locked-down Security Groups:**  
  Replaced open "allow-all" rules with least-privilege inbound rules, only permitting HTTP from ALB and optionally restricted SSH.

- **Multi-AZ Deployment:**  
  Instances and subnets are distributed across multiple Availability Zones for resiliency.

- **Auto Scaling:**  
  Configured minimum, maximum, and desired instance count with health checks and automatic recovery.

- **Outputs:**  
  Exposed ALB DNS and key resource IDs to facilitate integration and monitoring.

- **Variableization and Validation:**  
  Hardcoded values replaced by variables with sensible defaults and input validation to ensure flexibility and safety.

---

## Managing Secrets Approach

- **Use AWS Secrets Manager or AWS Systems Manager Parameter Store:**  
  Store sensitive data like database passwords, API keys, or credentials securely in managed services with encryption and fine-grained access control.

- **Instance IAM Role with Minimal Permissions:**  
  Assign an IAM role to EC2 instances that has permissions only to read required secrets, following the principle of least privilege.

- **Dynamic Secret Retrieval at Runtime:**  
  Applications retrieve secrets dynamically from the secret manager during startup or as needed, avoiding storing secrets in Terraform state or hardcoding.

- **Rotation and Auditing:**  
  Secrets can be rotated automatically using AWS Secrets Manager's built-in rotation features, with usage logged and audited using CloudTrail.

This approach ensures secrets are kept secure throughout infrastructure and application lifecycles.
