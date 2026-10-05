import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { IngredientPrice } from './entities/ingredient-price.entity';
import { CreateIngredientPriceDto } from './dto/create-ingredient-price.dto';
import { IngredientsService } from './ingredients.service';
import { IngredientUnit } from '../../common/enums';

/**
 * Los precios se guardan siempre por 1 kg, 1 l o 1 unidad. Antes el escaneo de
 * tickets guardaba el total del renglón con la unidad de la cantidad (350 g de
 * arvejas a $571 quedaba como "$571 el gramo") y el costo de las recetas daba
 * cientos de miles.
 */
export function normalizePrice(dto: CreateIngredientPriceDto): {
  price: number;
  unit: IngredientUnit;
} {
  const perUnit =
    dto.quantity !== undefined ? dto.price / dto.quantity : dto.price;
  const round = (n: number) => Math.round(n * 100) / 100;
  switch (dto.unit) {
    case IngredientUnit.GRAMS:
      return { price: round(perUnit * 1000), unit: IngredientUnit.KILOGRAMS };
    case IngredientUnit.MILLILITERS:
      return { price: round(perUnit * 1000), unit: IngredientUnit.LITERS };
    default:
      return { price: round(perUnit), unit: dto.unit };
  }
}

@Injectable()
export class IngredientPricesService {
  constructor(
    @InjectRepository(IngredientPrice)
    private readonly pricesRepository: Repository<IngredientPrice>,
    private readonly ingredientsService: IngredientsService,
  ) {}

  async create(
    ingredientId: string,
    dto: CreateIngredientPriceDto,
  ): Promise<IngredientPrice> {
    await this.ingredientsService.findOne(ingredientId); // valida que exista
    return this.pricesRepository.save(
      this.pricesRepository.create({ ...normalizePrice(dto), ingredientId }),
    );
  }

  findAllForIngredient(ingredientId: string): Promise<IngredientPrice[]> {
    return this.pricesRepository.find({
      where: { ingredientId },
      order: { updatedAt: 'DESC' },
    });
  }

  /** Precio más reciente cargado para un ingrediente, o null si nunca se cargó ninguno. */
  async findLatestForIngredient(
    ingredientId: string,
  ): Promise<IngredientPrice | null> {
    return this.pricesRepository.findOne({
      where: { ingredientId },
      order: { updatedAt: 'DESC' },
    });
  }

  async update(
    priceId: string,
    dto: CreateIngredientPriceDto,
  ): Promise<IngredientPrice> {
    const price = await this.pricesRepository.findOne({
      where: { id: priceId },
    });
    if (!price) {
      throw new NotFoundException('Precio no encontrado');
    }
    Object.assign(price, dto);
    return this.pricesRepository.save(price);
  }

  async remove(priceId: string): Promise<void> {
    const price = await this.pricesRepository.findOne({
      where: { id: priceId },
    });
    if (!price) {
      throw new NotFoundException('Precio no encontrado');
    }
    await this.pricesRepository.remove(price);
  }
}
