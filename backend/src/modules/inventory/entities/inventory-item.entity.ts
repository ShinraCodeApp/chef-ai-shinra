import {
  Column,
  CreateDateColumn,
  Entity,
  ManyToOne,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import {
  IngredientUnit,
  InventoryItemSource,
  InventoryItemState,
} from '../../../common/enums';
import { User } from '../../users/entities/user.entity';
import { Ingredient } from '../../ingredients/entities/ingredient.entity';

@Entity('inventory_items')
export class InventoryItem {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => User, (user) => user.inventoryItems, { onDelete: 'CASCADE' })
  user: User;

  @Column()
  userId: string;

  @ManyToOne(() => Ingredient, (ingredient) => ingredient.inventoryItems, {
    eager: true,
  })
  ingredient: Ingredient;

  @Column()
  ingredientId: string;

  @Column({ type: 'float' })
  quantity: number;

  @Column({ type: 'enum', enum: IngredientUnit })
  unit: IngredientUnit;

  @Column({
    type: 'enum',
    enum: InventoryItemState,
    default: InventoryItemState.FRESH,
  })
  state: InventoryItemState;

  @Column({ type: 'date', nullable: true })
  expirationDate: string | null;

  @Column({
    type: 'enum',
    enum: InventoryItemSource,
    default: InventoryItemSource.MANUAL,
  })
  source: InventoryItemSource;

  @CreateDateColumn()
  addedAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
