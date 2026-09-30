import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Contact, ContactStatus } from './entities/contact.entity';
import { User } from '../users/entities/user.entity';
import { InventoryItem } from '../inventory/entities/inventory-item.entity';

@Injectable()
export class ContactsService {
  constructor(
    @InjectRepository(Contact)
    private readonly contactsRepo: Repository<Contact>,
    @InjectRepository(User)
    private readonly usersRepo: Repository<User>,
    @InjectRepository(InventoryItem)
    private readonly inventoryRepo: Repository<InventoryItem>,
  ) {}

  async sendInvite(requesterId: string, addresseeEmail: string): Promise<Contact> {
    const addressee = await this.usersRepo.findOne({ where: { email: addresseeEmail } });
    if (!addressee) throw new NotFoundException('Usuario no encontrado con ese email');
    if (addressee.id === requesterId) throw new BadRequestException('No podés agregarte a vos mismo');

    const existing = await this.contactsRepo.findOne({
      where: [
        { requesterId, addresseeId: addressee.id },
        { requesterId: addressee.id, addresseeId: requesterId },
      ],
    });
    if (existing) {
      if (existing.status === ContactStatus.ACCEPTED) throw new BadRequestException('Ya son contactos');
      if (existing.status === ContactStatus.PENDING) throw new BadRequestException('Ya hay una invitación pendiente');
      // si fue rechazada, permitir reenviar
      existing.status = ContactStatus.PENDING;
      existing.requesterId = requesterId;
      existing.addresseeId = addressee.id;
      return this.contactsRepo.save(existing);
    }

    const contact = this.contactsRepo.create({ requesterId, addresseeId: addressee.id });
    return this.contactsRepo.save(contact);
  }

  async respondInvite(userId: string, contactId: string, accept: boolean): Promise<Contact> {
    const contact = await this.contactsRepo.findOne({ where: { id: contactId } });
    if (!contact) throw new NotFoundException('Invitación no encontrada');
    if (contact.addresseeId !== userId) throw new ForbiddenException('No sos el destinatario de esta invitación');
    if (contact.status !== ContactStatus.PENDING) throw new BadRequestException('Esta invitación ya fue procesada');

    contact.status = accept ? ContactStatus.ACCEPTED : ContactStatus.REJECTED;
    return this.contactsRepo.save(contact);
  }

  async getContacts(userId: string): Promise<any[]> {
    const rows = await this.contactsRepo.find({
      where: [
        { requesterId: userId, status: ContactStatus.ACCEPTED },
        { addresseeId: userId, status: ContactStatus.ACCEPTED },
      ],
      relations: { requester: true, addressee: true },
    });

    return rows.map((c) => {
      const contact = c.requesterId === userId ? c.addressee : c.requester;
      return {
        contactId: c.id,
        userId: contact.id,
        name: contact.name,
        email: contact.email,
        isFavorite: c.isFavorite,
      };
    });
  }

  async getPendingInvites(userId: string): Promise<any[]> {
    const rows = await this.contactsRepo.find({
      where: { addresseeId: userId, status: ContactStatus.PENDING },
      relations: { requester: true },
    });
    return rows.map((c) => ({
      contactId: c.id,
      from: { userId: c.requester.id, name: c.requester.name, email: c.requester.email },
      createdAt: c.createdAt,
    }));
  }

  async getSentInvites(userId: string): Promise<any[]> {
    const rows = await this.contactsRepo.find({
      where: { requesterId: userId, status: ContactStatus.PENDING },
      relations: { addressee: true },
    });
    return rows.map((c) => ({
      contactId: c.id,
      to: { userId: c.addressee.id, name: c.addressee.name, email: c.addressee.email },
      createdAt: c.createdAt,
    }));
  }

  async removeContact(userId: string, contactId: string): Promise<void> {
    const contact = await this.contactsRepo.findOne({ where: { id: contactId } });
    if (!contact) throw new NotFoundException('Contacto no encontrado');
    if (contact.requesterId !== userId && contact.addresseeId !== userId) {
      throw new ForbiddenException('No tenés permiso para eliminar este contacto');
    }
    await this.contactsRepo.remove(contact);
  }

  async findByEmails(
    userId: string,
    emails: string[],
  ): Promise<{ userId: string; name: string; email: string; isContact: boolean }[]> {
    if (emails.length === 0) return [];

    const users = await this.usersRepo
      .createQueryBuilder('user')
      .where('user.email IN (:...emails)', { emails })
      .andWhere('user.id != :userId', { userId })
      .select(['user.id', 'user.name', 'user.email'])
      .getMany();

    if (users.length === 0) return [];

    const userIds = users.map((u) => u.id);
    const existingContacts = await this.contactsRepo.find({
      where: [
        { requesterId: userId, status: ContactStatus.ACCEPTED },
        { addresseeId: userId, status: ContactStatus.ACCEPTED },
      ],
    });
    const contactUserIds = new Set(
      existingContacts.map((c) =>
        c.requesterId === userId ? c.addresseeId : c.requesterId,
      ),
    );

    return users.map((u) => ({
      userId: u.id,
      name: u.name,
      email: u.email,
      isContact: contactUserIds.has(u.id),
    }));
  }

  async toggleFavorite(userId: string, contactId: string): Promise<boolean> {
    const contact = await this.contactsRepo.findOne({ where: { id: contactId } });
    if (!contact) throw new NotFoundException('Contacto no encontrado');
    if (contact.requesterId !== userId && contact.addresseeId !== userId) {
      throw new ForbiddenException('No tenés permiso');
    }
    if (contact.status !== ContactStatus.ACCEPTED) {
      throw new BadRequestException('Solo podés marcar como favorito a contactos aceptados');
    }
    contact.isFavorite = !contact.isFavorite;
    await this.contactsRepo.save(contact);
    return contact.isFavorite;
  }

  async getContactInventory(userId: string, contactUserId: string): Promise<InventoryItem[]> {
    const isContact = await this.contactsRepo.findOne({
      where: [
        { requesterId: userId, addresseeId: contactUserId, status: ContactStatus.ACCEPTED },
        { requesterId: contactUserId, addresseeId: userId, status: ContactStatus.ACCEPTED },
      ],
    });
    if (!isContact) throw new ForbiddenException('No sos contacto de este usuario');

    return this.inventoryRepo.find({
      where: { userId: contactUserId },
      order: { addedAt: 'DESC' },
    });
  }
}
