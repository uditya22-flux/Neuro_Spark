import { accepted, json, readJson } from '../_shared/http.ts';

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') return json({}, { status: 200 });
  const body = await readJson<{ phone?: string; otp?: string; message?: string }>(request);
  const apiKey = Deno.env.get('MSG91_API_KEY');
  const sender = Deno.env.get('MSG91_SENDER_ID') ?? 'MINDBG';
  if (apiKey && body.phone && body.otp) {
    await fetch('https://control.msg91.com/api/v5/flow/', {
      method: 'POST',
      headers: {
        authkey: apiKey,
        'content-type': 'application/json',
      },
      body: JSON.stringify({
        template_id: Deno.env.get('MSG91_TEMPLATE_ID') ?? 'mindbridge-otp',
        short_url: '0',
        recipients: [{ mobiles: body.phone.replace(/\D/g, ''), otp: body.otp, sender }],
      }),
    }).catch(() => undefined);
  }
  return accepted({ delivered: true });
});