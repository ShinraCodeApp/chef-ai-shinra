import { Column, Entity, ManyToOne, PrimaryGeneratedColumn } from 'typeorm';
import { IngredientCategory, IngredientUnit } from '../../../common/enums';
import { ShoppingList } from './shopping-list.entity';
import { Ingredient } from '../../ingredients/entities/ingredient.entity';

@Entity('shopping_list_items')
export class ShoppingListItem {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => ShoppingList, (list) => list.items, { onDelete: 'CASCADE' })
  shoppingList: ShoppingList;

  @Column()
  shoppingListId: string;

  @ManyToOne(() => Ingredient, { nullable: true, eager: true })
  ingredient: Ingredient | null;

  @Column({ nullable: true })
  ingredientId: string | null;

  @Column({ nullable: true })
  customName: string | null;

  @Column({ type: 'float' })
  quantity: number;

  @Column({ type: 'enum', enum: IngredientUnit })
  unit: IngredientUnit;

  @Column({
    type: 'enum',
    enum: IngredientCategory,
    default: IngredientCategory.OTROS,
  })
  category: IngredientCategory;

  @Column({ default: false })
  isChecked: boolean;
}
