import { Column, Entity, ManyToOne, PrimaryGeneratedColumn } from 'typeorm';
import { MealType } from '../../../common/enums';
import { MealPlan } from './meal-plan.entity';
import { Recipe } from '../../recipes/entities/recipe.entity';

@Entity('meal_plan_entries')
export class MealPlanEntry {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => MealPlan, (mealPlan) => mealPlan.entries, {
    onDelete: 'CASCADE',
  })
  mealPlan: MealPlan;

  @Column()
  mealPlanId: string;

  @Column({ type: 'date' })
  date: string;

  @Column({ type: 'enum', enum: MealType })
  mealType: MealType;

  @ManyToOne(() => Recipe, { eager: true, onDelete: 'CASCADE' })
  recipe: Recipe;

  @Column()
  recipeId: string;
}
