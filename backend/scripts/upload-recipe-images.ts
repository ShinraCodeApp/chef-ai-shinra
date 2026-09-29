/**
 * Sube todas las imágenes de assets/recipe_images al bucket S3 (IDrive e2).
 * Uso: ts-node -r tsconfig-paths/register scripts/upload-recipe-images.ts
 *
 * Requiere S3_* variables en backend/.env configuradas.
 */

import * as fs from 'fs';
import * as path from 'path';
import * as dotenv from 'dotenv';
import { PutObjectCommand, S3Client } from '@aws-sdk/client-s3';

dotenv.config();

const endpoint = process.env.S3_ENDPOINT;
const accessKeyId = process.env.S3_ACCESS_KEY_ID;
const secretAccessKey = process.env.S3_SECRET_ACCESS_KEY;
const region = process.env.S3_REGION ?? 'us-east-1';
const bucketName = process.env.S3_BUCKET_NAME;
const publicUrl = process.env.S3_PUBLIC_URL;

if (!endpoint || !accessKeyId || !secretAccessKey || !bucketName || !publicUrl) {
  console.error('❌ Faltan variables S3_* en .env. Configurá el storage primero.');
  process.exit(1);
}

const client = new S3Client({
  region,
  endpoint,
  credentials: { accessKeyId, secretAccessKey },
  forcePathStyle: true,
});

const IMAGES_DIR = path.resolve(__dirname, '../../app/assets/recipe_images');
const FOLDER = 'recipe-images';

async function uploadAll() {
  const files = fs.readdirSync(IMAGES_DIR).filter((f) => /\.(jpg|jpeg|png|webp)$/i.test(f));
  console.log(`📁 ${files.length} imágenes encontradas. Subiendo a ${bucketName}/${FOLDER}...`);

  const results: { file: string; url: string }[] = [];
  let ok = 0;
  let fail = 0;

  for (const file of files) {
    const filePath = path.join(IMAGES_DIR, file);
    const buffer = fs.readFileSync(filePath);
    const ext = path.extname(file).slice(1).toLowerCase();
    const contentType = ext === 'jpg' || ext === 'jpeg' ? 'image/jpeg' : `image/${ext}`;
    const key = `${FOLDER}/${file}`;

    try {
      await client.send(
        new PutObjectCommand({
          Bucket: bucketName,
          Key: key,
          Body: buffer,
          ContentType: contentType,
          ACL: 'public-read',
        }),
      );
      const url = `${publicUrl.replace(/\/$/, '')}/${key}`;
      results.push({ file, url });
      ok++;
      process.stdout.write(`  ✓ ${file}\n`);
    } catch (err) {
      fail++;
      console.error(`  ✗ ${file} — ${(err as Error).message}`);
    }
  }

  // Guardar mapa filename → url para usarlo en el seed
  const mapPath = path.resolve(__dirname, 'recipe-image-urls.json');
  fs.writeFileSync(mapPath, JSON.stringify(Object.fromEntries(results.map((r) => [r.file, r.url])), null, 2));

  console.log(`\n✅ ${ok} subidas, ❌ ${fail} fallidas.`);
  console.log(`📄 Mapa guardado en: ${mapPath}`);
}

uploadAll().catch((err) => {
  console.error(err);
  process.exit(1);
});
