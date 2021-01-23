[#ftl]

[@addExtension
    id="cognitoqs_iam"
    aliases=[
        "_cognitoqs_iam"
    ]
    description=[
        "IAM role configuration for federated role configuration"
    ]
    supportedTypes=[
        FEDERATEDROLE_ASSIGNMENT_COMPONENT_TYPE
    ]
/]

[#macro shared_extension_cognitoqs_iam_deployment_setup occurrence ]
    [#assign core = occurrence.Core ]
    [#assign assumeRoleId = formatResourceId( AWS_IAM_ROLE_RESOURCE_TYPE, core.Id, "assume" ) ]

    [#if _context.Assignment == "allusers" ]
        [@Policy
            [
                getPolicyStatement(
                    [
                        "sts:AssumeRole"
                    ],
                    getReference(assumeRoleId, ARN_ATTRIBUTE_TYPE),
                    "",
                    {}
                )
            ]
        /]
    [/#if]

    [#if deploymentSubsetRequired("iam", true) && isPartOfCurrentDeploymentUnit(assumeRoleId)]
        [@createRole
            id=assumeRoleId
            trustedAccounts=[ accountObject.ProviderId ]
            policies=[
                getPolicyDocument(
                    getPolicyStatement(
                        [
                            "quicksight:CreateUser"
                        ],
                        "*"
                    ),
                    "quicksight"
                )
            ]
        /]
    [/#if]

[/#macro]
