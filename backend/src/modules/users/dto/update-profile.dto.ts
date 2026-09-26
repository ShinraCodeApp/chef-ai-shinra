import {
  IsArray,
  IsBoolean,
  IsEnum,
  IsInt,
  IsNumber,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
} from 'class-validator';
import { ActivityLevel, Goal, Sex } from '../../../common/enums';

export class UpdateProfileDto {
  @IsOptional()
  @IsString()
  name?: string;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(120)
  age?: number;

  @IsOptional()
  @IsNumber()
  @Min(1)
  weightKg?: number;

  @IsOptional()
  @IsNumber()
  @Min(1)
  heightCm?: number;

  @IsOptional()
  @IsEnum(Sex)
  sex?: Sex;

  @IsOptional()
  @IsEnum(Goal)
  goal?: Goal;

  @IsOptional()
  @IsEnum(ActivityLevel)
  activityLevel?: ActivityLevel;

  @IsOptional()
  @IsNumber()
  @Min(0)
  monthlyBudget?: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  familyMembers?: number;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  dietPreferences?: string[];

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  allergies?: string[];

  @IsOptional()
  @IsBoolean()
  onboardingCompleted?: boolean;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  healthNotes?: string;
}
