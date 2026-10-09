// Webhook do Mercado Pago: confere o pagamento direto na API (não confia no
// corpo da notificação) e entrega o que foi pago via
// public.fulfill_payment_from_gateway (só service_role executa).
// Variáveis: MP_ACCESS_TOKEN, SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY.
// Publicar com verify_jwt = false (o Mercado Pago não manda JWT).
import { createClient } from "jsr:@supabase/supabase-js@2";

Deno.serve(async (req) => {
  const url = new URL(req.url);
  const body = await req.json().catch(() => ({}));
  const id = body?.data?.id ?? url.searchParams.get("data.id") ?? url.searchParams.get("id");
  if (!id) return new Response("ignored", { status: 200 });

  const response = await fetch(`https://api.mercadopago.com/v1/payments/${id}`, {
    headers: { Authorization: `Bearer ${Deno.env.get("MP_ACCESS_TOKEN")}` },
  });
  if (!response.ok) return new Response("lookup failed", { status: 502 });
  const mp = await response.json();
  if (mp.status !== "approved" || !mp.external_reference) return new Response("pending", { status: 200 });

  const admin = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const { error } = await admin.rpc("fulfill_payment_from_gateway", {
    p_payment_id: mp.external_reference,
    p_provider: "mercadopago",
    p_provider_ref: String(mp.id),
    p_amount: mp.transaction_amount,
  });
  if (error) return new Response(error.message, { status: 500 });
  return new Response("ok", { status: 200 });
});
