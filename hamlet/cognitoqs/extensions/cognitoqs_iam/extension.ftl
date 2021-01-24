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

    [#local quickSightPolicy = []]

    [#switch (_context.DefaultEnvironment["QUICKSIGHT_ROLE"])!"" ]
        [#case "Admin"]
            [#local quickSightPolicy +=
                [
                    getPolicyDocument(
                        [
                            getPolicyStatement(
                                [
                                    "quicksight:CreateAdmin",
                                    "quicksight:Subscribe"
                                ]
                                "*"
                            ),
                            getPolicyStatement(
                                [
                                    "quicksight:Unsubscribe"
                                ],
                                "*",
                                "",
                                "",
                                false
                            )
                        ],
                        "quicksight-admin"
                    )
                ]]
            [#break]
        [#case "User"]
            [#local quickSightPolicy += [
                    getPolicyDocument(
                        [
                            getPolicyStatement(
                                [
                                    "quicksight:CreateUser",
                                    "quicksight:Subscribe"
                                ]
                                "*"
                            ),
                            getPolicyStatement(
                                [
                                    "quicksight:Unsubscribe"
                                ],
                                "*",
                                "",
                                "",
                                false
                            )
                        ],
                        "quicksight-user"
                    )
                ]]
            [#break]
        [#case "Reader"]
            [#local quickSightPolicy += [
                    getPolicyDocument(
                        getPolicyStatement(
                            [
                                "quicksight:CreateReader"
                            ]
                            "*"
                        ),
                        "quicksight-reader"
                    )
                ]]
            [#break]
    [/#switch]

    [#if deploymentSubsetRequired("iam", true) && isPartOfCurrentDeploymentUnit(assumeRoleId)]
        [@createRole
            id=assumeRoleId
            trustedAccounts=[ accountObject.ProviderId ]
            policies=quickSightPolicy
        /]
    [/#if]

[/#macro]
