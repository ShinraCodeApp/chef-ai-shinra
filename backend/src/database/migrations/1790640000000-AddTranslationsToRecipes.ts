import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * Traducciones de las recetas del catálogo (por ahora inglés):
 * { en: { title, description, instructions[], tips[], ingredientNotes[] } }.
 * Las recetas generadas por IA no lo necesitan: se generan en el idioma del usuario.
 */
export class AddTranslationsToRecipes1790640000000 implements MigrationInterface {
  name = 'AddTranslationsToRecipes1790640000000';

  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE recipes ADD COLUMN IF NOT EXISTS "translations" jsonb NULL`,
    );
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE recipes DROP COLUMN IF EXISTS "translations"`,
    );
  }
}
