terraform {
  backend "gcs" {
    # Make sure the bucket is created on GCP manually before running "terraform init" for the first time
    bucket  = "k8s-kafka"
    prefix  = "terraform/state"  # Optional: Use this to organize your state files within the bucket.
  }
}
