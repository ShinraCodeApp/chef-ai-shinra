import { Body, Controller, Get, Patch, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import {
  AuthenticatedUser,
  CurrentUser,
} from '../../common/decorators/current-user.decorator';
import { UsersService } from './users.service';
import { UpdateProfileDto } from './dto/update-profile.dto';

/** El hash de la contraseña nunca sale en las respuestas. */
function withoutPassword<T extends { passwordHash?: unknown }>(
  user: T,
): Omit<T, 'passwordHash'> {
  const profile = { ...user };
  delete profile.passwordHash;
  return profile;
}

@Controller('users')
@UseGuards(JwtAuthGuard)
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get('me')
  async getMe(@CurrentUser() user: AuthenticatedUser) {
    return withoutPassword(await this.usersService.findById(user.userId));
  }

  @Patch('me')
  async updateMe(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: UpdateProfileDto,
  ) {
    const { user: updated, weightProgress } =
      await this.usersService.updateProfile(user.userId, dto);
    return { ...withoutPassword(updated), weightProgress };
  }

  @Get('me/weight-logs')
  getWeightLogs(@CurrentUser() user: AuthenticatedUser) {
    return this.usersService.getWeightLogs(user.userId);
  }

  @Get('me/ai-info')
  getAiInfo(@CurrentUser() user: AuthenticatedUser) {
    return this.usersService.getAiGenerationsInfo(user.userId);
  }
}
