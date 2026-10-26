
resource "aws_s3_bucket" "security_lab" {
  bucket = "elie-security-lab"

  tags = {
    Environment = "Lab"
    Project     = "Cloud-Security"
    ManagedBy   = "Terraform"
  }
}
