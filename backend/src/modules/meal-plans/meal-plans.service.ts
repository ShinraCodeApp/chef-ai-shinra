import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { MealPlan } from './entities/meal-plan.entity';
import { MealPlanEntry } from './entities/meal-plan-entry.entity';
import { GenerateMealPlanDto } from './dto/generate-meal-plan.dto';
import { MealType } from '../../common/enums';
import { InventoryService } from '../inventory/inventory.service';
import { AiService } from '../ai/ai.service';

const DEFAULT_MEAL_TYPES: MealType[] = [
  MealType.BREAKFAST,
  MealType.LUNCH,
  MealType.SNACK,
  MealType.DINNER,
];

@Injectable()
export class MealPlansService {
  constructor(
    @InjectRepository(MealPlan)
    private readonly mealPlansRepository: Repository<MealPlan>,
    @InjectRepository(MealPlanEntry)
    private readonly entriesRepository: Repository<MealPlanEntry>,
    private readonly inventoryService: InventoryService,
    private readonly aiService: AiService,
  ) {}

  async generate(userId: string, dto: GenerateMealPlanDto): Promise<MealPlan> {
    const mealTypes = dto.mealTypes?.length
      ? dto.mealTypes
      : DEFAULT_MEAL_TYPES;
    const inventory = await this.inventoryService.findAllForUser(userId);
    const availableIngredients = [
      ...new Set(inventory.map((item) => item.ingredient.name)),
    ];

    const startDate = new Date();
    const endDate = new Date(startDate);
    endDate.setDate(endDate.getDate() + dto.days - 1);

    const mealPlan = await this.mealPlansRepository.save(
      this.mealPlansRepository.create({
        userId,
        startDate: toDateOnly(startDate),
        endDate: toDateOnly(endDate),
      }),
    );

    const entries: MealPlanEntry[] = [];
    for (let dayOffset = 0; dayOffset < dto.days; dayOffset++) {
      const date = new Date(startDate);
      date.setDate(date.getDate() + dayOffset);

      for (const mealType of mealTypes) {
        const recipe = await this.aiService.generateRecipeForUser(userId, {
          availableIngredients,
          dietTags: dto.dietTags,
          freeTextRequest: `Receta para ${translateMealType(mealType)}`,
        });

        entries.push(
          this.entriesRepository.create({
            mealPlanId: mealPlan.id,
            date: toDateOnly(date),
            mealType,
            recipeId: recipe.id,
          }),
        );
      }
    }
    await this.entriesRepository.save(entries);

    return this.findOne(userId, mealPlan.id);
  }

  async findOne(userId: string, id: string): Promise<MealPlan> {
    const mealPlan = await this.mealPlansRepository.findOne({
      where: { id, userId },
      relations: { entries: true },
    });
    if (!mealPlan) {
      throw new NotFoundException('Plan de comidas no encontrado');
    }
    return mealPlan;
  }

  findAllForUser(userId: string): Promise<MealPlan[]> {
    return this.mealPlansRepository.find({
      where: { userId },
      order: { createdAt: 'DESC' },
      relations: { entries: true },
    });
  }
}

function toDateOnly(date: Date): string {
  return date.toISOString().slice(0, 10);
}

function translateMealType(mealType: MealType): string {
  const labels: Record<MealType, string> = {
    [MealType.BREAKFAST]: 'el desayuno',
    [MealType.LUNCH]: 'el almuerzo',
    [MealType.SNACK]: 'la merienda',
    [MealType.DINNER]: 'la cena',
  };
  return labels[mealType];
}
