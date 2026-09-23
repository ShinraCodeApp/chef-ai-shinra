import { Type } from 'class-transformer';
import { IsInt, IsOptional, IsString, Min } from 'class-validator';
import { PaginationQueryDto } from '../../../common/dto/pagination-query.dto';

export class QueryRecipesDto extends PaginationQueryDto {
  @IsOptional()
  @IsString()
  search?: string;

  /** Filtra por un dietTag exacto, ej: "vegano", "sin_tacc", "keto" */
  @IsOptional()
  @IsString()
  dietTag?: string;

  /** Filtra recetas que usen un ingrediente cuyo nombre matchee (parcial, sin importar mayúsculas) */
  @IsOptional()
  @IsString()
  ingredient?: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  maxPrepTimeMinutes?: number;
}
