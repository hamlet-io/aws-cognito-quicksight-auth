[#ftl]

[@addExtension
    id="cognitoqs_auth"
    aliases=[
        "_cognitoqs_auth"
    ]
    description=[
        "Cognito client auth urls based on CDN"
    ]
    supportedTypes=[
        EXTERNALSERVICE_COMPONENT_TYPE
    ]
/]

[#macro shared_extension_cognitoqs_auth_deployment_setup occurrence ]

    [#assign cdnUrl = (_context.Links["cdn"].State.Attributes["URL"])!""]

    [@Settings
        {
            "AUTH_CALLBACK_URL" : cdnUrl,
            "AUTH_SIGNOUT_URL" : cdnUrl
        }
    /]
[/#macro]
