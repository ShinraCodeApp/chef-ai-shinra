import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { UserRole } from '../../common/enums';
import { IngredientPricesService } from './ingredient-prices.service';
import { CreateIngredientPriceDto } from './dto/create-ingredient-price.dto';

@Controller()
@UseGuards(JwtAuthGuard)
export class IngredientPricesController {
  constructor(private readonly pricesService: IngredientPricesService) {}

  @Post('ingredients/:ingredientId/prices')
  create(
    @Param('ingredientId') ingredientId: string,
    @Body() dto: CreateIngredientPriceDto,
  ) {
    return this.pricesService.create(ingredientId, dto);
  }

  @Get('ingredients/:ingredientId/prices')
  findAll(@Param('ingredientId') ingredientId: string) {
    return this.pricesService.findAllForIngredient(ingredientId);
  }

  @Patch('ingredient-prices/:priceId')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN)
  update(
    @Param('priceId') priceId: string,
    @Body() dto: CreateIngredientPriceDto,
  ) {
    return this.pricesService.update(priceId, dto);
  }

  @Delete('ingredient-prices/:priceId')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN)
  remove(@Param('priceId') priceId: string) {
    return this.pricesService.remove(priceId);
  }
}
