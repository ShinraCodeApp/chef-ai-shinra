import { Body, Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import {
  AuthenticatedUser,
  CurrentUser,
} from '../../common/decorators/current-user.decorator';
import { MealPlansService } from './meal-plans.service';
import { GenerateMealPlanDto } from './dto/generate-meal-plan.dto';

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

  @Get()
  findAll(@CurrentUser() user: AuthenticatedUser) {
    return this.mealPlansService.findAllForUser(user.userId);
  }

  @Get(':id')
  findOne(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.mealPlansService.findOne(user.userId, id);
  }
}
