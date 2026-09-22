import { IsString, MinLength } from 'class-validator';

export class ParseVoiceInventoryDto {
  @IsString()
  @MinLength(1)
  text: string;
}
