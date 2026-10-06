import { AsyncLocalStorage } from 'node:async_hooks';
import type { NextFunction, Request, Response } from 'express';

/**
 * Idioma de la request (la app manda Accept-Language: es | en). Se guarda por
 * request para que la IA escriba en el idioma del usuario sin tener que pasar
 * el dato por cada controller y servicio.
 */
export type AppLanguage = 'es' | 'en';

const storage = new AsyncLocalStorage<AppLanguage>();

export function parseLanguage(
  header: string | string[] | undefined,
): AppLanguage {
  const value = (
    Array.isArray(header) ? header[0] : (header ?? '')
  ).toLowerCase();
  return value.startsWith('en') ? 'en' : 'es';
}

export function requestLanguageMiddleware(
  req: Request,
  _res: Response,
  next: NextFunction,
): void {
  storage.run(parseLanguage(req.headers['accept-language']), () => next());
}

/** Idioma de la request en curso (castellano si no hay request). */
export function currentLanguage(): AppLanguage {
  return storage.getStore() ?? 'es';
}

/** Para tests y tareas fuera de una request. */
export function runWithLanguage<T>(language: AppLanguage, fn: () => T): T {
  return storage.run(language, fn);
}
