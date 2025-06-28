target "default" {
  name = "python27-alpine${replace(alpine_version, ".", "-")}"
  dockerfile = "./Dockerfile"
  context = "."
  matrix = {
    alpine_version = ["3.20", "3.21", "3.22"]
  }
  args = {
    ALPINE_VERSION = alpine_version
  }
  tags = [
    "docker.io/4teamwork/python:2.7-alpine${alpine_version}",
    equal(alpine_version, "3.22") ? "docker.io/4teamwork/python:latest" : "",
  ]
  platforms = [
    "linux/amd64",
    "linux/arm64"
  ]
}
