import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from './entities/user.entity';
import { WeightLog } from './entities/weight-log.entity';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { Goal, UserRole } from '../../common/enums';
import { isSuperAdminEmail } from '../../common/super-admin';

export const AI_MONTHLY_LIMIT = 5;

/** IA sin límite: la cuenta admin principal o usuarios habilitados desde el panel. */
function isUnlimited(user: User): boolean {
  return (
    user.aiUnlimited ||
    (user.role === UserRole.ADMIN && isSuperAdminEmail(user.email))
  );
}

export interface WeightProgress {
  previousWeightKg: number;
  newWeightKg: number;
  deltaKg: number;
  isGoalProgress: boolean;
}

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private readonly usersRepository: Repository<User>,
    @InjectRepository(WeightLog)
    private readonly weightLogsRepository: Repository<WeightLog>,
  ) {}

  async findByEmail(email: string): Promise<User | null> {
    return this.usersRepository.findOne({
      where: { email },
      select: {
        id: true,
        email: true,
        passwordHash: true,
        name: true,
        role: true,
      },
    });
  }

  async findById(id: string): Promise<User> {
    const user = await this.usersRepository.findOne({ where: { id } });
    if (!user) {
      throw new NotFoundException('Usuario no encontrado');
    }
    return user;
  }

  async create(data: {
    email: string;
    passwordHash: string;
    name: string;
  }): Promise<User> {
    const user = this.usersRepository.create(data);
    return this.usersRepository.save(user);
  }

  async updateProfile(
    id: string,
    dto: UpdateProfileDto,
  ): Promise<{ user: User; weightProgress: WeightProgress | null }> {
    const user = await this.findById(id);
    let weightProgress: WeightProgress | null = null;

    if (dto.weightKg !== undefined && dto.weightKg !== user.weightKg) {
      const previousWeightKg = user.weightKg;
      if (previousWeightKg !== null) {
        const deltaKg = dto.weightKg - previousWeightKg;
        weightProgress = {
          previousWeightKg,
          newWeightKg: dto.weightKg,
          deltaKg,
          isGoalProgress: this.isWeightChangeProgress(user.goal, deltaKg),
        };
      }
      await this.weightLogsRepository.save(
        this.weightLogsRepository.create({
          userId: id,
          weightKg: dto.weightKg,
          recordedAt: toDateOnly(new Date()),
        }),
      );
    }

    Object.assign(user, dto);
    const saved = await this.usersRepository.save(user);
    return { user: saved, weightProgress };
  }

  async checkAndConsumeAiGeneration(userId: string): Promise<void> {
    const user = await this.usersRepository.findOne({ where: { id: userId } });
    if (!user) throw new NotFoundException('Usuario no encontrado');

    if (isUnlimited(user)) return;

    const now = new Date();
    const resetAt = user.aiGenerationsResetAt;
    const isNewPeriod =
      !resetAt ||
      now.getFullYear() > resetAt.getFullYear() ||
      now.getMonth() > resetAt.getMonth() ||
      (now.getFullYear() === resetAt.getFullYear() &&
        now.getMonth() === resetAt.getMonth() &&
        now.getDate() - resetAt.getDate() >= 30);

    if (isNewPeriod) {
      user.aiGenerationsUsed = 0;
      user.aiGenerationsResetAt = now;
    }

    if (user.aiGenerationsUsed >= AI_MONTHLY_LIMIT) {
      throw new ForbiddenException(
        `Límite mensual de ${AI_MONTHLY_LIMIT} generaciones de IA alcanzado`,
      );
    }

    user.aiGenerationsUsed += 1;
    await this.usersRepository.save(user);
  }

  async getAiGenerationsInfo(
    userId: string,
  ): Promise<{ used: number; limit: number; unlimited: boolean }> {
    const user = await this.findById(userId);
    return {
      used: isUnlimited(user) ? 0 : user.aiGenerationsUsed,
      limit: AI_MONTHLY_LIMIT,
      unlimited: isUnlimited(user),
    };
  }

  getWeightLogs(userId: string): Promise<WeightLog[]> {
    return this.weightLogsRepository.find({
      where: { userId },
      order: { recordedAt: 'ASC' },
    });
  }

  private isWeightChangeProgress(goal: Goal | null, deltaKg: number): boolean {
    if (goal === Goal.LOSE_WEIGHT) return deltaKg < 0;
    if (goal === Goal.GAIN_MUSCLE) return deltaKg > 0;
    return false;
  }
}

function toDateOnly(date: Date): string {
  return date.toISOString().slice(0, 10);
}
