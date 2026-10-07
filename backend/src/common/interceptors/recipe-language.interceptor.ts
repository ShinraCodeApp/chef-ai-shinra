import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from '@nestjs/common';
import { Observable, map } from 'rxjs';
import { currentLanguage } from '../request-language';
import type {
  RecipeStep,
  RecipeTranslations,
} from '../../modules/recipes/entities/recipe.entity';

interface TranslatableRecipe {
  title?: string;
  description?: string;
  instructions?: RecipeStep[];
  tips?: string[] | null;
  translations?: RecipeTranslations | null;
  recipeIngredients?: { order?: number; notes?: string | null }[];
}

/**
 * Si la app pide inglés (Accept-Language: en), reemplaza el texto de las
 * recetas por su traducción en la respuesta, sin tocar lo guardado. Recorre
 * toda la respuesta, así funciona en listas, detalle, favoritos, planes, etc.
 * El campo `translations` no se manda a la app.
 */
@Injectable()
export class RecipeLanguageInterceptor implements NestInterceptor {
  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const language = currentLanguage();
    return next
      .handle()
      .pipe(map((body) => localize(body, language, new WeakSet())));
  }
}

export function localize(
  value: unknown,
  language: string,
  seen: WeakSet<object>,
): unknown {
  if (value === null || typeof value !== 'object') return value;
  if (value instanceof Date || Buffer.isBuffer(value)) return value;
  if (seen.has(value)) return value;
  seen.add(value);

  if (Array.isArray(value)) {
    value.forEach((item, i) => (value[i] = localize(item, language, seen)));
    return value;
  }

  const obj = value as Record<string, unknown>;
  for (const key of Object.keys(obj)) {
    if (key !== 'translations') obj[key] = localize(obj[key], language, seen);
  }

  if ('translations' in obj) {
    const recipe = obj as TranslatableRecipe;
    const t = recipe.translations?.[language as 'en'];
    if (t) {
      recipe.title = t.title;
      recipe.description = t.description;
      recipe.instructions = t.instructions.map((instruction, i) => ({
        order: i + 1,
        instruction,
      }));
      if (t.tips) recipe.tips = t.tips;
      if (t.ingredientNotes && recipe.recipeIngredients) {
        for (const ri of recipe.recipeIngredients) {
          const note = t.ingredientNotes[ri.order ?? -1];
          if (note !== undefined) ri.notes = note;
        }
      }
    }
    delete recipe.translations;
  }
  return obj;
}
