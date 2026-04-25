import { UsageLogModel } from "../models/UsageLog";

export async function logActivity(params: {
  userId?: string;
  eventType: string;
  metadata?: Record<string, unknown>;
  ip?: string;
  userAgent?: string;
}): Promise<void> {
  await UsageLogModel.create({
    user: params.userId,
    eventType: params.eventType,
    metadata: params.metadata,
    ip: params.ip,
    userAgent: params.userAgent,
  });
}
