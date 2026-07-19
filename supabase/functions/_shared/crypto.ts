const encoder = new TextEncoder();
const decoder = new TextDecoder();

function fromBase64(base64: string): Uint8Array {
  return Uint8Array.from(atob(base64), (character) => character.charCodeAt(0));
}

function toBase64(bytes: Uint8Array): string {
  return btoa(String.fromCharCode(...bytes));
}

export async function sha256Hex(value: string): Promise<string> {
  const digest = await crypto.subtle.digest('SHA-256', encoder.encode(value));
  return toBase64(new Uint8Array(digest));
}

export async function encryptText(value: string): Promise<string> {
  const keyBase64 = Deno.env.get('INTAKE_ENCRYPTION_KEY_BASE64');
  if (!keyBase64) return value;
  const key = await crypto.subtle.importKey('raw', fromBase64(keyBase64), 'AES-GCM', false, ['encrypt']);
  const iv = crypto.getRandomValues(new Uint8Array(12));
  const ciphertext = new Uint8Array(await crypto.subtle.encrypt({ name: 'AES-GCM', iv }, key, encoder.encode(value)));
  return `${toBase64(iv)}.${toBase64(ciphertext)}`;
}

export async function decryptText(value: string): Promise<string> {
  const keyBase64 = Deno.env.get('INTAKE_ENCRYPTION_KEY_BASE64');
  if (!keyBase64 || !value.includes('.')) return value;
  const [ivPart, payloadPart] = value.split('.');
  const key = await crypto.subtle.importKey('raw', fromBase64(keyBase64), 'AES-GCM', false, ['decrypt']);
  const plain = await crypto.subtle.decrypt({ name: 'AES-GCM', iv: fromBase64(ivPart) }, key, fromBase64(payloadPart));
  return decoder.decode(plain);
}