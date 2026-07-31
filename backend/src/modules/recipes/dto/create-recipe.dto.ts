import { Type } from 'class-transformer';
import {
  ArrayMinSize,
  IsArray,
  IsEnum,
  IsInt,
  IsNumber,
  IsOptional,
  IsString,
  Min,
  ValidateNested,
} from 'class-validator';
import { RecipeDifficulty } from '../../../common/enums';
import { RecipeIngredientInputDto } from './recipe-ingredient-input.dto';
import { RecipeStepInputDto } from './recipe-step-input.dto';

export class CreateRecipeDto {
  @IsString()
  title: string;

  @IsString()
  description: string;

  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => RecipeStepInputDto)
  instructions: RecipeStepInputDto[];

  @IsInt()
  @Min(1)
  servings: number;

  @IsInt()
  @Min(0)
  prepTimeMinutes: number;

  @IsOptional()
  @IsEnum(RecipeDifficulty)
  difficulty?: RecipeDifficulty;

  @IsOptional()
  @IsNumber()
  @Min(0)
  estimatedCostTotal?: number;

  @IsOptional()
  @IsString()
  imageUrl?: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  dietTags?: string[];

  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => RecipeIngredientInputDto)
  ingredients: RecipeIngredientInputDto[];
}
