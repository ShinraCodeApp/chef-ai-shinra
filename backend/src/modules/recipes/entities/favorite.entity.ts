import {
  Column,
  CreateDateColumn,
  Entity,
  ManyToOne,
  PrimaryGeneratedColumn,
  Unique,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { Recipe } from './recipe.entity';

@Entity('favorites')
@Unique(['userId', 'recipeId'])
export class Favorite {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => User, (user) => user.favorites, { onDelete: 'CASCADE' })
  user: User;

  @Column()
  userId: string;

  @ManyToOne(() => Recipe, (recipe) => recipe.favorites, {
    onDelete: 'CASCADE',
  })
  recipe: Recipe;

  @Column()
  recipeId: string;

  @CreateDateColumn()
  createdAt: Date;
}
