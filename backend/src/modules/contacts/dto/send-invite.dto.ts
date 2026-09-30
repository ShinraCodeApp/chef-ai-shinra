import { IsEmail } from 'class-validator';

export class SendInviteDto {
  @IsEmail()
  email: string;
}
