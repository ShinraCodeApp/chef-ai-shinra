import { IsEnum } from 'class-validator';
import { UserRole } from '../../../common/enums';

export class UpdateUserRoleDto {
  @IsEnum(UserRole)
  role: UserRole;
}
