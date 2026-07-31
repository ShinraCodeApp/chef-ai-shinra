import {
  Body,
  Controller,
  Delete,
  Get,
  NotFoundException,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { UserRole } from '../../common/enums';
import { IngredientsService } from './ingredients.service';
import { CreateIngredientDto } from './dto/create-ingredient.dto';
import { UpdateIngredientDto } from './dto/update-ingredient.dto';
import { QueryIngredientsDto } from './dto/query-ingredients.dto';

@Controller('ingredients')
@UseGuards(JwtAuthGuard)
export class IngredientsController {
  constructor(private readonly ingredientsService: IngredientsService) {}

  @Post()
  create(@Body() dto: CreateIngredientDto) {
    return this.ingredientsService.create(dto);
  }

  @Get()
  findAll(@Query() query: QueryIngredientsDto) {
    return this.ingredientsService.findAll(
      query.search,
      query.page ?? 1,
      query.limit ?? 20,
    );
  }

  @Get('barcode/:barcode')
  async findByBarcode(@Param('barcode') barcode: string) {
    const ingredient =
      await this.ingredientsService.findByBarcodeOrFetch(barcode);
    if (!ingredient) {
      throw new NotFoundException(
        'No se encontró el producto en el catálogo ni en Open Food Facts',
      );
    }
    return ingredient;
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.ingredientsService.findOne(id);
  }

  // Cualquier usuario autenticado puede crear ingredientes nuevos (ej. al cargar
  // algo al inventario que no está en el catálogo). Editar/borrar un ingrediente
  // ya existente afecta a todos los usuarios, así que queda restringido a admin.
  @Patch(':id')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN)
  update(@Param('id') id: string, @Body() dto: UpdateIngredientDto) {
    return this.ingredientsService.update(id, dto);
  }

  @Delete(':id')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN)
  remove(@Param('id') id: string) {
    return this.ingredientsService.remove(id);
  }
}
