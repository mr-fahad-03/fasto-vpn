import { AdViewModel } from "../models/AdView";

export async function recordAdView(params: {
  userId?: string;
  placement: string;
  provider?: string;
  revenueMicros?: number;
}): Promise<void> {
  await AdViewModel.create({
    user: params.userId,
    placement: params.placement,
    provider: params.provider ?? "admob",
    revenueMicros: params.revenueMicros ?? 0,
    viewedAt: new Date(),
  });
}
