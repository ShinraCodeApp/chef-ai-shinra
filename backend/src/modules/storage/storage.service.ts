import {
  Injectable,
  InternalServerErrorException,
  Logger,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PutObjectCommand, S3Client } from '@aws-sdk/client-s3';
import { randomUUID } from 'crypto';

@Injectable()
export class StorageService {
  private readonly logger = new Logger(StorageService.name);
  private readonly client: S3Client | null;
  private readonly bucketName: string | undefined;
  private readonly publicUrl: string | undefined;

  constructor(private readonly configService: ConfigService) {
    const accountId = this.configService.get<string>('R2_ACCOUNT_ID');
    const accessKeyId = this.configService.get<string>('R2_ACCESS_KEY_ID');
    const secretAccessKey = this.configService.get<string>(
      'R2_SECRET_ACCESS_KEY',
    );
    this.bucketName = this.configService.get<string>('R2_BUCKET_NAME');
    this.publicUrl = this.configService.get<string>('R2_PUBLIC_URL');

    if (accountId && accessKeyId && secretAccessKey) {
      this.client = new S3Client({
        region: 'auto',
        endpoint: `https://${accountId}.r2.cloudflarestorage.com`,
        credentials: { accessKeyId, secretAccessKey },
      });
    } else {
      this.client = null;
      this.logger.warn(
        'Cloudflare R2 no está configurado (faltan R2_* env vars) — la subida de imágenes fallará hasta que se configure.',
      );
    }
  }

  isConfigured(): boolean {
    return this.client !== null && !!this.bucketName && !!this.publicUrl;
  }

  async upload(
    buffer: Buffer,
    contentType: string,
    folder: string,
  ): Promise<string> {
    if (!this.client || !this.bucketName || !this.publicUrl) {
      throw new InternalServerErrorException(
        'El almacenamiento de imágenes (Cloudflare R2) no está configurado en el servidor.',
      );
    }
    const extension = contentType.split('/')[1] ?? 'bin';
    const key = `${folder}/${randomUUID()}.${extension}`;

    await this.client.send(
      new PutObjectCommand({
        Bucket: this.bucketName,
        Key: key,
        Body: buffer,
        ContentType: contentType,
      }),
    );

    return `${this.publicUrl.replace(/\/$/, '')}/${key}`;
  }
}
