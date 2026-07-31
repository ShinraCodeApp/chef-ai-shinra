import {
  IsArray,
  IsIn,
  IsInt,
  IsOptional,
  IsString,
  Min,
} from 'class-validator';

export class GenerateRecipeDto {
  @IsArray()
  @IsString({ each: true })
  availableIngredients: string[];

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  dietTags?: string[];

  @IsOptional()
  @IsInt()
  @Min(1)
  maxPrepTimeMinutes?: number;

  @IsOptional()
  @IsIn(['low', 'medium', 'high'])
  budget?: 'low' | 'medium' | 'high';

  @IsOptional()
  @IsInt()
  @Min(1)
  servings?: number;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  dislikedIngredients?: string[];

  @IsOptional()
  @IsString()
  freeTextRequest?: string;
}
