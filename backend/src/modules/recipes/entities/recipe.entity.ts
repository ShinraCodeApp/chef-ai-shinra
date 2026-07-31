import {
  Column,
  CreateDateColumn,
  Entity,
  ManyToOne,
  OneToMany,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { RecipeDifficulty } from '../../../common/enums';
import { User } from '../../users/entities/user.entity';
import { RecipeIngredient } from './recipe-ingredient.entity';
import { Favorite } from './favorite.entity';

export interface RecipeStep {
  order: number;
  instruction: string;
}

export interface RecipeNutrition {
  calories: number;
  proteinG: number;
  fatG: number;
  carbsG: number;
  fiberG: number;
  sugarG: number;
  sodiumMg: number;
}

@Entity('recipes')
export class Recipe {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  title: string;

  @Column({ type: 'text' })
  description: string;

  @Column({ type: 'jsonb' })
  instructions: RecipeStep[];

  @Column({ type: 'int' })
  servings: number;

  @Column({ type: 'int' })
  prepTimeMinutes: number;

  @Column({
    type: 'enum',
    enum: RecipeDifficulty,
    default: RecipeDifficulty.EASY,
  })
  difficulty: RecipeDifficulty;

  @Column({ type: 'float', nullable: true })
  estimatedCostTotal: number | null;

  @Column({ nullable: true })
  imageUrl: string | null;

  @Column({ type: 'text', array: true, default: () => "'{}'" })
  dietTags: string[];

  @Column({ default: false })
  isAiGenerated: boolean;

  @ManyToOne(() => User, { nullable: true, onDelete: 'SET NULL' })
  createdByUser: User | null;

  @Column({ nullable: true })
  createdByUserId: string | null;

  @Column({ type: 'jsonb', nullable: true })
  nutrition: RecipeNutrition | null;

  @OneToMany(() => RecipeIngredient, (ri) => ri.recipe, { cascade: true })
  recipeIngredients: RecipeIngredient[];

  @OneToMany(() => Favorite, (favorite) => favorite.recipe)
  favorites: Favorite[];

  /**
   * Campo transitorio (no persistido) que indica si el usuario autenticado que
   * hizo la request tiene esta receta como favorita. Lo completa RecipesService
   * según quién pregunta; no es una columna de la tabla.
   */
  isFavorite?: boolean;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
