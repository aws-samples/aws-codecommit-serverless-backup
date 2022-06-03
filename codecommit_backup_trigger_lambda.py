# Copyright 2012-2017 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

import boto3
client = boto3.client('codebuild')
def handler(event, context): 
    response = client.start_build(projectName='CodeCommitBackup')
    output = "Triggered CodeBuild project: 'CodeCommitBackup' to back all CodeCommit repos in this account/region. Status={}".format(response["build"]["buildStatus"])
    print(output)
    return output
