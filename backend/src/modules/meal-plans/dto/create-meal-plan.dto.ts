import { IsDateString, IsIn, IsOptional } from 'class-validator';

/** Plan vacío para armarlo a mano (sin IA). */
export class CreateMealPlanDto {
  @IsIn([7, 15, 30])
  days: 7 | 15 | 30;

  /** Primer día del plan en la fecha del celular (el servidor está en UTC). */
  @IsOptional()
  @IsDateString()
  startDate?: string;
}
