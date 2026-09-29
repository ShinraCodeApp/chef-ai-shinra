import { S3Client, PutBucketPolicyCommand } from '@aws-sdk/client-s3';
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

const policy = {
  Version: '2012-10-17',
  Statement: [
    {
      Sid: 'PublicReadGetObject',
      Effect: 'Allow',
      Principal: '*',
      Action: 's3:GetObject',
      Resource: `arn:aws:s3:::${process.env.S3_BUCKET_NAME}/*`,
    },
  ],
};

async function main() {
  await client.send(
    new PutBucketPolicyCommand({
      Bucket: process.env.S3_BUCKET_NAME!,
      Policy: JSON.stringify(policy),
    }),
  );
  console.log('✅ Bucket policy set: public read enabled');
}

main().catch((err) => {
  console.error('❌ Error:', err.message);
  process.exit(1);
});
