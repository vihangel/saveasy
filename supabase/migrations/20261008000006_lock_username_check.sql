-- O @ é escolhido depois do login (completar perfil): a checagem não precisa
-- ficar aberta para anônimos (advisor 0028).
revoke execute on function public.is_username_available(text) from anon;
