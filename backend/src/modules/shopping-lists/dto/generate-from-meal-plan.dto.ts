import { IsUUID } from 'class-validator';

export class GenerateFromMealPlanDto {
  @IsUUID()
  mealPlanId: string;
}
