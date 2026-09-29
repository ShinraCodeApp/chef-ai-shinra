import { S3Client, ListObjectsV2Command, PutObjectAclCommand } from '@aws-sdk/client-s3';
import * as dotenv from 'dotenv';
import * as path from 'path';

dotenv.config({ path: path.join(__dirname, '../.env') });

const client = new S3Client({
  endpoint: process.env.S3_ENDPOINT,
  region: process.env.S3_REGION,
  credentials: {
    accessKeyId: process.env.S3_ACCESS_KEY_ID!,
    secretAccessKey: process.env.S3_SECRET_ACCESS_KEY!,
  },
  forcePathStyle: true,
});

const bucket = process.env.S3_BUCKET_NAME!;

async function main() {
  let continuationToken: string | undefined;
  let total = 0;

  do {
    const list = await client.send(new ListObjectsV2Command({
      Bucket: bucket,
      ContinuationToken: continuationToken,
    }));

    for (const obj of list.Contents ?? []) {
      await client.send(new PutObjectAclCommand({
        Bucket: bucket,
        Key: obj.Key!,
        ACL: 'public-read',
      }));
      total++;
      process.stdout.write(`\r✅ ${total} objetos procesados`);
    }

    continuationToken = list.NextContinuationToken;
  } while (continuationToken);

  console.log(`\n✅ Listo: ${total} objetos con ACL public-read`);
}

main().catch((err) => {
  console.error('\n❌ Error:', err.message);
  process.exit(1);
});
