import { IsEnum, IsNumber, IsOptional, Min } from 'class-validator';
import { IngredientUnit } from '../../../common/enums';

export class CreateIngredientPriceDto {
  @IsNumber()
  @Min(0)
  price: number;

  @IsEnum(IngredientUnit)
  unit: IngredientUnit;

  /**
   * Opcional: cuánto se compró por ese precio (ej. ticket: 350 g por $571).
   * Si viene, `price` es el total pagado por esa cantidad y se guarda
   * convertido a precio por kg, por litro o por unidad.
   */
  @IsOptional()
  @IsNumber()
  @Min(0.000001)
  quantity?: number;
}
