import type { PreSignUpTriggerEvent } from "aws-lambda";
import { links } from "../lib/resources.js";

/**
 * Cloud generation is a closed beta until subscriptions ship: only emails in
 * the BetaEmails secret (comma-separated, `*` for everyone) can sign up.
 * With Sign in with Apple's "Hide My Email", add the relay address.
 */
export async function handler(event: PreSignUpTriggerEvent): Promise<PreSignUpTriggerEvent> {
  const allowed = links.BetaEmails.value
    .split(",")
    .map((email) => email.trim().toLowerCase())
    .filter(Boolean);
  const email = (event.request.userAttributes.email ?? "").toLowerCase();
  if (!allowed.includes("*") && !allowed.includes(email)) {
    throw new Error("Repocast cloud generation is invite-only during the beta.");
  }
  return event;
}
