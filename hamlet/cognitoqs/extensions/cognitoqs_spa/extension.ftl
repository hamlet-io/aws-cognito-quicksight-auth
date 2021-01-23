[#ftl]

[@addExtension
    id="cognitoqs_spa"
    aliases=[
        "_cognitoqs_spa"
    ]
    description=[
        "SPA configuration settings for cognito quicksight configuration"
    ]
    supportedTypes=[
        SPA_COMPONENT_TYPE
    ]
/]

[#macro shared_extension_cognitoqs_spa_deployment_setup occurrence ]
    [@DefaultLinkVariables enabled=false /]
    [@DefaultCoreVariables enabled=false /]
    [@DefaultEnvironmentVariables enabled=false /]
    [@DefaultBaselineVariables enabled=false /]

    [#if (_context.Links["cloudrole"]!{})?has_content ]

        [#assign assumeRoleId = formatResourceId( AWS_IAM_ROLE_RESOURCE_TYPE, (_context.Links["cloudrole"].Core.Id)!"", "assume" ) ]
        [@debug message="cloudRoleLink" context=assumeRoleId enabled=true /]
        [@Settings
            {
                "ROLE_ARN" : getExistingReference(assumeRoleId, ARN_ATTRIBUTE_TYPE),
                "SESSION_DURATION" : 3600
            }
        /]
    [/#if]

    [@AltSettings
        {
            "REGION" : "AUTH_REGION",
            "USER_POOL_ID" : "AUTH_USER_POOL",
            "USER_POOL_FQDN" : "AUTH_UI_FQDN",
            "CLIENT_ID" : "AUTH_CLIENT",
            "IDENTITY_POOL_ID" : "FEDERATEDROLE_ID",
            "API_URL" : "API_URL",
            "APP_SIGN_IN_URL" : "CDN_URL",
            "APP_SIGN_OUT_URL" : "CDN_URL"
        }
    /]
[/#macro]
