import {
  Column,
  Entity,
  ManyToOne,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { IngredientUnit } from '../../../common/enums';
import { Ingredient } from './ingredient.entity';

@Entity('ingredient_prices')
export class IngredientPrice {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => Ingredient, (ingredient) => ingredient.prices, {
    onDelete: 'CASCADE',
  })
  ingredient: Ingredient;

  @Column()
  ingredientId: string;

  @Column({ type: 'float' })
  price: number;

  @Column({ type: 'enum', enum: IngredientUnit })
  unit: IngredientUnit;

  @UpdateDateColumn()
  updatedAt: Date;
}
