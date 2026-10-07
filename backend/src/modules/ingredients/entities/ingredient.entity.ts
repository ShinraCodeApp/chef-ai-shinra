import {
  AfterLoad,
  Column,
  CreateDateColumn,
  Entity,
  OneToMany,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { IngredientCategory, IngredientUnit } from '../../../common/enums';
import { unitWeightFor } from '../../../common/utils/unit-weights';
import { InventoryItem } from '../../inventory/entities/inventory-item.entity';
import { IngredientPrice } from './ingredient-price.entity';
import { RecipeIngredient } from '../../recipes/entities/recipe-ingredient.entity';

@Entity('ingredients')
export class Ingredient {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  name: string;

  @Column({ type: 'enum', enum: IngredientCategory })
  category: IngredientCategory;

  @Column({ type: 'enum', enum: IngredientUnit })
  unit: IngredientUnit;

  @Column({ nullable: true, unique: true })
  barcode: string | null;

  @Column({ type: 'float', nullable: true })
  caloriesPer100g: number | null;

  @Column({ type: 'float', nullable: true })
  proteinPer100g: number | null;

  @Column({ type: 'float', nullable: true })
  fatPer100g: number | null;

  @Column({ type: 'float', nullable: true })
  carbsPer100g: number | null;

  @Column({ type: 'float', nullable: true })
  fiberPer100g: number | null;

  @Column({ type: 'float', nullable: true })
  sugarPer100g: number | null;

  @Column({ type: 'float', nullable: true })
  sodiumPer100g: number | null;

  @Column({ nullable: true })
  imageUrl: string | null;

  /**
   * Gramos que pesa una unidad (huevo ≈ 50 g, cebolla ≈ 150 g). No es columna:
   * se calcula al cargar desde la tabla de pesos y viaja en la API para que la
   * app también pueda comparar "unidad" con gramos.
   */
  unitWeightG: number | null;

  @AfterLoad()
  setUnitWeight() {
    this.unitWeightG = unitWeightFor(this.name);
  }

  @OneToMany(() => InventoryItem, (item) => item.ingredient)
  inventoryItems: InventoryItem[];

  @OneToMany(() => IngredientPrice, (price) => price.ingredient)
  prices: IngredientPrice[];

  @OneToMany(() => RecipeIngredient, (ri) => ri.ingredient)
  recipeIngredients: RecipeIngredient[];

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
