import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import {
  AuthenticatedUser,
  CurrentUser,
} from '../../common/decorators/current-user.decorator';
import { ShoppingListsService } from './shopping-lists.service';
import { CreateShoppingListDto } from './dto/create-shopping-list.dto';
import { CreateShoppingListItemDto } from './dto/create-shopping-list-item.dto';
import { GenerateFromMealPlanDto } from './dto/generate-from-meal-plan.dto';

@Controller('shopping-lists')
@UseGuards(JwtAuthGuard)
export class ShoppingListsController {
  constructor(private readonly shoppingListsService: ShoppingListsService) {}

  @Post()
  create(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreateShoppingListDto,
  ) {
    return this.shoppingListsService.create(user.userId, dto);
  }

  @Post('generate-from-meal-plan')
  generateFromMealPlan(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: GenerateFromMealPlanDto,
  ) {
    return this.shoppingListsService.generateFromMealPlan(
      user.userId,
      dto.mealPlanId,
    );
  }

  @Get()
  findAll(@CurrentUser() user: AuthenticatedUser) {
    return this.shoppingListsService.findAllForUser(user.userId);
  }

  @Post(':id/items')
  addItem(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') listId: string,
    @Body() dto: CreateShoppingListItemDto,
  ) {
    return this.shoppingListsService.addItem(user.userId, listId, dto);
  }

  @Post(':id/items/:itemId/toggle')
  toggleChecked(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') listId: string,
    @Param('itemId') itemId: string,
  ) {
    return this.shoppingListsService.toggleChecked(user.userId, listId, itemId);
  }

  @Delete(':id/items/:itemId')
  removeItem(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') listId: string,
    @Param('itemId') itemId: string,
  ) {
    return this.shoppingListsService.removeItem(user.userId, listId, itemId);
  }
}
