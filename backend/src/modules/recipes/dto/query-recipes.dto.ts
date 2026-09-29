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

  /** Filtra recetas que contengan AL MENOS UNO de estos ingredientes (comma-separated). Ordena por cantidad de matches. */
  @IsOptional()
  @IsString()
  ingredients?: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  maxPrepTimeMinutes?: number;
}
