import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { ILike, Repository } from 'typeorm';
import { Ingredient } from './entities/ingredient.entity';
import { CreateIngredientDto } from './dto/create-ingredient.dto';
import { UpdateIngredientDto } from './dto/update-ingredient.dto';
import { IngredientCategory, IngredientUnit } from '../../common/enums';
import {
  paginate,
  PaginatedResult,
} from '../../common/dto/pagination-query.dto';
import { OpenFoodFactsService } from './open-food-facts.service';

@Injectable()
export class IngredientsService {
  constructor(
    @InjectRepository(Ingredient)
    private readonly ingredientsRepository: Repository<Ingredient>,
    private readonly openFoodFactsService: OpenFoodFactsService,
  ) {}

  create(dto: CreateIngredientDto): Promise<Ingredient> {
    return this.ingredientsRepository.save(
      this.ingredientsRepository.create(dto),
    );
  }

  async findAll(
    search: string | undefined,
    page: number,
    limit: number,
  ): Promise<PaginatedResult<Ingredient>> {
    const [items, total] = await this.ingredientsRepository.findAndCount({
      where: search ? { name: ILike(`%${search}%`) } : {},
      order: { name: 'ASC' },
      skip: (page - 1) * limit,
      take: limit,
    });
    return paginate(items, total, page, limit);
  }

  async findOne(id: string): Promise<Ingredient> {
    const ingredient = await this.ingredientsRepository.findOne({
      where: { id },
    });
    if (!ingredient) {
      throw new NotFoundException('Ingrediente no encontrado');
    }
    return ingredient;
  }

  async findByBarcode(barcode: string): Promise<Ingredient | null> {
    return this.ingredientsRepository.findOne({ where: { barcode } });
  }

  /**
   * Busca el ingrediente por código de barras en el catálogo propio; si no existe,
   * lo busca en Open Food Facts (base pública gratuita) y lo crea automáticamente.
   */
  async findByBarcodeOrFetch(barcode: string): Promise<Ingredient | null> {
    const existing = await this.findByBarcode(barcode);
    if (existing) {
      return existing;
    }
    const fetched = await this.openFoodFactsService.lookup(barcode);
    if (!fetched) {
      return null;
    }
    return this.create(fetched);
  }

  /** Encuentra por nombre exacto (case-insensitive) o lo crea si no existe. Usado por IA e importaciones. */
  async findOrCreateByName(
    name: string,
    defaults: Partial<CreateIngredientDto>,
  ): Promise<Ingredient> {
    const existing = await this.ingredientsRepository.findOne({
      where: { name: ILike(name) },
    });
    if (existing) {
      return existing;
    }
    return this.create({
      category: IngredientCategory.OTROS,
      unit: IngredientUnit.UNIT,
      ...defaults,
      name,
    });
  }

  async update(id: string, dto: UpdateIngredientDto): Promise<Ingredient> {
    const ingredient = await this.findOne(id);
    Object.assign(ingredient, dto);
    return this.ingredientsRepository.save(ingredient);
  }

  async remove(id: string): Promise<void> {
    const ingredient = await this.findOne(id);
    await this.ingredientsRepository.remove(ingredient);
  }
}
