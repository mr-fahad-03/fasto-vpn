import { NextFunction, Request, Response } from "express";
import { logger } from "../config/logger";
import { ApiError } from "../utils/ApiError";
import { validationErrorToResponse } from "./validate";

export function errorHandler(err: unknown, req: Request, res: Response, _next: NextFunction): void {
  const zod = validationErrorToResponse(err);
  if (zod.isZodError) {
    res.status(400).json({
      success: false,
      message: "Validation failed",
      issues: zod.issues,
      requestId: req.requestId,
    });
    return;
  }

  if (err instanceof ApiError) {
    res.status(err.statusCode).json({
      success: false,
      message: err.message,
      details: err.details,
      requestId: req.requestId,
    });
    return;
  }

  logger.error({ err, requestId: req.requestId }, "Unhandled error");
  res.status(500).json({
    success: false,
    message: "Internal server error",
    requestId: req.requestId,
  });
}

export function notFoundHandler(req: Request, res: Response): void {
  res.status(404).json({
    success: false,
    message: `Route not found: ${req.method} ${req.originalUrl}`,
    requestId: req.requestId,
  });
}
