import "dotenv/config";
import { connectDatabase, disconnectDatabase } from "../config/database";
import { ensureDefaultAdmin } from "../services/authService";

async function run(): Promise<void> {
  await connectDatabase();
  await ensureDefaultAdmin();
  console.log("Admin seed complete.");
  await disconnectDatabase();
}

run().catch(async (error) => {
  console.error(error);
  await disconnectDatabase();
  process.exit(1);
});
