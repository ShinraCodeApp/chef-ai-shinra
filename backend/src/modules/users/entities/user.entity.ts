import {
  Column,
  CreateDateColumn,
  Entity,
  OneToMany,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { ActivityLevel, Goal, Sex, UserRole } from '../../../common/enums';
import { RefreshToken } from '../../auth/entities/refresh-token.entity';
import { InventoryItem } from '../../inventory/entities/inventory-item.entity';
import { Favorite } from '../../recipes/entities/favorite.entity';

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true })
  email: string;

  @Column({ select: false })
  passwordHash: string;

  @Column()
  name: string;

  @Column({ type: 'enum', enum: UserRole, default: UserRole.USER })
  role: UserRole;

  @Column({ type: 'int', nullable: true })
  age: number | null;

  @Column({ type: 'float', nullable: true })
  weightKg: number | null;

  @Column({ type: 'float', nullable: true })
  heightCm: number | null;

  @Column({ type: 'enum', enum: Sex, nullable: true })
  sex: Sex | null;

  @Column({ type: 'enum', enum: Goal, nullable: true })
  goal: Goal | null;

  @Column({ type: 'enum', enum: ActivityLevel, nullable: true })
  activityLevel: ActivityLevel | null;

  @Column({ type: 'float', nullable: true })
  monthlyBudget: number | null;

  @Column({ type: 'int', nullable: true })
  familyMembers: number | null;

  @Column({ type: 'text', array: true, default: () => "'{}'" })
  dietPreferences: string[];

  @Column({ type: 'text', array: true, default: () => "'{}'" })
  allergies: string[];

  /** Texto libre: enfermedades, condiciones o necesidades dietarias especiales
   * que no entran en los tags fijos (ej. "gastritis", "embarazo", "resistencia
   * a la insulina"). Se usa para pedirle a la IA consejos personalizados. */
  @Column({ type: 'text', nullable: true })
  healthNotes: string | null;

  @Column({ default: false })
  onboardingCompleted: boolean;

  @OneToMany(() => RefreshToken, (token) => token.user)
  refreshTokens: RefreshToken[];

  @OneToMany(() => InventoryItem, (item) => item.user)
  inventoryItems: InventoryItem[];

  @OneToMany(() => Favorite, (favorite) => favorite.user)
  favorites: Favorite[];

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
