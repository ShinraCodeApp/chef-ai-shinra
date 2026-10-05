import { ForbiddenException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { RolesGuard } from './roles.guard';
import { UserRole } from '../enums';

function contextFor(user: unknown) {
  return {
    getHandler: () => null,
    getClass: () => null,
    switchToHttp: () => ({ getRequest: () => ({ user }) }),
  } as any;
}

function guardRequiring(roles: UserRole[] | undefined) {
  const reflector = { getAllAndOverride: () => roles } as unknown as Reflector;
  return new RolesGuard(reflector);
}

describe('RolesGuard — un único admin', () => {
  const admin = guardRequiring([UserRole.ADMIN]);

  it('deja pasar a admin@chefai.com con rol admin', () => {
    expect(
      admin.canActivate(
        contextFor({ email: 'Admin@ChefAI.com', role: 'admin' }),
      ),
    ).toBe(true);
  });

  it('otra cuenta con rol admin en la base no entra', () => {
    expect(() =>
      admin.canActivate(contextFor({ email: 'otro@mail.com', role: 'admin' })),
    ).toThrow(ForbiddenException);
  });

  it('un usuario común no entra', () => {
    expect(() =>
      admin.canActivate(
        contextFor({ email: 'admin@chefai.com', role: 'user' }),
      ),
    ).toThrow(ForbiddenException);
  });

  it('las rutas sin @Roles no se restringen', () => {
    expect(
      guardRequiring(undefined).canActivate(
        contextFor({ email: 'x', role: 'user' }),
      ),
    ).toBe(true);
  });
});
