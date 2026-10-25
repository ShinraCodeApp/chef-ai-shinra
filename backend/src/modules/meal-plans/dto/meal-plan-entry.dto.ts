import { IsDateString, IsEnum, IsOptional, IsUUID } from 'class-validator';
import { MealType } from '../../../common/enums';

export class AddMealPlanEntryDto {
  @IsDateString()
  date: string;

  @IsEnum(MealType)
  mealType: MealType;

  /** Sin receta, la propone la IA. */
  @IsOptional()
  @IsUUID()
  recipeId?: string;
}

/** Cambiar la receta, el día o la comida de una entrada del plan. */
export class UpdateMealPlanEntryDto {
  @IsOptional()
  @IsDateString()
  date?: string;

  @IsOptional()
  @IsEnum(MealType)
  mealType?: MealType;

  @IsOptional()
  @IsUUID()
  recipeId?: string;
}
