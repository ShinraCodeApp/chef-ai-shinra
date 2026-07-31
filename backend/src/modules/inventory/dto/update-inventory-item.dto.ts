import { PartialType, OmitType } from '@nestjs/mapped-types';
import { CreateInventoryItemDto } from './create-inventory-item.dto';

export class UpdateInventoryItemDto extends PartialType(
  OmitType(CreateInventoryItemDto, ['ingredientId'] as const),
) {}
