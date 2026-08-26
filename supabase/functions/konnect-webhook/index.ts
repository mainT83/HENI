// Reçoit la confirmation de paiement de Konnect (silentWebhook=true côté
// create-payment, donc appelé serveur-à-serveur, pas par le navigateur du
// client), vérifie le statut réel du paiement auprès de Konnect (jamais se
// fier au seul appel entrant), puis passe l'éleveur en premium.
//
// À configurer comme KONNECT_WEBHOOK_URL dans les secrets, et à déployer
// avec --no-verify-jwt (Konnect n'envoie pas de token Supabase).

import { createClient } from "jsr:@supabase/supabase-js@2";

Deno.serve(async (req) => {
  const url = new URL(req.url);
  const paymentRef = url.searchParams.get("payment_ref");
  if (!paymentRef) {
    return new Response("payment_ref manquant", { status: 400 });
  }

  const statutRes = await fetch(`https://api.konnect.network/api/v2/payments/${paymentRef}`, {
    headers: { "x-api-key": Deno.env.get("KONNECT_API_KEY")! },
  });
  if (!statutRes.ok) {
    return new Response("Impossible de vérifier le paiement auprès de Konnect", { status: 502 });
  }
  const paiement = await statutRes.json();

  const statut = paiement.payment?.status;
  const eleveurId = paiement.payment?.orderId;

  if (statut !== "completed" || !eleveurId) {
    // Paiement pas (encore) confirmé : on ne débloque rien, Konnect
    // rappellera si le statut change.
    return new Response("ok", { status: 200 });
  }

  const supabaseAdmin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { error } = await supabaseAdmin
    .from("profiles")
    .update({ is_premium: true })
    .eq("id", eleveurId);

  if (error) {
    return new Response(`Erreur mise à jour profil: ${error.message}`, { status: 500 });
  }

  return new Response("ok", { status: 200 });
});
