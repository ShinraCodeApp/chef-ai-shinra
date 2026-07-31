import {
  ConflictException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService, JwtSignOptions } from '@nestjs/jwt';
import { InjectRepository } from '@nestjs/typeorm';
import { LessThan, Repository } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { UsersService } from '../users/users.service';
import { RefreshToken } from './entities/refresh-token.entity';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { User } from '../users/entities/user.entity';

export interface JwtPayload {
  sub: string;
  email: string;
  role: string;
}

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
}

const SALT_ROUNDS = 10;

@Injectable()
export class AuthService {
  constructor(
    private readonly usersService: UsersService,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    @InjectRepository(RefreshToken)
    private readonly refreshTokensRepository: Repository<RefreshToken>,
  ) {}

  async register(dto: RegisterDto): Promise<AuthTokens> {
    const existing = await this.usersService.findByEmail(dto.email);
    if (existing) {
      throw new ConflictException('Ya existe una cuenta con ese email');
    }
    const passwordHash = await bcrypt.hash(dto.password, SALT_ROUNDS);
    const user = await this.usersService.create({
      email: dto.email,
      passwordHash,
      name: dto.name,
    });
    return this.issueTokens(user);
  }

  async login(dto: LoginDto): Promise<AuthTokens> {
    const user = await this.usersService.findByEmail(dto.email);
    if (!user) {
      throw new UnauthorizedException('Credenciales inválidas');
    }
    const passwordMatches = await bcrypt.compare(
      dto.password,
      user.passwordHash,
    );
    if (!passwordMatches) {
      throw new UnauthorizedException('Credenciales inválidas');
    }
    return this.issueTokens(user);
  }

  async refresh(rawRefreshToken: string): Promise<AuthTokens> {
    let payload: JwtPayload;
    try {
      payload = await this.jwtService.verifyAsync<JwtPayload>(rawRefreshToken, {
        secret: this.configService.get<string>('JWT_REFRESH_SECRET'),
      });
    } catch {
      throw new UnauthorizedException('Refresh token inválido o expirado');
    }

    const candidates = await this.refreshTokensRepository.find({
      where: { userId: payload.sub, revoked: false },
    });

    const matching = await this.findMatchingToken(candidates, rawRefreshToken);
    if (!matching || matching.expiresAt < new Date()) {
      throw new UnauthorizedException('Refresh token inválido o expirado');
    }

    matching.revoked = true;
    await this.refreshTokensRepository.save(matching);

    const user = await this.usersService.findById(payload.sub);
    return this.issueTokens(user);
  }

  async logout(userId: string, rawRefreshToken: string): Promise<void> {
    const candidates = await this.refreshTokensRepository.find({
      where: { userId, revoked: false },
    });
    const matching = await this.findMatchingToken(candidates, rawRefreshToken);
    if (matching) {
      matching.revoked = true;
      await this.refreshTokensRepository.save(matching);
    }
  }

  private async findMatchingToken(
    candidates: RefreshToken[],
    rawRefreshToken: string,
  ): Promise<RefreshToken | null> {
    for (const candidate of candidates) {
      if (await bcrypt.compare(rawRefreshToken, candidate.tokenHash)) {
        return candidate;
      }
    }
    return null;
  }

  private async issueTokens(user: User): Promise<AuthTokens> {
    const payload: JwtPayload = {
      sub: user.id,
      email: user.email,
      role: user.role,
    };

    const accessToken = await this.jwtService.signAsync(payload, {
      secret: this.configService.get<string>('JWT_ACCESS_SECRET'),
      expiresIn: this.configService.get<string>('JWT_ACCESS_EXPIRES_IN'),
    } as JwtSignOptions);

    const refreshExpiresIn = this.configService.get<string>(
      'JWT_REFRESH_EXPIRES_IN',
    );
    const refreshToken = await this.jwtService.signAsync(payload, {
      secret: this.configService.get<string>('JWT_REFRESH_SECRET'),
      expiresIn: refreshExpiresIn,
    } as JwtSignOptions);

    const tokenHash = await bcrypt.hash(refreshToken, SALT_ROUNDS);
    await this.refreshTokensRepository.save(
      this.refreshTokensRepository.create({
        userId: user.id,
        tokenHash,
        expiresAt: addDuration(new Date(), refreshExpiresIn),
      }),
    );

    // limpieza best-effort de tokens vencidos para no acumular filas indefinidamente
    await this.refreshTokensRepository.delete({
      userId: user.id,
      expiresAt: LessThan(new Date()),
    });

    return { accessToken, refreshToken };
  }
}

function addDuration(base: Date, duration: string): Date {
  const match = /^(\d+)([smhd])$/.exec(duration.trim());
  if (!match) {
    // fallback conservador si el formato no es el esperado (ej: "7d")
    return new Date(base.getTime() + 7 * 24 * 60 * 60 * 1000);
  }
  const value = Number(match[1]);
  const unit = match[2];
  const unitMs: Record<string, number> = {
    s: 1000,
    m: 60 * 1000,
    h: 60 * 60 * 1000,
    d: 24 * 60 * 60 * 1000,
  };
  return new Date(base.getTime() + value * unitMs[unit]);
}
