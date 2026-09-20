import 'reflect-metadata';
import * as path from 'path';
import { DataSource } from 'typeorm';
import * as dotenv from 'dotenv';
import * as bcrypt from 'bcrypt';
import { User } from '../../modules/users/entities/user.entity';
import { UserRole } from '../../common/enums';

dotenv.config();

const SALT_ROUNDS = 10;

const ADMIN_EMAIL = 'admin@chefai.com';
const ADMIN_PASSWORD = 'admin132';
const ADMIN_NAME = 'Super Admin';

async function run() {
  const dataSource = new DataSource({
    type: 'postgres',
    host: process.env.DB_HOST,
    port: Number(process.env.DB_PORT ?? 5432),
    username: process.env.DB_USERNAME,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    // se registran todas las entities (no solo User) porque TypeORM necesita
    // resolver las relaciones inversas declaradas en User (inventoryItems, favorites, etc.)
    entities: [path.join(__dirname, '../../modules/**/*.entity.{ts,js}')],
  });

  await dataSource.initialize();
  const usersRepository = dataSource.getRepository(User);

  const passwordHash = await bcrypt.hash(ADMIN_PASSWORD, SALT_ROUNDS);
  const existing = await usersRepository.findOne({
    where: { email: ADMIN_EMAIL },
  });

  if (existing) {
    existing.passwordHash = passwordHash;
    existing.role = UserRole.ADMIN;
    existing.onboardingCompleted = true;
    await usersRepository.save(existing);
    console.log(`Admin ya existía: se actualizó su contraseña y rol (${ADMIN_EMAIL}).`);
  } else {
    const admin = usersRepository.create({
      email: ADMIN_EMAIL,
      passwordHash,
      name: ADMIN_NAME,
      role: UserRole.ADMIN,
      onboardingCompleted: true,
    });
    await usersRepository.save(admin);
    console.log(`Admin creado: ${ADMIN_EMAIL}`);
  }

  await dataSource.destroy();
}

run().catch((error) => {
  console.error('Error corriendo el seed:', error);
  process.exit(1);
});
