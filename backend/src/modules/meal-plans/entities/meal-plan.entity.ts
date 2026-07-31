import {
  Column,
  CreateDateColumn,
  Entity,
  ManyToOne,
  OneToMany,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { MealPlanEntry } from './meal-plan-entry.entity';

@Entity('meal_plans')
export class MealPlan {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  user: User;

  @Column()
  userId: string;

  @Column({ type: 'date' })
  startDate: string;

  @Column({ type: 'date' })
  endDate: string;

  @OneToMany(() => MealPlanEntry, (entry) => entry.mealPlan, { cascade: true })
  entries: MealPlanEntry[];

  @CreateDateColumn()
  createdAt: Date;
}
