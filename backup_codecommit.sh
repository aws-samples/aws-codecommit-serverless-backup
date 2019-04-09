#!/bin/bash

# Copyright 2012-2017 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

set -ex

# variable CodeCommitBackupsS3Bucket is exported into CodeBuild environment variables
backup_s3_bucket="${CodeCommitBackupsS3Bucket:-"my-s3-bucket"}"

git config --global credential.helper '!aws codecommit credential-helper $@'
git config --global credential.UseHttpPath true

declare -a repos=(`aws codecommit list-repositories | jq -r '.repositories[].repositoryName'`)

for codecommitrepo in "${repos[@]}"
do  
    echo "[===== Cloning repository: ${codecommitrepo} =====]"
    git clone "https://git-codecommit.${AWS_DEFAULT_REGION}.amazonaws.com/v1/repos/${codecommitrepo}"

    dt=$(date -u '+%Y_%m_%d_%H_%M')
    zipfile="${codecommitrepo}_backup_${dt}_UTC.tar.gz"
    echo "Compressing repository: ${codecommitrepo} into file: ${zipfile} and uploading to S3 bucket: ${backup_s3_bucket}/${codecommitrepo}"

    tar -zcvf "${zipfile}" "${codecommitrepo}/"
    aws s3 cp "${zipfile}" "s3://${backup_s3_bucket}/${codecommitrepo}/${zipfile}" --region $AWS_DEFAULT_REGION

    rm $zipfile
    rm -rf "$codecommitrepo"
done
