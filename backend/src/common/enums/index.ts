export enum UserRole {
  USER = 'user',
  ADMIN = 'admin',
}

export enum Sex {
  MALE = 'male',
  FEMALE = 'female',
  OTHER = 'other',
}

export enum Goal {
  LOSE_WEIGHT = 'lose_weight',
  GAIN_MUSCLE = 'gain_muscle',
  MAINTAIN = 'maintain',
  EAT_HEALTHIER = 'eat_healthier',
  SAVE_MONEY = 'save_money',
}

export enum ActivityLevel {
  SEDENTARY = 'sedentary',
  LIGHT = 'light',
  MODERATE = 'moderate',
  ACTIVE = 'active',
  VERY_ACTIVE = 'very_active',
}

export enum IngredientCategory {
  CARNES = 'carnes',
  VERDURAS = 'verduras',
  FRUTAS = 'frutas',
  LACTEOS = 'lacteos',
  CONGELADOS = 'congelados',
  BEBIDAS = 'bebidas',
  PANADERIA = 'panaderia',
  LIMPIEZA = 'limpieza',
  CONDIMENTOS = 'condimentos',
  OTROS = 'otros',
}

export enum IngredientUnit {
  GRAMS = 'g',
  KILOGRAMS = 'kg',
  MILLILITERS = 'ml',
  LITERS = 'l',
  UNIT = 'unidad',
}

export enum InventoryItemState {
  FRESH = 'fresh',
  FROZEN = 'frozen',
  OPENED = 'opened',
  COOKED = 'cooked',
  EXPIRED = 'expired',
}

export enum InventoryItemSource {
  MANUAL = 'manual',
  PHOTO = 'photo',
  BARCODE = 'barcode',
}

export enum RecipeDifficulty {
  EASY = 'easy',
  MEDIUM = 'medium',
  HARD = 'hard',
}

export enum MealType {
  BREAKFAST = 'breakfast',
  LUNCH = 'lunch',
  SNACK = 'snack',
  DINNER = 'dinner',
}
