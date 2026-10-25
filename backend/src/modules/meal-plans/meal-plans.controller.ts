import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Param,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import {
  AuthenticatedUser,
  CurrentUser,
} from '../../common/decorators/current-user.decorator';
import { MealPlansService } from './meal-plans.service';
import { GenerateMealPlanDto } from './dto/generate-meal-plan.dto';
import { CreateMealPlanDto } from './dto/create-meal-plan.dto';
import {
  AddMealPlanEntryDto,
  UpdateMealPlanEntryDto,
} from './dto/meal-plan-entry.dto';

@Controller('meal-plans')
@UseGuards(JwtAuthGuard)
export class MealPlansController {
  constructor(private readonly mealPlansService: MealPlansService) {}

  @Post('generate')
  generate(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: GenerateMealPlanDto,
  ) {
    return this.mealPlansService.generate(user.userId, dto);
  }

  /** Plan vacío para armarlo a mano. */
  @Post()
  create(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreateMealPlanDto,
  ) {
    return this.mealPlansService.createEmpty(user.userId, dto);
  }

  @Get()
  findAll(@CurrentUser() user: AuthenticatedUser) {
    return this.mealPlansService.findAllForUser(user.userId);
  }

  @Get(':id')
  findOne(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.mealPlansService.findOne(user.userId, id);
  }

  @Delete(':id')
  @HttpCode(204)
  remove(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.mealPlansService.remove(user.userId, id);
  }

  @Post(':planId/entries')
  addEntry(
    @CurrentUser() user: AuthenticatedUser,
    @Param('planId') planId: string,
    @Body() dto: AddMealPlanEntryDto,
  ) {
    return this.mealPlansService.addEntry(user.userId, planId, dto);
  }

  @Patch(':planId/entries/:entryId')
  updateEntry(
    @CurrentUser() user: AuthenticatedUser,
    @Param('planId') planId: string,
    @Param('entryId') entryId: string,
    @Body() dto: UpdateMealPlanEntryDto,
  ) {
    return this.mealPlansService.updateEntry(user.userId, planId, entryId, dto);
  }

  @Delete(':planId/entries/:entryId')
  @HttpCode(204)
  removeEntry(
    @CurrentUser() user: AuthenticatedUser,
    @Param('planId') planId: string,
    @Param('entryId') entryId: string,
  ) {
    return this.mealPlansService.removeEntry(user.userId, planId, entryId);
  }

  /** Cambia una comida por otra sugerida por la IA. */
  @Post(':planId/entries/:entryId/suggest')
  suggestEntry(
    @CurrentUser() user: AuthenticatedUser,
    @Param('planId') planId: string,
    @Param('entryId') entryId: string,
  ) {
    return this.mealPlansService.suggestEntry(user.userId, planId, entryId);
  }

  @Patch(':planId/entries/:entryId/toggle')
  toggleEntryCompleted(
    @CurrentUser() user: AuthenticatedUser,
    @Param('planId') planId: string,
    @Param('entryId') entryId: string,
  ) {
    return this.mealPlansService.toggleEntryCompleted(
      user.userId,
      planId,
      entryId,
    );
  }
}
