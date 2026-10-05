import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { ROLES_KEY } from '../decorators/roles.decorator';
import { UserRole } from '../enums';
import { isSuperAdminEmail } from '../super-admin';

/**
 * Se usa junto a JwtAuthGuard (que corre primero y llena request.user).
 * Requiere @Roles(...) en el handler o controller; sin ese decorator, no restringe nada.
 */
@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private readonly reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const requiredRoles = this.reflector.getAllAndOverride<UserRole[]>(
      ROLES_KEY,
      [context.getHandler(), context.getClass()],
    );
    if (!requiredRoles || requiredRoles.length === 0) {
      return true;
    }
    const { user } = context.switchToHttp().getRequest();
    if (!user || !requiredRoles.includes(user.role)) {
      throw new ForbiddenException(
        'No tenés permisos para realizar esta acción',
      );
    }
    // Rol admin solo vale para la cuenta principal: si otra cuenta quedó con
    // rol admin en la base (antes el panel lo permitía), no entra.
    if (
      requiredRoles.includes(UserRole.ADMIN) &&
      !requiredRoles.includes(UserRole.USER) &&
      !isSuperAdminEmail(user.email)
    ) {
      throw new ForbiddenException(
        'No tenés permisos para realizar esta acción',
      );
    }
    return true;
  }
}
