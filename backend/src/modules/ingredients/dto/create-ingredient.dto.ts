import { IsEnum, IsNumber, IsOptional, IsString, Min } from 'class-validator';
import { IngredientCategory, IngredientUnit } from '../../../common/enums';

export class CreateIngredientDto {
  @IsString()
  name: string;

  @IsEnum(IngredientCategory)
  category: IngredientCategory;

  @IsEnum(IngredientUnit)
  unit: IngredientUnit;

  @IsOptional()
  @IsString()
  barcode?: string;

  @IsOptional()
  @IsNumber()
  @Min(0)
  caloriesPer100g?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  proteinPer100g?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  fatPer100g?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  carbsPer100g?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  fiberPer100g?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  sugarPer100g?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  sodiumPer100g?: number;

  @IsOptional()
  @IsString()
  imageUrl?: string;
}
