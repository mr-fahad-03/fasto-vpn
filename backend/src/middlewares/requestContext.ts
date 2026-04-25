import { NextFunction, Request, Response } from "express";
import crypto from "crypto";

export function requestContext(req: Request, res: Response, next: NextFunction): void {
  req.requestId = req.header("x-request-id") ?? crypto.randomUUID();
  res.setHeader("x-request-id", req.requestId);
  next();
}
