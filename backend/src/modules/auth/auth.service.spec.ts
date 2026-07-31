import { ConflictException, UnauthorizedException } from '@nestjs/common';
import * as bcrypt from 'bcrypt';
import { AuthService } from './auth.service';
import { UsersService } from '../users/users.service';
import { RefreshToken } from './entities/refresh-token.entity';

describe('AuthService', () => {
  let authService: AuthService;
  let usersService: jest.Mocked<
    Pick<UsersService, 'findByEmail' | 'create' | 'findById'>
  >;
  let jwtService: { signAsync: jest.Mock; verifyAsync: jest.Mock };
  let configService: { get: jest.Mock };
  let refreshTokensRepository: {
    find: jest.Mock;
    save: jest.Mock;
    create: jest.Mock;
    delete: jest.Mock;
  };

  const baseUser = {
    id: 'user-1',
    email: 'test@chefai.com',
    role: 'user',
  };

  beforeEach(() => {
    usersService = {
      findByEmail: jest.fn(),
      create: jest.fn(),
      findById: jest.fn(),
    };
    jwtService = {
      signAsync: jest.fn().mockResolvedValue('signed-token'),
      verifyAsync: jest.fn(),
    };
    configService = {
      get: jest.fn((key: string) => {
        const values: Record<string, string> = {
          JWT_ACCESS_SECRET: 'access-secret',
          JWT_ACCESS_EXPIRES_IN: '15m',
          JWT_REFRESH_SECRET: 'refresh-secret',
          JWT_REFRESH_EXPIRES_IN: '7d',
        };
        return values[key];
      }),
    };
    refreshTokensRepository = {
      find: jest.fn().mockResolvedValue([]),
      save: jest.fn((entity) => Promise.resolve(entity)),
      create: jest.fn((entity) => entity),
      delete: jest.fn().mockResolvedValue(undefined),
    };

    authService = new AuthService(
      usersService as unknown as UsersService,
      jwtService as any,
      configService as any,
      refreshTokensRepository as any,
    );
  });

  describe('register', () => {
    it('lanza ConflictException si el email ya existe', async () => {
      usersService.findByEmail.mockResolvedValue(baseUser as any);

      await expect(
        authService.register({
          email: baseUser.email,
          password: 'password123',
          name: 'Test',
        }),
      ).rejects.toThrow(ConflictException);
    });

    it('crea el usuario y devuelve tokens si el email es nuevo', async () => {
      usersService.findByEmail.mockResolvedValue(null);
      usersService.create.mockResolvedValue(baseUser as any);

      const tokens = await authService.register({
        email: baseUser.email,
        password: 'password123',
        name: 'Test',
      });

      expect(usersService.create).toHaveBeenCalledWith(
        expect.objectContaining({ email: baseUser.email, name: 'Test' }),
      );
      expect(tokens).toEqual({
        accessToken: 'signed-token',
        refreshToken: 'signed-token',
      });
      expect(refreshTokensRepository.save).toHaveBeenCalled();
    });
  });

  describe('login', () => {
    it('lanza UnauthorizedException si el usuario no existe', async () => {
      usersService.findByEmail.mockResolvedValue(null);

      await expect(
        authService.login({ email: 'nadie@chefai.com', password: 'x' }),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('lanza UnauthorizedException si la contraseña no coincide', async () => {
      const passwordHash = await bcrypt.hash('correcta123', 10);
      usersService.findByEmail.mockResolvedValue({
        ...baseUser,
        passwordHash,
      } as any);

      await expect(
        authService.login({ email: baseUser.email, password: 'incorrecta' }),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('devuelve tokens si la contraseña coincide', async () => {
      const passwordHash = await bcrypt.hash('correcta123', 10);
      usersService.findByEmail.mockResolvedValue({
        ...baseUser,
        passwordHash,
      } as any);

      const tokens = await authService.login({
        email: baseUser.email,
        password: 'correcta123',
      });

      expect(tokens).toEqual({
        accessToken: 'signed-token',
        refreshToken: 'signed-token',
      });
    });
  });

  describe('refresh', () => {
    it('lanza UnauthorizedException si el JWT no verifica', async () => {
      jwtService.verifyAsync.mockRejectedValue(new Error('invalid'));

      await expect(authService.refresh('token-invalido')).rejects.toThrow(
        UnauthorizedException,
      );
    });

    it('lanza UnauthorizedException si no hay un token guardado que matchee', async () => {
      jwtService.verifyAsync.mockResolvedValue({
        sub: baseUser.id,
        email: baseUser.email,
        role: 'user',
      });
      refreshTokensRepository.find.mockResolvedValue([]);

      await expect(authService.refresh('token-no-guardado')).rejects.toThrow(
        UnauthorizedException,
      );
    });

    it('rota el token y devuelve nuevos tokens cuando matchea', async () => {
      const rawRefreshToken = 'valid-refresh-token';
      const tokenHash = await bcrypt.hash(rawRefreshToken, 10);
      const storedToken: Partial<RefreshToken> = {
        id: 'rt-1',
        userId: baseUser.id,
        tokenHash,
        revoked: false,
        expiresAt: new Date(Date.now() + 60_000),
      };

      jwtService.verifyAsync.mockResolvedValue({
        sub: baseUser.id,
        email: baseUser.email,
        role: 'user',
      });
      refreshTokensRepository.find.mockResolvedValue([storedToken]);
      usersService.findById.mockResolvedValue(baseUser as any);

      const tokens = await authService.refresh(rawRefreshToken);

      expect(storedToken.revoked).toBe(true);
      expect(tokens).toEqual({
        accessToken: 'signed-token',
        refreshToken: 'signed-token',
      });
    });
  });
});
