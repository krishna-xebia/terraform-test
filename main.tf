provider "aws" {
  region = "${var.aws_region}"
}
#########################################################
## Pipeline for DEV
#########################################################
resource "aws_codepipeline" "test-dev" {
  name     = "test-demo-codepipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = "pawan-test"
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["SourceArtifact"]

      configuration = {
        Owner                = "krishna-xebia"
        Repo                 = "terraform-test"
        Branch               = "master"
        OAuthToken           = "bf64a285b0daf305d46df636a5eb5987d41e6641"
        PollForSourceChanges = "false"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["SourceArtifact"]
      output_artifacts = ["BuildArtifact"]

      configuration = {
        ProjectName = "aws_codebuild_project.stunpeer-cd[0].name"
      }
    }
  }

}




#########################################################
## DEV only
#########################################################
resource "aws_codepipeline_webhook" "test-dev-webhook" {
  name            = "test-dev-webhook"
  authentication  = "GITHUB_HMAC"
  target_action   = "Source"
  target_pipeline = aws_codepipeline.test-dev.name

  authentication_configuration {
    secret_token = "bf64a285b0daf305d46df636a5eb5987d41e6641"
  }

  filter {
    json_path    = "$.ref"
    match_equals = "refs/heads/{Branch}"
  }
}


####IAM Role

resource "aws_iam_role" "codepipeline_role" {
  name = "test-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "codepipeline_policy"
  role = "${aws_iam_role.codepipeline_role.id}"

  policy = <<EOF

{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "*",
            "Resource": "*"
        }
    ]
}

EOF
}



