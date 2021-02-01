[#ftl]

[@addModule
    name="cognito_quicksight"
    description="Creates an API and SPA for cognito based access to AWS Quicksight"
    provider=COGNITOQS_PROVIDER
    properties=[
        {
            "Names" : "id",
            "Description" : "A unique id for this instance of the api",
            "Type" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "tier",
            "Description" : "The tier the components will belong to",
            "Type" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "instance",
            "Description" : "The instance id of the components",
            "Type" : STRING_TYPE,
            "Default" : "default"
        },
        {
            "Names" : "quicksightUserRole",
            "Description" : "The QuickSight role assigned to users who login through cognito",
            "Type" : STRING_TYPE,
            "Values" : [ "Admin", "User", "Reader" ],
            "Default" : "Reader"
        },
        {
            "Names" : "userPoolClientLink",
            "Description" : "Link to a userpool client which will be used as the authorisation source",
            "AttributeSet" : LINK_ATTRIBUTESET_TYPE
        },
        {
            "Names" : "cogntioDeploymentProfileSuffix",
            "Description" : "The suffix ( added to the id ) for the deployment profile which configures the userpool client",
            "Type" : STRING_TYPE,
            "Default" : "_cognitoqs"
        },
        {
            "Names" : "lambdaImageUrl",
            "Description" : "The url to the lambda zip image",
            "Type" : STRING_TYPE,
            "Default" : "https://github.com/hamlet-io/aws-cognito-quicksight-auth/releases/download/v0.0.2/lambda.zip"
        },
        {
            "Names" : "lambdaImageHash",
            "Description" : "The sha1 hash of the lambda zip image",
            "Type" : STRING_TYPE,
            "Default" : "f5eb03403d328d8d8d2a3719c857ac16d9d4b925"
        },
        {
            "Names" : "spaImageUrl",
            "Description" : "The url to the spa zip image",
            "Type" : STRING_TYPE,
            "Default" : "https://github.com/hamlet-io/aws-cognito-quicksight-auth/releases/download/v0.0.2/spa.zip"
        },
        {
            "Names" : "spaImageHash",
            "Description" : "The sha1 hash of the spa zip image",
            "Type" : STRING_TYPE,
            "Default" : "1c47dbf9228c1bff92daaa3f11d6b59abc4bb42f"
        }
    ]
/]


[#macro cognitoqs_module_cognito_quicksight
        id
        tier
        instance
        userPoolClientLink
        quicksightUserRole
        cogntioDeploymentProfileSuffix
        lambdaImageUrl
        lambdaImageHash
        spaImageUrl
        spaImageHash
]

    [#local product = getActiveLayer(PRODUCT_LAYER_TYPE) ]
    [#local environment = getActiveLayer(ENVIRONMENT_LAYER_TYPE)]
    [#local segment = getActiveLayer(SEGMENT_LAYER_TYPE)]
    [#local instance = (instance == "default")?then("", instance)]
    [#local namespace = formatName(product["Name"], environment["Name"], segment["Name"])]

    [#local apiId = formatName(id, "apigateway") ]
    [#local apiSettingsNamespace = formatName(namespace, tier, apiId, instance)]
    [#local apiDefinition = formatId(tier,id)]
    [#local lambdaId = formatName(id, "lambda") ]
    [#local cdnId = formatName(id, "cdn") ]
    [#local spaId = formatName(id, "spa") ]
    [#local authId = formatName(id, "externalservice", "auth")]
    [#local federatedRoleId = formatName(id, "federatedrole")]
    [#local federatedRoleSettingsNamespace = formatName( namespace, tier, id, "allusers")]

    [#local userPoolLink = {
        "Tier" : (userPoolClientLink.Tier)!"",
        "Component" : (userPoolClientLink.Component)!""
    } +
    (userPoolClientLink.Instance??)?then(
        {
            "Instance" : userPoolClientLink.Instance
        },
        {}
    ) +
    (userPoolClientLink.Version??)?then(
        {
            "Version" : userPoolClientLink.Version
        },
        {}
    )]


    [#-- API Definition for API Gateway --]
    [@addDefinition
        definition={
            apiDefinition :     {
                "openapi": "3.0.0",
                "components": {
                    "schemas": {},
                    "securitySchemes": {}
                },
                "info": {
                    "title": "Cognito QuickSight API",
                    "description": "Basic callback API for Cogntio Quicksight",
                    "version": "1.0.0"
                },
                "paths": {
                    "/": {
                        "post": {
                            "operationId": "cognito-quicksight",
                            "summary": "LoopBack Response",
                            "responses": {
                                "200": {
                                    "description": "Loopback",
                                    "content": {
                                        "application/json": {
                                            "schema": {
                                            "type": "object"
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    /]

    [#-- Cloud Role configuration --]
    [@loadModule
        settingSets=[
            {
                "Type" : "Settings",
                "Scope" : "Products",
                "Namespace" : federatedRoleSettingsNamespace,
                "Settings" : {
                    "QUICKSIGHT_ROLE" : quicksightUserRole
                }
            }
        ]

    /]

    [#-- API Configuration to map Specification to Lambda Resources --]
    [@loadModule
        settingSets=[
            {
                "Type" : "Builds",
                "Scope" : "Products",
                "Namespace" : apiSettingsNamespace,
                "Settings" : {
                    "Commit" : "_module_",
                    "Formats" : ["openapi"]
                }
            },
            {
                "Type" : "Settings",
                "Scope" : "Products",
                "Namespace" : apiSettingsNamespace,
                "Settings" : {
                    "apigw" : {
                        "Internal" : true,
                        "Value" : {
                            "Type" : "lambda",
                            "Proxy" : false,
                            "Variable" : "API_HANDLER_LAMBDA",
                            "SecuritySchemes" : {
                                "oidc" : {
                                    "Type" : "openIdConnect",
                                    "Authorizer" : {
                                        "Type" : "cognito_user_pools",
                                        "Default" : true
                                    }
                                }
                            },
                            "OptionsSecurity" : "disabled",
                            "Security" : {
                                "userpool" : {
                                    "Enabled" : true
                                }
                            },
                            "Patterns" : [
                                {
                                    "Path" : "/",
                                    "Verb" : "options"
                                }
                            ]
                        }
                    }
                }
            }
        ]
    /]

    [#-- Solution Configuration --]
    [@loadModule
        blueprint={
            "Tiers" : {
                tier : {
                    "Components" : {
                        cdnId: {
                            "cdn" : {
                                "deployment:Unit" : cdnId,
                                "Instances" : {
                                    instance : {
                                    }
                                },
                                "Pages" : {
                                    "Root" : "index.html",
                                    "Error" : ""
                                },
                                "Routes" : {
                                    "default" : {
                                        "PathPattern" : "_default",
                                        "Origin" : {
                                            "Link" : {
                                                "Tier" : tier,
                                                "Component" : spaId
                                            }
                                        },
                                        "Compress" : true
                                    }
                                }
                            }
                        },
                        authId : {
                            "externalservice" : {
                                "deployment:Unit" : authId,
                                "Instances" : {
                                    instance: {
                                    }
                                },
                                "Extensions" : [ "_cognitoqs_auth" ],
                                "Links" : {
                                    "cdn" : {
                                        "Tier" : tier,
                                        "Component" : cdnId,
                                        "Route" : "default"
                                    }
                                },
                                "Profiles" : {
                                    "Placement"  : "external"
                                }
                            }
                        },
                        spaId : {
                            "spa" : {
                                "deployment:Unit" : spaId,
                                "Instances" : {
                                    instance : {
                                    }
                                },
                                "Extensions" : [ "_cognitoqs_spa" ],
                                "Image" : {
                                    "Source" : "url",
                                    "UrlSource" : {
                                        "Url" : spaImageUrl,
                                        "ImageHash" : spaImageHash
                                    }
                                },
                                "Links" : {
                                    "cdn" : {
                                        "Tier" : tier,
                                        "Component" : cdnId,
                                        "Route" : "default",
                                        "Direction" : "inbound"
                                    },
                                    "auth" : userPoolClientLink,
                                    "cloudrole" : {
                                        "Tier"  : tier,
                                        "Component" : federatedRoleId,
                                        "Assignment" : "allusers"
                                    },
                                    "federatedrole" : {
                                        "Tier"  : tier,
                                        "Component" : federatedRoleId
                                    },
                                    "api" : {
                                        "Tier" : tier,
                                        "Component" : apiId
                                    }
                                }
                            }
                        },
                        apiId : {
                            "Title": "SPA QS API",
                            "apigateway": {
                                "deployment:Unit" : apiId,
                                "Instances": {
                                    instance : {
                                    }
                                },
                                "IPAddressGroups" : ["_global"],
                                "Links": {
                                    "api": {
                                        "Tier": tier,
                                        "Component": lambdaId,
                                        "Function": "handler"
                                    },
                                    "userpool" : userPoolLink
                                }
                            }
                        },
                        lambdaId : {
                            "Title": "SPA QS API Implementation",
                            "lambda": {
                                "deployment:Unit" : lambdaId,
                                "Instances": {
                                    instance: {
                                        "DeploymentUnits": [
                                            lambdaId
                                        ]
                                    }
                                },
                                "Image" : {
                                    "Source" : "url",
                                    "UrlSource" : {
                                        "Url" : lambdaImageUrl,
                                        "ImageHash" : lambdaImageHash
                                    }
                                },
                                "Extensions": [ "_noenv" ],
                                "Functions": {
                                    "handler": {
                                        "Handler": "lambda/index.handler",
                                        "RunTime": "nodejs12.x",
                                        "MemorySize": 128,
                                        "PredefineLogGroup": true,
                                        "VPCAccess": false,
                                        "Timeout": 29,
                                        "Links": {
                                            "api": {
                                                "Tier": tier,
                                                "Component": apiId,
                                                "Direction": "inbound"
                                            }
                                        }
                                    }
                                }
                            }
                        },
                        federatedRoleId : {
                            "federatedrole" : {
                                "deployment:Unit" : federatedRoleId,
                                "Instances" : {
                                    instance : {}
                                },
                                "NoMatchBehaviour" : "Deny",
                                "Extensions" : [ "_cognitoqs_iam" ],
                                "Assignments" : {
                                    "allusers" : {
                                        "Type" : "Authenticated"
                                    }
                                },
                                "Links" : {
                                    "auth" : userPoolClientLink
                                }
                            }
                        }
                    }
                }
            },
            "DeploymentProfiles" : {
                id + cogntioDeploymentProfileSuffix : {
                    "Modes" : {
                        "*" : {
                            "userpoolclient" : {
                                "ClientGenerateSecret" : false,
                                "OAuth" : {
                                    "Scopes" : [
                                        "openid"
                                    ],
                                    "Flows" : [ "implicit" ]
                                },
                                "Links" : {
                                    "authSpa" : {
                                        "Tier" : tier,
                                        "Component" : authId
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    /]

[/#macro]
