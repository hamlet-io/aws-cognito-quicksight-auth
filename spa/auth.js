// Load Config
function getConfig (cb) {
    const defaultConfig = {
        IDENTITY_POOL_ID: 'us-east-1:XXXXXXXXXXXXXXXXXXXXXXXXXXXXX', //Cognito Identity Pool
        REGION: 'us-east-1',
        USER_POOL_ID: 'us-east-1_XXXXXXXX',                         //Cognito User Pool
        USER_POOL_FQDN: 'XXXXXX.auth.us-east-1.amazoncognito.com',  // Cognito App Domain Name
        CLIENT_ID: 'XXXXXXXXXXXXXXXXX',                             //Cognito User Pool App
        API_URL: 'https://XXXXXXXXXXX.execute-api.us-east-1.amazonaws.com/prod', // API Endpoint Url
        APP_SIGN_IN_URL: 'https://d12345example.cloudfront.net',    // CloudFront Url
        APP_SIGN_OUT_URL: 'https://d12345example.cloudfront.net'    // Cloudfront Url

    };
    if(['localhost', '127.0.0.1'].indexOf(window.location.hostname) !== -1) {
        cb(defaultConfig);
    } else {
        var oReq = new XMLHttpRequest();
        oReq.addEventListener("load", function () {
            cb(JSON.parse(this.responseText));
        });
        oReq.open("GET", "/config/config.json");
        oReq.send();
    }
}

getConfig(function (config) {
    window.AppConfig = config;
});

let identityPool = window.AppConfig.IDENTITY_POOL_ID;
let region = window.AppConfig.REGION;
let poolId = window.AppConfig.USER_POOL_ID;
let clientId = window.AppConfig.CLIENT_ID;
let appDomain = window.AppConfig.USER_POOL_FQDN;
let endpoint = window.AppConfig.API_URL;
let authData = {
    ClientId : clientId,
    AppWebDomain : appDomain,
    TokenScopesArray : ['openid'],
    RedirectUriSignIn : window.AppConfig.APP_SIGN_IN_URL,
    RedirectUriSignOut : window.AppConfig.APP_SIGN_OUT_URL,
};
