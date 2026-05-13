terraform {
  backend "s3" {
    bucket       = "tf-state-taxsutra"
    key          = "lower-env/infra.tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }
}
