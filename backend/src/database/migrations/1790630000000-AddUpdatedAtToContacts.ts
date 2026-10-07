import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * La entidad Contact tiene @UpdateDateColumn() updatedAt, pero la migración que
 * creó la tabla no la agregó. Cualquier consulta a contacts fallaba con
 * "column Contact.updatedAt does not exist" → 500 al invitar y al buscar
 * contactos del celular que tienen la app.
 */
export class AddUpdatedAtToContacts1790630000000 implements MigrationInterface {
  name = 'AddUpdatedAtToContacts1790630000000';

  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE contacts
      ADD COLUMN IF NOT EXISTS "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
    `);
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE contacts DROP COLUMN IF EXISTS "updatedAt"`);
  }
}
