import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../users/entities/user.entity';
import { Recipe } from '../recipes/entities/recipe.entity';
import { Ingredient } from '../ingredients/entities/ingredient.entity';
import { InventoryItem } from '../inventory/entities/inventory-item.entity';
import { UserRole } from '../../common/enums';
import { paginate, PaginatedResult } from '../../common/dto/pagination-query.dto';
import { AiService } from '../ai/ai.service';
import { IngredientsService } from '../ingredients/ingredients.service';

export interface AdminStats {
  totalUsers: number;
  totalRecipes: number;
  aiGeneratedRecipes: number;
  totalIngredients: number;
  totalInventoryItems: number;
}

@Injectable()
export class AdminService {
  constructor(
    @InjectRepository(User)
    private readonly usersRepository: Repository<User>,
    @InjectRepository(Recipe)
    private readonly recipesRepository: Repository<Recipe>,
    @InjectRepository(Ingredient)
    private readonly ingredientsRepository: Repository<Ingredient>,
    @InjectRepository(InventoryItem)
    private readonly inventoryRepository: Repository<InventoryItem>,
    private readonly aiService: AiService,
    private readonly ingredientsService: IngredientsService,
  ) {}

  async findUsers(page: number, limit: number): Promise<PaginatedResult<User>> {
    const [items, total] = await this.usersRepository.findAndCount({
      order: { createdAt: 'DESC' },
      skip: (page - 1) * limit,
      take: limit,
    });
    return paginate(items, total, page, limit);
  }

  async updateUserRole(userId: string, role: UserRole): Promise<User> {
    const user = await this.usersRepository.findOne({ where: { id: userId } });
    if (!user) {
      throw new NotFoundException('Usuario no encontrado');
    }
    user.role = role;
    return this.usersRepository.save(user);
  }

  async deleteUser(userId: string, requesterId: string): Promise<void> {
    if (userId === requesterId) {
      throw new BadRequestException('No podés eliminar tu propia cuenta de administrador');
    }
    const user = await this.usersRepository.findOne({ where: { id: userId } });
    if (!user) {
      throw new NotFoundException('Usuario no encontrado');
    }
    await this.usersRepository.remove(user);
  }

  async setAiUnlimited(userId: string, unlimited: boolean): Promise<User> {
    const user = await this.usersRepository.findOne({ where: { id: userId } });
    if (!user) throw new NotFoundException('Usuario no encontrado');
    user.aiUnlimited = unlimited;
    return this.usersRepository.save(user);
  }

  async enrichIngredientsNutrition(batchSize = 20): Promise<{ enriched: number; failed: number; total: number }> {
    const ingredients = await this.ingredientsService.findMissingNutrition();
    let enriched = 0;
    let failed = 0;
    for (let i = 0; i < ingredients.length; i += batchSize) {
      const batch = ingredients.slice(i, i + batchSize);
      const result = await this.aiService.enrichIngredientsNutrition(batch);
      enriched += result.enriched;
      failed += result.failed;
    }
    return { enriched, failed, total: ingredients.length };
  }

  async getStats(): Promise<AdminStats> {
    const [totalUsers, totalRecipes, aiGeneratedRecipes, totalIngredients, totalInventoryItems] =
      await Promise.all([
        this.usersRepository.count(),
        this.recipesRepository.count(),
        this.recipesRepository.count({ where: { isAiGenerated: true } }),
        this.ingredientsRepository.count(),
        this.inventoryRepository.count(),
      ]);
    return {
      totalUsers,
      totalRecipes,
      aiGeneratedRecipes,
      totalIngredients,
      totalInventoryItems,
    };
  }
}
