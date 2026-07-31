import {
  IsEnum,
  IsNumber,
  IsOptional,
  IsString,
  IsUUID,
  Min,
} from 'class-validator';
import { IngredientUnit } from '../../../common/enums';

export class RecipeIngredientInputDto {
  @IsUUID()
  ingredientId: string;

  @IsNumber()
  @Min(0)
  quantity: number;

  @IsEnum(IngredientUnit)
  unit: IngredientUnit;

  @IsOptional()
  @IsString()
  notes?: string;
}
