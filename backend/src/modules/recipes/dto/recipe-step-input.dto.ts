import { IsInt, IsString, Min } from 'class-validator';

export class RecipeStepInputDto {
  @IsInt()
  @Min(1)
  order: number;

  @IsString()
  instruction: string;
}
