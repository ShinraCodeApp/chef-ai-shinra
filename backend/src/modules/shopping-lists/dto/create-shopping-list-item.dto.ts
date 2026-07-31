import {
  IsEnum,
  IsNumber,
  IsOptional,
  IsString,
  IsUUID,
  Min,
  ValidateIf,
} from 'class-validator';
import { IngredientCategory, IngredientUnit } from '../../../common/enums';

export class CreateShoppingListItemDto {
  @ValidateIf((dto: CreateShoppingListItemDto) => !dto.customName)
  @IsUUID()
  ingredientId?: string;

  @ValidateIf((dto: CreateShoppingListItemDto) => !dto.ingredientId)
  @IsString()
  customName?: string;

  @IsNumber()
  @Min(0)
  quantity: number;

  @IsEnum(IngredientUnit)
  unit: IngredientUnit;

  @IsOptional()
  @IsEnum(IngredientCategory)
  category?: IngredientCategory;
}
