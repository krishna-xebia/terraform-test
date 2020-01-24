############################################
##  Codebuild - Build Environment - "dev"  ##
#############################################

resource "aws_codebuild_project" "stunpeer-cd" {
  name          = "stunpeer-cd"
  description   = "stunpeer"
  build_timeout = "30"
  service_role  = aws_iam_role.codebuild_role.arn

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec-plan-infra.yml"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_LARGE"
    image           = "hashicorp/terraform:0.12"
    type            = "LINUX_CONTAINER"
    privileged_mode = "true"

    environment_variable {
      name  = "ENVIRONMENT"
      value = "dev"
    }
    environment_variable {
      name  = "PROJECT_NAME"
      value = "dev"
    }
  }

  artifacts {
    type = "CODEPIPELINE"
  }

  cache {
    type  = "LOCAL"
    modes = ["LOCAL_DOCKER_LAYER_CACHE", "LOCAL_SOURCE_CACHE"]
  }
}


####IAM Role

resource "aws_iam_role" "codebuild_role" {
  name = "test-codebuild-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}
