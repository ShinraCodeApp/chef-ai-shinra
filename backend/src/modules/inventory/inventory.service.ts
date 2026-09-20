import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { InventoryItem } from './entities/inventory-item.entity';
import { CreateInventoryItemDto } from './dto/create-inventory-item.dto';
import { UpdateInventoryItemDto } from './dto/update-inventory-item.dto';
import { IngredientUnit, InventoryItemSource } from '../../common/enums';
import { convertQuantity } from '../../common/utils/unit-conversion';

@Injectable()
export class InventoryService {
  constructor(
    @InjectRepository(InventoryItem)
    private readonly inventoryRepository: Repository<InventoryItem>,
  ) {}

  findAllForUser(userId: string): Promise<InventoryItem[]> {
    return this.inventoryRepository.find({
      where: { userId },
      order: { addedAt: 'DESC' },
    });
  }

  async create(
    userId: string,
    dto: CreateInventoryItemDto,
  ): Promise<InventoryItem> {
    const item = this.inventoryRepository.create({
      ...dto,
      userId,
      ingredient: { id: dto.ingredientId },
      source: dto.source ?? InventoryItemSource.MANUAL,
    });
    return this.inventoryRepository.save(item);
  }

  private async findOwned(userId: string, id: string): Promise<InventoryItem> {
    const item = await this.inventoryRepository.findOne({
      where: { id, userId },
    });
    if (!item) {
      throw new NotFoundException('Ítem de inventario no encontrado');
    }
    return item;
  }

  async update(
    userId: string,
    id: string,
    dto: UpdateInventoryItemDto,
  ): Promise<InventoryItem> {
    const item = await this.findOwned(userId, id);
    Object.assign(item, dto);
    return this.inventoryRepository.save(item);
  }

  async remove(userId: string, id: string): Promise<void> {
    const item = await this.findOwned(userId, id);
    await this.inventoryRepository.remove(item);
  }

  /**
   * Descuenta (o elimina si llega a 0) la cantidad de un ingrediente del inventario
   * del usuario. Usado al marcar una receta como "cocinada". Si el usuario no tiene
   * ese ingrediente en inventario, no hace nada (no todo lo que usa una receta
   * viene necesariamente del inventario registrado). Convierte unidades cuando son
   * de la misma magnitud (g/kg, ml/l); si son incompatibles (ej. "unidad" vs "g")
   * ese ítem del inventario se deja intacto porque no hay forma confiable de reconciliar.
   *
   * Devuelve la cantidad (en `unit`) que no pudo descontarse por no haber suficiente
   * en inventario — se usa para ofrecerle al usuario agregar lo faltante a la lista
   * de compras.
   */
  async consume(
    userId: string,
    ingredientId: string,
    quantity: number,
    unit: IngredientUnit,
  ): Promise<number> {
    const items = await this.inventoryRepository.find({
      where: { userId, ingredientId },
      order: { addedAt: 'ASC' },
    });

    let remainingToConsume = quantity;
    for (const item of items) {
      if (remainingToConsume <= 0) break;

      const itemQuantityInRequestedUnit = convertQuantity(
        item.quantity,
        item.unit,
        unit,
      );
      if (itemQuantityInRequestedUnit === null) {
        continue; // unidades incompatibles, no se puede descontar de este ítem
      }

      if (itemQuantityInRequestedUnit <= remainingToConsume) {
        remainingToConsume -= itemQuantityInRequestedUnit;
        await this.inventoryRepository.remove(item);
      } else {
        const consumedInItemUnit = convertQuantity(
          remainingToConsume,
          unit,
          item.unit,
        )!;
        item.quantity -= consumedInItemUnit;
        remainingToConsume = 0;
        await this.inventoryRepository.save(item);
      }
    }
    return remainingToConsume;
  }
}
