import {
  Column,
  CreateDateColumn,
  Entity,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { User } from './user.entity';

@Entity('weight_logs')
export class WeightLog {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  user: User;

  @Column()
  userId: string;

  @Column({ type: 'float' })
  weightKg: number;

  @Column({ type: 'date' })
  recordedAt: string;

  @CreateDateColumn()
  createdAt: Date;
}
