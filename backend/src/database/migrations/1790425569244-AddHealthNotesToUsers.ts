import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddHealthNotesToUsers1790425569244 implements MigrationInterface {
  name = 'AddHealthNotesToUsers1790425569244';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "users" ADD "healthNotes" text`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "users" DROP COLUMN "healthNotes"`);
  }
}
