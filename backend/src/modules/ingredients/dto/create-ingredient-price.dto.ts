import { IsEnum, IsNumber, Min } from 'class-validator';
import { IngredientUnit } from '../../../common/enums';

export class CreateIngredientPriceDto {
  @IsNumber()
  @Min(0)
  price: number;

  @IsEnum(IngredientUnit)
  unit: IngredientUnit;
}
