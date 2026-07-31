import { Column, Entity, ManyToOne, PrimaryGeneratedColumn } from 'typeorm';
import { IngredientUnit } from '../../../common/enums';
import { Recipe } from './recipe.entity';
import { Ingredient } from '../../ingredients/entities/ingredient.entity';

@Entity('recipe_ingredients')
export class RecipeIngredient {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => Recipe, (recipe) => recipe.recipeIngredients, {
    onDelete: 'CASCADE',
  })
  recipe: Recipe;

  @Column()
  recipeId: string;

  @ManyToOne(() => Ingredient, (ingredient) => ingredient.recipeIngredients, {
    eager: true,
  })
  ingredient: Ingredient;

  @Column()
  ingredientId: string;

  @Column({ type: 'float' })
  quantity: number;

  @Column({ type: 'enum', enum: IngredientUnit })
  unit: IngredientUnit;

  @Column({ nullable: true })
  notes: string | null;
}
