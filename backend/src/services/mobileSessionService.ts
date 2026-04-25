import crypto from "crypto";
import mongoose, { ClientSession } from "mongoose";
import { AdViewModel } from "../models/AdView";
import { DeviceSessionDoc, DeviceSessionModel } from "../models/DeviceSession";
import { SubscriptionDoc, SubscriptionModel } from "../models/Subscription";
import { UsageLogModel } from "../models/UsageLog";
import { UserDoc, UserModel } from "../models/User";

type CreateGuestParams = {
  deviceId?: string;
  platform?: string;
  ip?: string;
  userAgent?: string;
};

type ResolveOrMergeFirebaseIdentityParams = {
  firebaseUid: string;
  email?: string;
  displayName?: string;
  guestSessionId?: string;
};

type ResolveOrMergeFirebaseIdentityResult = {
  user: UserDoc;
  mergedGuestUserId?: string;
};

function transactionUnsupported(error: unknown): boolean {
  const message = error instanceof Error ? error.message : "";
  return (
    message.includes("Transaction numbers are only allowed") ||
    message.toLowerCase().includes("replica set")
  );
}

async function withTransactionFallback<T>(fn: (session?: ClientSession) => Promise<T>): Promise<T> {
  const session = await mongoose.startSession();

  try {
    let result: T | undefined;

    await session.withTransaction(async () => {
      result = await fn(session);
    });

    if (result === undefined) {
      throw new Error("Transaction did not produce a result");
    }

    return result;
  } catch (error) {
    if (transactionUnsupported(error)) {
      return fn(undefined);
    }

    throw error;
  } finally {
    await session.endSession();
  }
}

function subscriptionPriority(doc: SubscriptionDoc): {
  manualOverride: number;
  activePremium: number;
  futureExpiryMs: number;
  updatedAtMs: number;
} {
  const now = Date.now();
  const manualOverride = doc.manualOverride?.isActive ? 1 : 0;
  const expiryMs = doc.expiresAt ? doc.expiresAt.getTime() : 0;
  const activePremium = doc.isPremium && (!doc.expiresAt || expiryMs > now) ? 1 : 0;
  const futureExpiryMs = expiryMs > now ? expiryMs : 0;
  const updatedAtMs = doc.updatedAt ? doc.updatedAt.getTime() : 0;

  return {
    manualOverride,
    activePremium,
    futureExpiryMs,
    updatedAtMs,
  };
}

function shouldKeepLeft(left: SubscriptionDoc, right: SubscriptionDoc): boolean {
  const a = subscriptionPriority(left);
  const b = subscriptionPriority(right);

  if (a.manualOverride !== b.manualOverride) return a.manualOverride > b.manualOverride;
  if (a.activePremium !== b.activePremium) return a.activePremium > b.activePremium;
  if (a.futureExpiryMs !== b.futureExpiryMs) return a.futureExpiryMs > b.futureExpiryMs;
  return a.updatedAtMs >= b.updatedAtMs;
}

async function saveUser(doc: UserDoc, session?: ClientSession): Promise<UserDoc> {
  if (session) {
    await doc.save({ session });
    return doc;
  }

  await doc.save();
  return doc;
}

async function createUser(data: Partial<UserDoc>, session?: ClientSession): Promise<UserDoc> {
  if (session) {
    const rows = await UserModel.create([data], { session });
    return rows[0] as UserDoc;
  }

  return (await UserModel.create(data)) as UserDoc;
}

async function mergeSubscriptions(sourceUserId: string, targetUserId: string, session?: ClientSession): Promise<void> {
  let sourceSubQuery = SubscriptionModel.findOne({ user: sourceUserId });
  let targetSubQuery = SubscriptionModel.findOne({ user: targetUserId });

  if (session) {
    sourceSubQuery = sourceSubQuery.session(session);
    targetSubQuery = targetSubQuery.session(session);
  }

  const [sourceSub, targetSub] = await Promise.all([sourceSubQuery, targetSubQuery]);

  if (!sourceSub) {
    return;
  }

  if (!targetSub) {
    sourceSub.user = new mongoose.Types.ObjectId(targetUserId);
    if (session) {
      await sourceSub.save({ session });
      return;
    }
    await sourceSub.save();
    return;
  }

  const keepSource = shouldKeepLeft(sourceSub, targetSub);

  if (keepSource) {
    targetSub.provider = sourceSub.provider;
    targetSub.revenueCatAppUserId = sourceSub.revenueCatAppUserId;
    targetSub.productId = sourceSub.productId;
    targetSub.entitlementId = sourceSub.entitlementId;
    targetSub.status = sourceSub.status;
    targetSub.isPremium = sourceSub.isPremium;
    targetSub.planPriceUsd = sourceSub.planPriceUsd;
    targetSub.currency = sourceSub.currency;
    targetSub.adsEnabled = sourceSub.adsEnabled;
    targetSub.expiresAt = sourceSub.expiresAt;
    targetSub.sourceEntitlementId = sourceSub.sourceEntitlementId;
    targetSub.sourceStatus = sourceSub.sourceStatus;
    targetSub.sourceIsPremium = sourceSub.sourceIsPremium;
    targetSub.sourceAdsEnabled = sourceSub.sourceAdsEnabled;
    targetSub.manualOverride = sourceSub.manualOverride;
    targetSub.lastEventType = sourceSub.lastEventType;
    targetSub.lastEventId = sourceSub.lastEventId;
    targetSub.lastEventAt = sourceSub.lastEventAt;
    targetSub.rawEvent = sourceSub.rawEvent;
  }

  if (session) {
    await targetSub.save({ session });
    await sourceSub.deleteOne({ session });
    return;
  }

  await targetSub.save();
  await sourceSub.deleteOne();
}

async function mergeGuestIntoMobileUser(params: {
  sourceGuestUser: UserDoc;
  targetMobileUser: UserDoc;
}): Promise<void> {
  await withTransactionFallback(async (session) => {
    const sourceUserId = params.sourceGuestUser._id.toString();
    const targetUserId = params.targetMobileUser._id.toString();

    const moveQueryOpts = session ? { session } : undefined;

    await Promise.all([
      DeviceSessionModel.updateMany({ user: sourceUserId }, { $set: { user: targetUserId } }, moveQueryOpts),
      UsageLogModel.updateMany({ user: sourceUserId }, { $set: { user: targetUserId } }, moveQueryOpts),
      AdViewModel.updateMany({ user: sourceUserId }, { $set: { user: targetUserId } }, moveQueryOpts),
    ]);

    await mergeSubscriptions(sourceUserId, targetUserId, session);

    params.sourceGuestUser.isActive = false;
    params.sourceGuestUser.mergedIntoUserId = params.targetMobileUser._id;
    params.sourceGuestUser.mergedAt = new Date();
    params.sourceGuestUser.lastSeenAt = new Date();

    await saveUser(params.sourceGuestUser, session);
  });
}

async function promoteGuestUserToMobile(params: {
  guestUser: UserDoc;
  firebaseUid: string;
  email?: string;
  displayName?: string;
}): Promise<UserDoc> {
  params.guestUser.mode = "mobile";
  params.guestUser.firebaseUid = params.firebaseUid;
  params.guestUser.email = params.email ?? params.guestUser.email;
  params.guestUser.displayName = params.displayName ?? params.guestUser.displayName;
  params.guestUser.lastSeenAt = new Date();
  params.guestUser.isActive = true;
  await params.guestUser.save();
  return params.guestUser;
}

export async function createGuestSession(params: CreateGuestParams): Promise<{
  user: UserDoc;
  session: DeviceSessionDoc;
}> {
  const sessionId = crypto.randomUUID();

  const user = await UserModel.create({
    mode: "guest",
    guestSessionId: sessionId,
    isActive: true,
    lastSeenAt: new Date(),
  });

  const session = await DeviceSessionModel.create({
    sessionId,
    user: user._id,
    type: "guest",
    deviceId: params.deviceId,
    platform: params.platform,
    ip: params.ip,
    userAgent: params.userAgent,
    lastActiveAt: new Date(),
  });

  return { user, session };
}

export async function resolveGuestSession(sessionId: string): Promise<{ user: UserDoc; session: DeviceSessionDoc } | null> {
  const session = await DeviceSessionModel.findOne({ sessionId, type: "guest", revokedAt: { $exists: false } });
  if (!session) return null;

  const user = await UserModel.findById(session.user);
  if (!user) return null;

  user.lastSeenAt = new Date();
  await user.save();

  session.lastActiveAt = new Date();
  await session.save();

  return { user, session };
}

export async function resolveOrMergeFirebaseIdentity(
  params: ResolveOrMergeFirebaseIdentityParams,
): Promise<ResolveOrMergeFirebaseIdentityResult> {
  const [firebaseUser, guestResolved] = await Promise.all([
    UserModel.findOne({ firebaseUid: params.firebaseUid }),
    params.guestSessionId ? resolveGuestSession(params.guestSessionId) : Promise.resolve(null),
  ]);

  const now = new Date();

  if (guestResolved && !firebaseUser) {
    const promoted = await promoteGuestUserToMobile({
      guestUser: guestResolved.user,
      firebaseUid: params.firebaseUid,
      email: params.email,
      displayName: params.displayName,
    });
    return { user: promoted };
  }

  if (!guestResolved && firebaseUser) {
    firebaseUser.email = params.email ?? firebaseUser.email;
    firebaseUser.displayName = params.displayName ?? firebaseUser.displayName;
    firebaseUser.lastSeenAt = now;
    await firebaseUser.save();
    return { user: firebaseUser };
  }

  if (guestResolved && firebaseUser) {
    if (guestResolved.user._id.equals(firebaseUser._id)) {
      firebaseUser.mode = "mobile";
      firebaseUser.email = params.email ?? firebaseUser.email;
      firebaseUser.displayName = params.displayName ?? firebaseUser.displayName;
      firebaseUser.lastSeenAt = now;
      await firebaseUser.save();
      return { user: firebaseUser };
    }

    const mergedGuestUserId = guestResolved.user._id.toString();
    await mergeGuestIntoMobileUser({
      sourceGuestUser: guestResolved.user,
      targetMobileUser: firebaseUser,
    });

    firebaseUser.mode = "mobile";
    firebaseUser.email = params.email ?? firebaseUser.email;
    firebaseUser.displayName = params.displayName ?? firebaseUser.displayName;
    firebaseUser.lastSeenAt = now;
    await firebaseUser.save();

    return {
      user: firebaseUser,
      mergedGuestUserId,
    };
  }

  const created = await createUser({
    mode: "mobile",
    firebaseUid: params.firebaseUid,
    email: params.email,
    displayName: params.displayName,
    isActive: true,
    lastSeenAt: now,
  });

  return { user: created };
}

export async function touchMobileSession(params: {
  userId: string;
  type: "guest" | "mobile";
  firebaseUid?: string;
  deviceId?: string;
  platform?: string;
  ip?: string;
  userAgent?: string;
}): Promise<DeviceSessionDoc> {
  const sessionId = crypto.randomUUID();

  return DeviceSessionModel.create({
    sessionId,
    user: params.userId,
    type: params.type,
    firebaseUid: params.firebaseUid,
    deviceId: params.deviceId,
    platform: params.platform,
    ip: params.ip,
    userAgent: params.userAgent,
    lastActiveAt: new Date(),
  });
}
