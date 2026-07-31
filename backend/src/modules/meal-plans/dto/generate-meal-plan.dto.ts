import { IsArray, IsEnum, IsIn, IsOptional, IsString } from 'class-validator';
import { MealType } from '../../../common/enums';

export class GenerateMealPlanDto {
  @IsIn([7, 15, 30])
  days: 7 | 15 | 30;

  @IsOptional()
  @IsArray()
  @IsEnum(MealType, { each: true })
  mealTypes?: MealType[];

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  dietTags?: string[];
}
