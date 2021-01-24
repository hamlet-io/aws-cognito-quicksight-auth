# CognitoQS Plugin

The Cognito QS Hamlet plugin creates a deployment of the solution outlined in this repo.

The components in the deployment include:

- SPA which acts as the login portal
- API Gateway + Lambda which performs an authentication check using Cognito integration to confirm user access
- Identity Pool which translates Cognito User credentials into an IAM role with access to QuickSight and its self provisioning policy

You need to provide a user pool client through the userpoolClientLink which enables the integration between cognito and this plugin
The client provided in the module configuration should also be configured with the deployment profile that is provided in the plugin. This will configure the client for use with the module

## Usage

1. In your segment file install the plugin - Update the Ref based on the version you want to install. The AWS plugin is also required

    ```json
    {
        "Segment" : {
            "Plugins" : {
                "cognitoqs" : {
                    "Enabled" : true,
                    "Name" : "cognitoqs",
                    "Priority" : 200,
                    "Required" : true,
                    "Source" : "git",
                    "Source:git" : {
                        "Url" : "https://github.com/hamlet-io/aws-cognito-quicksight-auth",
                        "Ref" : "v1.0.0",
                        "Path" : "hamlet/cognitoqs"
                    }
                },
                "aws" : {
                    "Enabled" : true,
                    "Name" : "aws",
                    "Priority" : 10,
                    "Required" : true,
                    "Source" : "git",
                    "Source:git" : {
                        "Url" : "https://github.com/hamlet-io/engine-plugin-aws",
                        "Ref" : "master",
                        "Path" : "aws/"
                    }
                }
            }
        }
    }
    ```

2. Create a user pool with a client specifically for the quicksight pool. In your solution add the pool. This is a basic pool, feel free to extend it as required

    ```json
    {
        "Tier" : {
            "mgmt" : {
                "Components" : {
                    "pool" : {
                        "userpool" : {
                            "deployment:Unit" : "pool",
                            "Instances" : {
                                "default" : {}
                            },
                            "MFA" : "optional",
                            "UnusedAccountTimeout" : 7,
                            "AdminCreatesUser" : true,
                            "Username" : {
                                "CaseSensitive" : false,
                                "Attributes" : [ "email" ],
                                "Aliases" : []
                            },
                            "HostedUI" : {},
                            "DefaultClient" : false,
                            "Schema" : {
                                "email" : {
                                    "DataType" : "String",
                                    "Mutable" : true,
                                    "Required" : true
                                },
                            },
                            "Clients" : {
                                "qs" : {
                                    "AuthProviders" : [ "COGNITO" ]
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    ```

3. Add an instance of the module ( you can add multiple instances if you need )

    ```json
    {
        "Segment" : {
            "Modules" : {
                "qs" : {
                    "Provider" : "cognitoqs",
                    "Name" : "cognito_quicksight",
                    "Parameters" : {
                        "id" : {
                            "Key" : "id",
                            "Value" : "qs"
                        },
                        "tier" : {
                            "Key" : "tier",
                            "Value" : "api"
                        },
                        "userPool" : {
                            "Key" : "userPoolClientLink",
                            "Value" : {
                                "Tier" : "mgmt",
                                "Component" : "pool",
                                "Client" : "qs",
                                "Instance" : "",
                                "Version" : ""
                            }
                        },
                        "quicksightUserRole" : {
                            "Key" : "quicksightUserRole",
                            "Value" : "User"
                        }
                    }
                }
            }
        }
    }

    ```

4. Update the userpool client to use the deployment profile provided in the module

   ```json
    {
        "Tier" : {
            "mgmt" : {
                "Components" : {
                    "pool" : {
                        "userpool" : {
                            "Clients" : {
                                "qs" : {
                                    "AuthProviders" : [ "COGNITO" ],
                                    "Profiles" : {
                                        "Deployment" : [ "qs_cognitoqs" ]
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    ```

    The profile name is created based on the id provided in the module and a configurable suffix, by default `_cognitoqs` so here it is `qs_cognitoqs`
