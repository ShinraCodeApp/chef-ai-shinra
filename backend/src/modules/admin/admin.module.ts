import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { User } from '../users/entities/user.entity';
import { Recipe } from '../recipes/entities/recipe.entity';
import { Ingredient } from '../ingredients/entities/ingredient.entity';
import { InventoryItem } from '../inventory/entities/inventory-item.entity';
import { AdminService } from './admin.service';
import { AdminController } from './admin.controller';

@Module({
  imports: [
    TypeOrmModule.forFeature([User, Recipe, Ingredient, InventoryItem]),
  ],
  controllers: [AdminController],
  providers: [AdminService],
})
export class AdminModule {}
