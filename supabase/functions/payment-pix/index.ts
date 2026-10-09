// Gera a cobrança Pix real no Mercado Pago para um pagamento já criado pelo
// RPC create_payment (o valor vem do banco, nunca do app).
// Variáveis: MP_ACCESS_TOKEN, SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY.
// Só é usada quando private.settings.payments_mode = 'live'.
import { createClient } from "jsr:@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  const auth = req.headers.get("Authorization") ?? "";
  const userClient = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!, {
    global: { headers: { Authorization: auth } },
  });
  const { data: { user } } = await userClient.auth.getUser();
  if (!user) return json({ error: "Não autenticado" }, 401);

  const { paymentId } = await req.json();
  const admin = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const { data: payment } = await admin.from("payments").select("*").eq("id", paymentId).eq("payer_id", user.id)
    .eq("status", "pending").single();
  if (!payment) return json({ error: "Pagamento não encontrado." }, 404);

  const response = await fetch("https://api.mercadopago.com/v1/payments", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${Deno.env.get("MP_ACCESS_TOKEN")}`,
      "Content-Type": "application/json",
      "X-Idempotency-Key": payment.id,
    },
    body: JSON.stringify({
      transaction_amount: Number(payment.amount),
      description: payment.description,
      payment_method_id: "pix",
      external_reference: payment.id,
      payer: { email: user.email },
      notification_url: `${Deno.env.get("SUPABASE_URL")}/functions/v1/payment-webhook`,
    }),
  });
  const mp = await response.json();
  if (!response.ok) return json({ error: "Não foi possível gerar o Pix agora." }, 502);

  const pix = mp.point_of_interaction?.transaction_data?.qr_code;
  const { data: updated } = await admin.from("payments")
    .update({ provider: "mercadopago", provider_ref: String(mp.id), pix_code: pix })
    .eq("id", payment.id).select().single();
  return json({ id: updated.id, pixCode: pix, status: updated.status });
});

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: { ...cors, "Content-Type": "application/json" } });
}
