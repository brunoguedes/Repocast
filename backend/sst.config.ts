/// <reference path="./.sst/platform/config.d.ts" />

/**
 * Repocast cloud tour generation. Index runs eagerly when a repo is added;
 * each episode runs lazily through EpisodeFlow (Script → Audio) when a
 * listener taps Generate. Output is a narration package in S3 — the format
 * the app's NarrationImporter already plays (see ../CLAUDE.md).
 */
export default $config({
  app(input) {
    return {
      name: "repocast",
      home: "aws",
      removal: input?.stage === "production" ? "retain" : "remove",
      protect: input?.stage === "production",
    };
  },
  async run() {
    // Secrets — set per stage with `npx sst secret set <Name> <value>`.
    const gitHubToken = new sst.Secret("GitHubToken", "");
    const elevenLabsApiKey = new sst.Secret("ElevenLabsApiKey");
    const elevenLabsVoiceId = new sst.Secret("ElevenLabsVoiceId");
    const betaEmails = new sst.Secret("BetaEmails", "");
    // Sign in with Apple (developer.apple.com ▸ Identifiers ▸ Services IDs, plus a Sign in with Apple key).
    const appleServicesId = new sst.Secret("AppleServicesId");
    const appleTeamId = new sst.Secret("AppleTeamId");
    const appleKeyId = new sst.Secret("AppleKeyId");
    const applePrivateKey = new sst.Secret("ApplePrivateKey");

    const table = new sst.aws.Dynamo("Table", {
      fields: { pk: "string", sk: "string" },
      primaryIndex: { hashKey: "pk", rangeKey: "sk" },
    });

    const bucket = new sst.aws.Bucket("Episodes", {
      transform: {
        bucket: (args) => {
          args.forceDestroy = $app.stage !== "production";
        },
      },
    });
    new aws.s3.BucketLifecycleConfigurationV2("EpisodesLifecycle", {
      bucket: bucket.name,
      rules: [{ id: "expire-scripts", status: "Enabled", filter: { prefix: "scripts/" }, expiration: { days: 90 } }],
    });

    // Claude on Amazon Bedrock. Enable model access for the region first.
    const bedrock = {
      environment: {
        BEDROCK_MODEL_ID: process.env.BEDROCK_MODEL_ID ?? "anthropic.claude-opus-5",
        ...(process.env.BEDROCK_REGION ? { BEDROCK_REGION: process.env.BEDROCK_REGION } : {}),
      },
      permissions: [
        {
          actions: ["bedrock:InvokeModel", "bedrock:InvokeModelWithResponseStream", "bedrock-mantle:*"],
          resources: ["*"],
        },
      ],
    };
    const prompts = [{ from: "../shared/prompts", to: "prompts" }];

    const index = new sst.aws.Function("Index", {
      handler: "src/steps/index.handler",
      timeout: "5 minutes",
      link: [table, gitHubToken],
      copyFiles: prompts,
      ...bedrock,
    });

    const scriptFn = new sst.aws.Function("Script", {
      handler: "src/steps/script.handler",
      timeout: "10 minutes",
      link: [table, bucket, gitHubToken],
      copyFiles: prompts,
      ...bedrock,
    });
    const audioFn = new sst.aws.Function("Audio", {
      handler: "src/steps/audio.handler",
      timeout: "15 minutes",
      memory: "1024 MB",
      link: [table, bucket, elevenLabsApiKey, elevenLabsVoiceId],
    });
    const failFn = new sst.aws.Function("Fail", {
      handler: "src/steps/fail.handler",
      link: [table],
    });

    // Keep the job in a variable so the catch can report which episode failed.
    const begin = sst.aws.StepFunctions.pass({ name: "Begin", assign: { job: "{% $states.input %}" } });
    const job = {
      repo: "{% $job.repo %}",
      commit: "{% $job.commit %}",
      type: "{% $job.type %}",
      sub: "{% $job.sub %}",
      reservedMinutes: "{% $job.reservedMinutes %}",
    };
    const markFailed = sst.aws.StepFunctions.lambdaInvoke({
      name: "MarkFailed",
      function: failFn,
      payload: { job: "{% $job %}", error: "{% $states.input %}" },
    }).next(sst.aws.StepFunctions.fail({ name: "Failed" }));
    const retry = { interval: "10 seconds" as const, maxAttempts: 2, backoffRate: 3 };
    const script = sst.aws.StepFunctions.lambdaInvoke({ name: "Script", function: scriptFn, payload: job })
      .retry(retry)
      .catch(markFailed);
    const audio = sst.aws.StepFunctions.lambdaInvoke({ name: "Audio", function: audioFn, payload: job })
      .retry(retry)
      .catch(markFailed);
    const episodeFlow = new sst.aws.StepFunctions("EpisodeFlow", {
      definition: begin.next(script).next(audio).next(sst.aws.StepFunctions.succeed({ name: "Done" })),
    });

    // Cognito: Sign in with Apple through the hosted UI, PKCE from the app.
    const users = new sst.aws.CognitoUserPool("Users", {
      usernames: ["email"],
      triggers: {
        preSignUp: { handler: "src/auth/preSignUp.handler", link: [betaEmails] },
      },
    });
    const apple = users.addIdentityProvider("Apple", {
      type: "apple",
      details: {
        client_id: appleServicesId.value,
        team_id: appleTeamId.value,
        key_id: appleKeyId.value,
        private_key: applePrivateKey.value,
        authorize_scopes: "email name",
      },
      attributes: { email: "email" },
    });
    const appClient = users.addClient("App", {
      providers: [apple.providerName],
      callbackUrls: ["repocast://auth"],
      transform: {
        client: (args) => {
          args.allowedOauthFlows = ["code"];
          args.allowedOauthScopes = ["openid", "email"];
          args.logoutUrls = ["repocast://auth"];
          args.generateSecret = false;
          args.refreshTokenValidity = 30;
          args.tokenValidityUnits = { refreshToken: "days", accessToken: "minutes", idToken: "minutes" };
          args.accessTokenValidity = 60;
          args.idTokenValidity = 60;
        },
      },
    });
    const domain = new aws.cognito.UserPoolDomain("UsersDomain", {
      userPoolId: users.id,
      domain: `repocast-${$app.stage}`,
    });

    const api = new sst.aws.ApiGatewayV2("Api", {
      transform: {
        stage: (args) => {
          args.defaultRouteSettings = { throttlingBurstLimit: 20, throttlingRateLimit: 10 };
        },
      },
    });
    const authorizer = api.addAuthorizer({
      name: "Cognito",
      jwt: {
        issuer: $interpolate`https://cognito-idp.${aws.getRegionOutput().name}.amazonaws.com/${users.id}`,
        audiences: [appClient.id],
      },
    });
    const auth = { auth: { jwt: { authorizer: authorizer.id } } };
    const routeLinks = [table, bucket];

    api.route("POST /repos", { handler: "src/api/repos.add", link: [...routeLinks, index, gitHubToken] }, auth);
    api.route("GET /repos/{owner}/{name}/tour", { handler: "src/api/repos.tour", link: routeLinks }, auth);
    api.route(
      "POST /repos/{owner}/{name}/episodes/{type}",
      { handler: "src/api/episodes.start", link: [...routeLinks, episodeFlow] },
      auth,
    );
    api.route("GET /repos/{owner}/{name}/episodes/{type}", { handler: "src/api/episodes.status", link: routeLinks }, auth);
    api.route("GET /me", { handler: "src/api/me.get", link: routeLinks }, auth);
    api.route(
      "DELETE /me",
      {
        handler: "src/api/me.remove",
        link: [...routeLinks, users],
        permissions: [{ actions: ["cognito-idp:AdminDeleteUser"], resources: [users.arn] }],
      },
      auth,
    );

    // Values for ios/Config/Backend.xcconfig.
    return {
      API_BASE_URL: api.url,
      COGNITO_DOMAIN: $interpolate`${domain.domain}.auth.${aws.getRegionOutput().name}.amazoncognito.com`,
      COGNITO_CLIENT_ID: appClient.id,
    };
  },
});
