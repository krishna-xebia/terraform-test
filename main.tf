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
        ProjectName = "test-tf-codebuild"
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name             = "PlanInfra_USE1"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["BuildArtifact"]
      output_artifacts = ["InfraArtifact"]
      run_order        = 1

      configuration = {
        ProjectName = "test-tf-codebuild"
      }
    }

    action {
      name            = "DeployInfra_USE1"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["InfraArtifact"]
      run_order       = 2

      configuration = {
        ProjectName = "test-tf-codebuild"
      }
    }

    action {
      name            = "DeployApp_USE1"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["InfraArtifact"]
      run_order       = 3

      configuration = {
        ProjectName = aws_codebuild_project.deploy-app-dev[0].name
      }
    }
  }

  stage {
    name = "PromoteToQA"

    action {
      name      = "ManualApproval"
      category  = "Approval"
      owner     = "AWS"
      provider  = "Manual"
      version   = "1"
      run_order = 1
    }

    action {
      name            = "CopyArtifactToQA"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "S3"
      version         = "1"
      input_artifacts = ["InfraArtifact"]
      run_order       = 2

      configuration = {
        BucketName = var.s3_bucket["qa"]
        Extract    = "false"
        ObjectKey  = "${local.name}/PromotedBuild.zip"
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
            "Resource": "*",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ]
        },
        {
            "Effect": "Allow",
            "Resource": [
                "arn:aws:s3:::codepipeline-us-east-1-*"
            ],
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:GetObjectVersion",
                "s3:GetBucketAcl",
                "s3:GetBucketLocation"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "codebuild:CreateReportGroup",
                "codebuild:CreateReport",
                "codebuild:UpdateReport",
                "codebuild:BatchPutTestCases"
            ],
            "Resource": [
                "arn:aws:codebuild:us-east-1:443147798423:report-group/demo-*"
            ]
        }
    ]
}
EOF
}


