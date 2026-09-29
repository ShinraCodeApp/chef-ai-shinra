import {
  Injectable,
  InternalServerErrorException,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { GetObjectCommand, PutObjectCommand, S3Client } from '@aws-sdk/client-s3';
import { randomUUID } from 'crypto';
import { Readable } from 'stream';

@Injectable()
export class StorageService {
  private readonly logger = new Logger(StorageService.name);
  private readonly client: S3Client | null;
  private readonly bucketName: string | undefined;
  private readonly publicUrl: string | undefined;

  constructor(private readonly configService: ConfigService) {
    const endpoint = this.configService.get<string>('S3_ENDPOINT');
    const accessKeyId = this.configService.get<string>('S3_ACCESS_KEY_ID');
    const secretAccessKey = this.configService.get<string>('S3_SECRET_ACCESS_KEY');
    const region = this.configService.get<string>('S3_REGION') ?? 'us-east-1';
    this.bucketName = this.configService.get<string>('S3_BUCKET_NAME');
    this.publicUrl = this.configService.get<string>('S3_PUBLIC_URL');

    if (endpoint && accessKeyId && secretAccessKey) {
      this.client = new S3Client({
        region,
        endpoint,
        credentials: { accessKeyId, secretAccessKey },
        forcePathStyle: true, // requerido por IDrive e2 y otros S3-compatibles
      });
    } else {
      this.client = null;
      this.logger.warn(
        'Storage S3 no está configurado (faltan S3_* env vars) — la subida de imágenes fallará hasta que se configure.',
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
        'El almacenamiento de imágenes no está configurado en el servidor (faltan S3_* env vars).',
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

  async getObject(key: string): Promise<{ stream: Readable; contentType: string }> {
    if (!this.client || !this.bucketName) {
      throw new InternalServerErrorException('Storage no configurado.');
    }
    try {
      const res = await this.client.send(
        new GetObjectCommand({ Bucket: this.bucketName, Key: key }),
      );
      return {
        stream: res.Body as Readable,
        contentType: res.ContentType ?? 'application/octet-stream',
      };
    } catch {
      throw new NotFoundException('Imagen no encontrada.');
    }
  }
}
