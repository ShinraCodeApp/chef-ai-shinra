import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { MealPlan } from './entities/meal-plan.entity';
import { MealPlanEntry } from './entities/meal-plan-entry.entity';
import { MealPlansService } from './meal-plans.service';
import { MealPlansController } from './meal-plans.controller';
import { InventoryModule } from '../inventory/inventory.module';
import { AiModule } from '../ai/ai.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([MealPlan, MealPlanEntry]),
    InventoryModule,
    AiModule,
  ],
  controllers: [MealPlansController],
  providers: [MealPlansService],
  exports: [MealPlansService],
})
export class MealPlansModule {}
