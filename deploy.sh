#!/bin/bash

# Copyright 2012-2017 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

#----- Change these parameters to suit your environment -----#
aws_profile="default"
backup_schedule="cron(0 2 * * ? *)"
scripts_s3_bucket="[S3-BUCKET-FOR-BACKUP-SCRIPTS]" # bucket must exist in the SAME region the deployment is taking place
backups_s3_bucket="[S3-BUCKET-FOR-BACKUPS]" # bucket must exist and have no policy that disallows PutObject from CodeBuild
stack_name="codecommit-backups"
#----- End of user parameters  -----#

# You can also change these parameters but it's not required
cfn_template="codecommit_backup_cfn_template.yaml"
zipfile="codecommit_backup_scripts.zip"
cfn_gen_template="/tmp/gen_codecommit_backup_cfn_template.yaml"

zip -r "${zipfile}" ./ -x .git\*
aws s3 --profile $aws_profile cp "${zipfile}" "s3://${scripts_s3_bucket}"
rm -f "${zipfile}"

aws cloudformation package \
    --template-file "${cfn_template}" \
    --s3-bucket "$scripts_s3_bucket" \
    --output-template-file "$cfn_gen_template"

aws cloudformation deploy \
    --profile $aws_profile \
    --stack-name "${stack_name}" \
    --template-file "${cfn_gen_template}" \
    --parameter-overrides \
        CodeCommitBackupsScriptsS3Bucket="${scripts_s3_bucket}" \
        CodeCommitBackupsS3Bucket="${backups_s3_bucket}" \
        BackupSchedule="${backup_schedule}" \
        BackupScriptsFile="${zipfile}" \
    --capabilities CAPABILITY_IAM \
    --tags "Name=${stack_name}"

