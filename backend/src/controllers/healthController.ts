import { Request, Response } from "express";

export function healthController(_req: Request, res: Response): void {
  res.status(200).json({
    success: true,
    status: "ok",
    service: "fasto-vpn-backend",
    timestamp: new Date().toISOString(),
  });
}
