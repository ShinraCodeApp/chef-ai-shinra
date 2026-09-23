import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddTipsToRecipes1790174466391 implements MigrationInterface {
  name = 'AddTipsToRecipes1790174466391';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "recipes" ADD "tips" text array`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "recipes" DROP COLUMN "tips"`);
  }
}
