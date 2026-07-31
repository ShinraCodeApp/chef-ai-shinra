import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import {
  AuthenticatedUser,
  CurrentUser,
} from '../../common/decorators/current-user.decorator';
import { RecipesService } from './recipes.service';
import { CreateRecipeDto } from './dto/create-recipe.dto';
import { UpdateRecipeDto } from './dto/update-recipe.dto';
import { QueryRecipesDto } from './dto/query-recipes.dto';

@Controller('recipes')
@UseGuards(JwtAuthGuard)
export class RecipesController {
  constructor(private readonly recipesService: RecipesService) {}

  @Post()
  create(@CurrentUser() user: AuthenticatedUser, @Body() dto: CreateRecipeDto) {
    return this.recipesService.create(dto, { createdByUserId: user.userId });
  }

  @Get()
  findAll(
    @CurrentUser() user: AuthenticatedUser,
    @Query() query: QueryRecipesDto,
  ) {
    return this.recipesService.findAll(query, user.userId);
  }

  @Get('favorites')
  findFavorites(@CurrentUser() user: AuthenticatedUser) {
    return this.recipesService.findFavorites(user.userId);
  }

  @Get(':id')
  findOne(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.recipesService.findOne(id, user.userId);
  }

  @Patch(':id')
  update(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() dto: UpdateRecipeDto,
  ) {
    return this.recipesService.update(id, dto, {
      userId: user.userId,
      role: user.role,
    });
  }

  @Delete(':id')
  remove(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.recipesService.remove(id, {
      userId: user.userId,
      role: user.role,
    });
  }

  @Post(':id/cook')
  cook(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body('servingsMultiplier') servingsMultiplier?: number,
  ) {
    return this.recipesService.cook(user.userId, id, servingsMultiplier ?? 1);
  }

  @Post(':id/favorite')
  toggleFavorite(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
  ) {
    return this.recipesService.toggleFavorite(user.userId, id);
  }
}
