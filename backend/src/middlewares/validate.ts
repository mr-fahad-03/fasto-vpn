import { NextFunction, Request, Response } from "express";
import { z, ZodSchema } from "zod";

export function validate(schema: ZodSchema, source: "body" | "query" | "params" = "body") {
  return (req: Request, _res: Response, next: NextFunction): void => {
    const parsed = schema.parse(req[source]);
    req[source] = parsed;
    next();
  };
}

export function validationErrorToResponse(err: unknown): { isZodError: boolean; issues?: z.ZodIssue[] } {
  if (err instanceof z.ZodError) {
    return { isZodError: true, issues: err.issues };
  }
  return { isZodError: false };
}
