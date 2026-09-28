import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddCompletedAndMoreMealTypes1790428950681
  implements MigrationInterface
{
  name = 'AddCompletedAndMoreMealTypes1790428950681';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "meal_plan_entries" ADD "completed" boolean NOT NULL DEFAULT false`,
    );
    await queryRunner.query(
      `ALTER TYPE "public"."meal_plan_entries_mealtype_enum" ADD VALUE 'mid_morning'`,
    );
    await queryRunner.query(
      `ALTER TYPE "public"."meal_plan_entries_mealtype_enum" ADD VALUE 'post_workout'`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "meal_plan_entries" DROP COLUMN "completed"`,
    );
    // Postgres no soporta quitar un valor de un enum directamente; recrear el tipo
    // sin los 2 valores nuevos requeriría migrar la columna a un tipo temporal.
    // Se deja sin revertir automáticamente porque en la práctica nunca hicimos
    // rollback de un ADD VALUE en este proyecto.
  }
}
