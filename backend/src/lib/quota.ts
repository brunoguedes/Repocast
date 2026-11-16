/**
 * Beta quota: generation minutes per user per calendar month (UTC). Metering
 * minutes rather than repos keeps ElevenLabs' per-character cost bounded.
 */
export const MONTHLY_QUOTA_MINUTES = Number(process.env.MONTHLY_QUOTA_MINUTES ?? 60);

export function monthKey(date = new Date()): string {
  return date.toISOString().slice(0, 7);
}

export function roundMinutes(seconds: number): number {
  return Math.round((seconds / 60) * 10) / 10;
}
