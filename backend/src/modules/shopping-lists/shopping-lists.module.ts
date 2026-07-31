import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ShoppingList } from './entities/shopping-list.entity';
import { ShoppingListItem } from './entities/shopping-list-item.entity';
import { ShoppingListsService } from './shopping-lists.service';
import { ShoppingListsController } from './shopping-lists.controller';
import { MealPlansModule } from '../meal-plans/meal-plans.module';
import { RecipesModule } from '../recipes/recipes.module';
import { InventoryModule } from '../inventory/inventory.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([ShoppingList, ShoppingListItem]),
    MealPlansModule,
    RecipesModule,
    InventoryModule,
  ],
  controllers: [ShoppingListsController],
  providers: [ShoppingListsService],
})
export class ShoppingListsModule {}
