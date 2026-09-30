import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseBoolPipe,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import {
  AuthenticatedUser,
  CurrentUser,
} from '../../common/decorators/current-user.decorator';
import { ContactsService } from './contacts.service';
import { SendInviteDto } from './dto/send-invite.dto';

@Controller('contacts')
@UseGuards(JwtAuthGuard)
export class ContactsController {
  constructor(private readonly contactsService: ContactsService) {}

  @Post('invite')
  sendInvite(@CurrentUser() user: AuthenticatedUser, @Body() dto: SendInviteDto) {
    return this.contactsService.sendInvite(user.userId, dto.email);
  }

  @Post(':id/respond')
  respondInvite(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body('accept', ParseBoolPipe) accept: boolean,
  ) {
    return this.contactsService.respondInvite(user.userId, id, accept);
  }

  @Get()
  getContacts(@CurrentUser() user: AuthenticatedUser) {
    return this.contactsService.getContacts(user.userId);
  }

  @Get('pending')
  getPending(@CurrentUser() user: AuthenticatedUser) {
    return this.contactsService.getPendingInvites(user.userId);
  }

  @Get('sent')
  getSent(@CurrentUser() user: AuthenticatedUser) {
    return this.contactsService.getSentInvites(user.userId);
  }

  @Post('find-by-emails')
  findByEmails(@CurrentUser() user: AuthenticatedUser, @Body('emails') emails: string[]) {
    return this.contactsService.findByEmails(user.userId, emails ?? []);
  }

  @Patch(':id/favorite')
  toggleFavorite(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.contactsService.toggleFavorite(user.userId, id);
  }

  @Delete(':id')
  removeContact(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.contactsService.removeContact(user.userId, id);
  }

  @Get(':userId/inventory')
  getContactInventory(
    @CurrentUser() user: AuthenticatedUser,
    @Param('userId') contactUserId: string,
  ) {
    return this.contactsService.getContactInventory(user.userId, contactUserId);
  }
}
