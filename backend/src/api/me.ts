import { AdminDeleteUserCommand, CognitoIdentityProviderClient } from "@aws-sdk/client-cognito-identity-provider";
import { DeleteCommand, QueryCommand } from "@aws-sdk/lib-dynamodb";
import { doc, getMinutesUsed } from "../lib/db.js";
import { MONTHLY_QUOTA_MINUTES, monthKey } from "../lib/quota.js";
import { links } from "../lib/resources.js";
import { caller, json, type ApiEvent, type ApiResult } from "./http.js";

const cognito = new CognitoIdentityProviderClient({});

/** GET /me: this month's cloud minutes. */
export async function get(event: ApiEvent): Promise<ApiResult> {
  const month = monthKey();
  return json(200, {
    month,
    minutesUsed: await getMinutesUsed(caller(event).sub, month),
    minutesQuota: MONTHLY_QUOTA_MINUTES,
  });
}

/**
 * DELETE /me: removes the Cognito user and every USER# row (App Store
 * account-deletion requirement). Shared episodes aren't the user's data and
 * stay.
 */
export async function remove(event: ApiEvent): Promise<ApiResult> {
  const { sub, username } = caller(event);
  const { Items = [] } = await doc.send(
    new QueryCommand({
      TableName: links.Table.name,
      KeyConditionExpression: "pk = :pk",
      ExpressionAttributeValues: { ":pk": `USER#${sub}` },
    }),
  );
  for (const item of Items) {
    await doc.send(new DeleteCommand({ TableName: links.Table.name, Key: { pk: item.pk, sk: item.sk } }));
  }
  await cognito.send(new AdminDeleteUserCommand({ UserPoolId: links.Users.id, Username: username }));
  return { statusCode: 204 };
}
