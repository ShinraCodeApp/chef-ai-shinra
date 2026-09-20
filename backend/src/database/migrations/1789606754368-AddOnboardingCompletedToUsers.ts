import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddOnboardingCompletedToUsers1789606754368
  implements MigrationInterface
{
  name = 'AddOnboardingCompletedToUsers1789606754368';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "users" ADD "onboardingCompleted" boolean NOT NULL DEFAULT false`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "users" DROP COLUMN "onboardingCompleted"`,
    );
  }
}
