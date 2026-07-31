import {
  IsDateString,
  IsEnum,
  IsNumber,
  IsOptional,
  IsString,
  IsUUID,
  Min,
} from 'class-validator';
import {
  IngredientUnit,
  InventoryItemSource,
  InventoryItemState,
} from '../../../common/enums';

export class CreateInventoryItemDto {
  @IsUUID()
  ingredientId: string;

  @IsNumber()
  @Min(0)
  quantity: number;

  @IsEnum(IngredientUnit)
  unit: IngredientUnit;

  @IsOptional()
  @IsEnum(InventoryItemState)
  state?: InventoryItemState;

  @IsOptional()
  @IsDateString()
  expirationDate?: string;

  @IsOptional()
  @IsEnum(InventoryItemSource)
  source?: InventoryItemSource;
}
