import { ActivityLevel, Goal, Sex } from '../enums';

const ACTIVITY_FACTOR: Record<ActivityLevel, number> = {
  [ActivityLevel.SEDENTARY]: 1.2,
  [ActivityLevel.LIGHT]: 1.375,
  [ActivityLevel.MODERATE]: 1.55,
  [ActivityLevel.ACTIVE]: 1.725,
  [ActivityLevel.VERY_ACTIVE]: 1.9,
};

export interface CalorieProfile {
  age: number | null;
  weightKg: number | null;
  heightCm: number | null;
  sex: Sex | null;
  activityLevel: ActivityLevel | null;
  goal: Goal | null;
}

/**
 * Calorías diarias aproximadas (Mifflin-St Jeor × actividad, ajustadas por el
 * objetivo). Devuelve null si faltan edad, peso o altura: sin esos datos no
 * se puede estimar y el plan sigue sin un objetivo de calorías.
 * Es una referencia para armar el plan, no una indicación médica.
 */
export function estimateDailyCalories(p: CalorieProfile): number | null {
  if (!p.age || !p.weightKg || !p.heightCm) return null;
  const base = 10 * p.weightKg + 6.25 * p.heightCm - 5 * p.age;
  // Sin sexo indicado (u "otro") se usa el promedio de ambas fórmulas
  const sexOffset = p.sex === Sex.MALE ? 5 : p.sex === Sex.FEMALE ? -161 : -78;
  const bmr = base + sexOffset;
  let kcal = bmr * ACTIVITY_FACTOR[p.activityLevel ?? ActivityLevel.LIGHT];
  if (p.goal === Goal.LOSE_WEIGHT) kcal -= 400;
  if (p.goal === Goal.GAIN_MUSCLE) kcal += 300;
  // Nunca por debajo de un mínimo razonable
  const floor = p.sex === Sex.MALE ? 1500 : 1200;
  return Math.round(Math.max(kcal, floor) / 50) * 50;
}
