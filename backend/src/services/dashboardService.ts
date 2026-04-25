import { ProxyModel } from "../models/Proxy";
import { SubscriptionModel } from "../models/Subscription";
import { UsageLogModel } from "../models/UsageLog";
import { UserModel } from "../models/User";

export async function getDashboardStats() {
  const [
    proxyCountByCountry,
    activeVsInactive,
    premiumVsFree,
    totalUsers,
    guestUsers,
    premiumUsers,
  ] = await Promise.all([
    ProxyModel.aggregate([{ $group: { _id: "$countryCode", count: { $sum: 1 } } }, { $sort: { count: -1 } }]),
    ProxyModel.aggregate([{ $group: { _id: "$status", count: { $sum: 1 } } }]),
    ProxyModel.aggregate([
      {
        $group: {
          _id: "$isPremium",
          count: { $sum: 1 },
        },
      },
    ]),
    UserModel.countDocuments(),
    UserModel.countDocuments({ mode: "guest" }),
    SubscriptionModel.countDocuments({ isPremium: true }),
  ]);

  return {
    proxyCountByCountry: proxyCountByCountry.map((row) => ({ countryCode: row._id ?? "XX", count: row.count })),
    activeVsInactive: {
      active: activeVsInactive.find((x) => x._id === "active")?.count ?? 0,
      inactive: activeVsInactive.find((x) => x._id === "inactive")?.count ?? 0,
    },
    premiumVsFreeProxyCounts: {
      premium: premiumVsFree.find((x) => x._id === true)?.count ?? 0,
      free: premiumVsFree.find((x) => x._id === false)?.count ?? 0,
    },
    userStats: {
      totalUsers,
      premiumUsers,
      guests: guestUsers,
    },
  };
}

export async function getRecentActivity(limit = 20) {
  const items = await UsageLogModel.find()
    .sort({ createdAt: -1 })
    .limit(limit)
    .populate("user", "mode email firebaseUid")
    .lean();

  return items.map((item) => ({
    id: item._id.toString(),
    eventType: item.eventType,
    metadata: item.metadata,
    ip: item.ip,
    userAgent: item.userAgent,
    user: item.user,
    createdAt: item.createdAt,
  }));
}
