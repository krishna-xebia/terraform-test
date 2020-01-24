
#############################################
##  Codebuild - Build Environment - "dev"  ##
#############################################

resource "aws_codebuild_project" "stunpeer-cd" {
  name          = "stunpeer-cd"
  description   = "stunpeer"
  build_timeout = "30"
  service_role  = aws_iam_role.codepipeline_role.arn
  badge_enabled = "true"

  source {
    type                = "GITHUB"
    location            = "https://github.com/krishna-xebia/terraform-test.git"
    git_clone_depth     = 0
    buildspec           = "buildspec-build.yml"
    report_build_status = "true"
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

  source {
    type      = "CODEPIPELINE"
    buildspec = "devops/buildspec-plan-infra.yml"
  }

  artifacts {
    type = "CODEPIPELINE"
  }

  cache {
    type  = "LOCAL"
    modes = ["LOCAL_DOCKER_LAYER_CACHE", "LOCAL_SOURCE_CACHE"]
  }
}
