const functions = require('firebase-functions');
const admin = require('firebase-admin');
const twilio = require('twilio');

admin.initializeApp();

const TWILIO_SID = process.env.TWILIO_SID || functions.config().twilio.sid;
const TWILIO_TOKEN = process.env.TWILIO_TOKEN || functions.config().twilio.token;
const TWILIO_NUMBER = process.env.TWILIO_NUMBER || functions.config().twilio.number;

const client = twilio(TWILIO_SID, TWILIO_TOKEN);

// Callable function: sendSOS
exports.sendSOS = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Sign in required.');
  }

  const contacts = data.contacts || [];
  const message = (data.message || '').toString().trim();
  if (!message || !Array.isArray(contacts) || contacts.length === 0) {
    throw new functions.https.HttpsError('invalid-argument', 'contacts and message are required');
  }

  // Guardrails for free trial
  const MAX_RECIPIENTS = 3;
  const limited = contacts.slice(0, MAX_RECIPIENTS);

  try {
    const results = [];
    for (const c of limited) {
      const to = (c.phone || '').toString().trim();
      if (!to) continue;
      const res = await client.messages.create({
        from: TWILIO_NUMBER,
        to,
        body: message,
      });
      results.push({ to, sid: res.sid });
    }
    return { ok: true, results };
  } catch (err) {
    console.error('Twilio send error:', err);
    return { ok: false, error: err.message || 'send failed' };
  }
});
