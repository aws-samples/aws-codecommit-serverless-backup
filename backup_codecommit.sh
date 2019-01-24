#!/bin/bash

# Copyright 2012-2017 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Amazon Software License (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License is located at
#
# http://aws.amazon.com/asl/
#
# or in the "license" file accompanying this file. This file is distributed
# on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
# express or implied. See the License for the specific language governing
# permissions and limitations under the License.

set -ex

# variable CodeCommitBackupsS3Bucket is exported into CodeBuild environment variables
backup_s3_bucket="${CodeCommitBackupsS3Bucket:-"my-s3-bucket"}"

git config --global credential.helper '!aws codecommit credential-helper $@'
git config --global credential.UseHttpPath true

declare -a repos=(`aws codecommit list-repositories | jq -r '.repositories[].repositoryName'`)

if ! parallel --joblog /tmp/log --jobs 400% --max-args=1 \
  ./backup_repo.sh "${backup_s3_bucket}" {} ::: "${repos[@]}"
then
  for i in {1..3}
  do
    sleep $(( i * 5 ))
    parallel --resume-failed --joblog /tmp/log --jobs 400% --max-args=1 \
      ./backup_repo.sh "${backup_s3_bucket}" {} ::: "${repos[@]}" && break
  done
fi

