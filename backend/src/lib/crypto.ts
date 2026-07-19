import { createCipheriv, createDecipheriv, createHash, randomBytes } from 'node:crypto';
import { config } from '../config';

function encryptionKey(): Buffer {
  const key = Buffer.from(config.intakeEncryptionKey, 'base64');
  if (key.length !== 32) throw new Error('INTAKE_ENCRYPTION_KEY_BASE64 must decode to exactly 32 bytes');
  return key;
}

export function encryptString(value: string): string {
  const iv = randomBytes(12);
  const cipher = createCipheriv('aes-256-gcm', encryptionKey(), iv);
  const ciphertext = Buffer.concat([cipher.update(value, 'utf8'), cipher.final()]);
  const tag = cipher.getAuthTag();
  return [iv, tag, ciphertext].map((part) => part.toString('base64url')).join('.');
}

export function decryptString(encoded: string): string {
  const [ivText, tagText, ciphertextText] = encoded.split('.');
  if (!ivText || !tagText || !ciphertextText) throw new Error('Malformed encrypted value');
  const decipher = createDecipheriv('aes-256-gcm', encryptionKey(), Buffer.from(ivText, 'base64url'));
  decipher.setAuthTag(Buffer.from(tagText, 'base64url'));
  return Buffer.concat([
    decipher.update(Buffer.from(ciphertextText, 'base64url')),
    decipher.final(),
  ]).toString('utf8');
}

export function sha256(value: string): string {
  return createHash('sha256').update(value).digest('hex');
}
