import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Ingredient } from './entities/ingredient.entity';
import { IngredientPrice } from './entities/ingredient-price.entity';
import { IngredientsService } from './ingredients.service';
import { IngredientsController } from './ingredients.controller';
import { OpenFoodFactsService } from './open-food-facts.service';
import { IngredientPricesService } from './ingredient-prices.service';
import { IngredientPricesController } from './ingredient-prices.controller';

@Module({
  imports: [TypeOrmModule.forFeature([Ingredient, IngredientPrice])],
  controllers: [IngredientsController, IngredientPricesController],
  providers: [
    IngredientsService,
    OpenFoodFactsService,
    IngredientPricesService,
  ],
  exports: [IngredientsService, IngredientPricesService],
})
export class IngredientsModule {}
