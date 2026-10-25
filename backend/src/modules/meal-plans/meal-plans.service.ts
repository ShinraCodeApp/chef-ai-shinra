import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { MealPlan } from './entities/meal-plan.entity';
import { MealPlanEntry } from './entities/meal-plan-entry.entity';
import { GenerateMealPlanDto } from './dto/generate-meal-plan.dto';
import { CreateMealPlanDto } from './dto/create-meal-plan.dto';
import {
  AddMealPlanEntryDto,
  UpdateMealPlanEntryDto,
} from './dto/meal-plan-entry.dto';
import { Recipe } from '../recipes/entities/recipe.entity';
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

    const startDate = planStart(dto.startDate);
    const endDate = new Date(startDate);
    endDate.setUTCDate(endDate.getUTCDate() + dto.days - 1);

    const mealPlan = await this.mealPlansRepository.save(
      this.mealPlansRepository.create({
        userId,
        startDate: toDateOnly(startDate),
        endDate: toDateOnly(endDate),
      }),
    );

    const entries: MealPlanEntry[] = [];
    const usedTitles: string[] = [];
    for (let dayOffset = 0; dayOffset < dto.days; dayOffset++) {
      const date = new Date(startDate);
      date.setUTCDate(date.getUTCDate() + dayOffset);

      const dayMeals = await this.aiService.generateDailyMealPlanForUser(
        userId,
        {
          availableIngredients,
          mealTypes,
          dietTags: dto.dietTags,
          avoidTitles: usedTitles.slice(-20),
        },
      );

      for (const { mealType, recipe } of dayMeals) {
        usedTitles.push(recipe.title);
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

  /** Plan vacío desde hoy, para que la persona lo arme a mano. */
  async createEmpty(userId: string, dto: CreateMealPlanDto): Promise<MealPlan> {
    const startDate = planStart(dto.startDate);
    const endDate = new Date(startDate);
    endDate.setUTCDate(endDate.getUTCDate() + dto.days - 1);
    const mealPlan = await this.mealPlansRepository.save(
      this.mealPlansRepository.create({
        userId,
        startDate: toDateOnly(startDate),
        endDate: toDateOnly(endDate),
      }),
    );
    return this.findOne(userId, mealPlan.id);
  }

  async remove(userId: string, id: string): Promise<void> {
    const mealPlan = await this.findOne(userId, id);
    await this.mealPlansRepository.remove(mealPlan);
  }

  async addEntry(
    userId: string,
    planId: string,
    dto: AddMealPlanEntryDto,
  ): Promise<MealPlanEntry> {
    const mealPlan = await this.findOne(userId, planId);
    const date = this.dateInPlan(mealPlan, dto.date);
    let recipeId = dto.recipeId;
    if (recipeId) {
      await this.ensureRecipeExists(recipeId);
    } else {
      recipeId = await this.aiRecipeFor(userId, mealPlan, dto.mealType);
    }
    const entry = await this.entriesRepository.save(
      this.entriesRepository.create({
        mealPlanId: mealPlan.id,
        date,
        mealType: dto.mealType,
        recipeId,
      }),
    );
    return this.findEntry(entry.id);
  }

  async updateEntry(
    userId: string,
    planId: string,
    entryId: string,
    dto: UpdateMealPlanEntryDto,
  ): Promise<MealPlanEntry> {
    const mealPlan = await this.findOne(userId, planId);
    const entry = this.entryOf(mealPlan, entryId);
    if (dto.date) entry.date = this.dateInPlan(mealPlan, dto.date);
    if (dto.mealType) entry.mealType = dto.mealType;
    if (dto.recipeId && dto.recipeId !== entry.recipeId) {
      await this.ensureRecipeExists(dto.recipeId);
      entry.recipeId = dto.recipeId;
      // si cambió la comida, lo que estaba tildado ya no vale
      entry.completed = false;
    }
    // update() y no save(): la relación eager pisaría el recipeId nuevo
    await this.entriesRepository.update(entry.id, {
      date: entry.date,
      mealType: entry.mealType,
      recipeId: entry.recipeId,
      completed: entry.completed,
    });
    return this.findEntry(entry.id);
  }

  async removeEntry(
    userId: string,
    planId: string,
    entryId: string,
  ): Promise<void> {
    const mealPlan = await this.findOne(userId, planId);
    await this.entriesRepository.delete(this.entryOf(mealPlan, entryId).id);
  }

  /** Cambia una sola comida del plan por otra que propone la IA. */
  async suggestEntry(
    userId: string,
    planId: string,
    entryId: string,
  ): Promise<MealPlanEntry> {
    const mealPlan = await this.findOne(userId, planId);
    const entry = this.entryOf(mealPlan, entryId);
    const recipeId = await this.aiRecipeFor(userId, mealPlan, entry.mealType);
    await this.entriesRepository.update(entry.id, {
      recipeId,
      completed: false,
    });
    return this.findEntry(entry.id);
  }

  /** Receta nueva de la IA para una comida, sin repetir las del plan. */
  private async aiRecipeFor(
    userId: string,
    mealPlan: MealPlan,
    mealType: MealType,
  ): Promise<string> {
    const inventory = await this.inventoryService.findAllForUser(userId);
    const [meal] = await this.aiService.generateDailyMealPlanForUser(userId, {
      availableIngredients: [
        ...new Set(inventory.map((item) => item.ingredient.name)),
      ],
      mealTypes: [mealType],
      avoidTitles: mealPlan.entries.map((e) => e.recipe.title).slice(-20),
    });
    if (!meal) {
      throw new BadRequestException('La IA no propuso ninguna comida');
    }
    return meal.recipe.id;
  }

  private entryOf(mealPlan: MealPlan, entryId: string): MealPlanEntry {
    const entry = mealPlan.entries.find((e) => e.id === entryId);
    if (!entry) {
      throw new NotFoundException('Comida no encontrada en este plan');
    }
    return entry;
  }

  private dateInPlan(mealPlan: MealPlan, value: string): string {
    const date = value.slice(0, 10);
    if (date < mealPlan.startDate || date > mealPlan.endDate) {
      throw new BadRequestException('La fecha está fuera del plan');
    }
    return date;
  }

  private async ensureRecipeExists(recipeId: string): Promise<void> {
    const exists = await this.entriesRepository.manager.exists(Recipe, {
      where: { id: recipeId },
    });
    if (!exists) throw new NotFoundException('Receta no encontrada');
  }

  private async findEntry(id: string): Promise<MealPlanEntry> {
    return this.entriesRepository.findOneOrFail({ where: { id } });
  }

  async toggleEntryCompleted(
    userId: string,
    planId: string,
    entryId: string,
  ): Promise<MealPlanEntry> {
    const mealPlan = await this.findOne(userId, planId);
    const entry = mealPlan.entries.find((e) => e.id === entryId);
    if (!entry) {
      throw new NotFoundException('Comida no encontrada en este plan');
    }
    entry.completed = !entry.completed;
    return this.entriesRepository.save(entry);
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

/** Fecha que manda la app (hoy en el celular) o hoy en el servidor. */
function planStart(startDate?: string): Date {
  return startDate
    ? new Date(`${startDate.slice(0, 10)}T00:00:00Z`)
    : new Date();
}

function toDateOnly(date: Date): string {
  return date.toISOString().slice(0, 10);
}
