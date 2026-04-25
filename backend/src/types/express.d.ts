import "express";

declare global {
  namespace Express {
    interface Request {
      requestId?: string;
      admin?: {
        id: string;
        email: string;
        role: "admin";
        tokenVersion: number;
      };
      mobileAuth?: {
        userId: string;
        mode: "guest" | "mobile";
        firebaseUid?: string;
        guestSessionId?: string;
        rcAppUserId?: string;
      };
      entitlement?: {
        plan: "free" | "premium";
        hasPremium: boolean;
        adsEnabled: boolean;
        proxyLimit: number | null;
        status?: "free" | "premium" | "expired" | "cancelled";
        expiresAt?: Date;
        userId?: string;
        rcAppUserId?: string;
      };
      rawBody?: string;
    }
  }
}

export {};
