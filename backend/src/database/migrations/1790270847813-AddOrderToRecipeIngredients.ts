import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddOrderToRecipeIngredients1790270847813
  implements MigrationInterface
{
  name = 'AddOrderToRecipeIngredients1790270847813';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "recipe_ingredients" ADD "order" integer NOT NULL DEFAULT 0`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "recipe_ingredients" DROP COLUMN "order"`,
    );
  }
}
