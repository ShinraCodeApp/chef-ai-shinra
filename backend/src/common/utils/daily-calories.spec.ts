import { ActivityLevel, Goal, Sex } from '../enums';
import { estimateDailyCalories } from './daily-calories';

const base = {
  age: 70,
  weightKg: 70,
  heightCm: 165,
  sex: Sex.FEMALE,
  activityLevel: ActivityLevel.SEDENTARY,
  goal: Goal.MAINTAIN,
};

describe('estimateDailyCalories', () => {
  it('calcula con Mifflin-St Jeor y la actividad', () => {
    // 10*70 + 6.25*165 - 5*70 - 161 = 1220.25 → ×1.2 = 1464 → 1450
    expect(estimateDailyCalories(base)).toBe(1450);
  });

  it('ajusta por objetivo', () => {
    const man = {
      ...base,
      sex: Sex.MALE,
      activityLevel: ActivityLevel.MODERATE,
    };
    const maintain = estimateDailyCalories(man)!;
    expect(
      estimateDailyCalories({ ...man, goal: Goal.LOSE_WEIGHT }),
    ).toBeLessThan(maintain);
    expect(
      estimateDailyCalories({ ...man, goal: Goal.GAIN_MUSCLE }),
    ).toBeGreaterThan(maintain);
  });

  it('no baja de un mínimo razonable', () => {
    expect(
      estimateDailyCalories({
        ...base,
        weightKg: 40,
        heightCm: 145,
        age: 90,
        goal: Goal.LOSE_WEIGHT,
      }),
    ).toBe(1200);
  });

  it('sin edad, peso o altura devuelve null', () => {
    expect(estimateDailyCalories({ ...base, weightKg: null })).toBeNull();
    expect(estimateDailyCalories({ ...base, age: null })).toBeNull();
  });
});
