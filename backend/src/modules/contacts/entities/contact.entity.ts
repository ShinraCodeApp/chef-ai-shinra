import {
  Column,
  CreateDateColumn,
  Entity,
  ManyToOne,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';

export enum ContactStatus {
  PENDING = 'pending',
  ACCEPTED = 'accepted',
  REJECTED = 'rejected',
}

@Entity('contacts')
export class Contact {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  /** Usuario que envía la invitación */
  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  requester: User;

  @Column()
  requesterId: string;

  /** Usuario que recibe la invitación */
  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  addressee: User;

  @Column()
  addresseeId: string;

  @Column({ type: 'enum', enum: ContactStatus, default: ContactStatus.PENDING })
  status: ContactStatus;

  /** El usuario que inició la relación puede marcar al otro como favorito */
  @Column({ default: false })
  isFavorite: boolean;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
