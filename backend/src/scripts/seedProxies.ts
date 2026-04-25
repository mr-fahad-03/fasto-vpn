import "dotenv/config";
import { connectDatabase, disconnectDatabase } from "../config/database";
import { AdminModel } from "../models/Admin";
import { createProxy } from "../services/proxyService";

async function run(): Promise<void> {
  await connectDatabase();

  const admin = await AdminModel.findOne();
  if (!admin) {
    throw new Error("No admin found. Run: npm run seed:admin");
  }

  await createProxy(
    {
      name: "Germany Free",
      host: "149.154.167.99",
      port: 8080,
      type: "HTTP",
      status: "active",
      isPremium: false,
      sortOrder: 1,
      tags: ["free", "http"],
      latency: 110,
      healthStatus: "healthy",
      maxFreeVisible: true,
    },
    admin._id.toString(),
  );

  await createProxy(
    {
      name: "Netherlands Premium",
      host: "149.154.167.220",
      port: 1080,
      type: "SOCKS5",
      status: "active",
      isPremium: true,
      sortOrder: 2,
      tags: ["premium", "socks5"],
      latency: 75,
      healthStatus: "healthy",
      maxFreeVisible: false,
    },
    admin._id.toString(),
  );

  console.log("Proxy seed complete.");
  await disconnectDatabase();
}

run().catch(async (error) => {
  console.error(error);
  await disconnectDatabase();
  process.exit(1);
});
