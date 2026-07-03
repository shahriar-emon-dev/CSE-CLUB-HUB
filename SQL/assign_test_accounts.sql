-- Automatically assign the proper RBAC roles to the 4 designated test accounts

UPDATE public.profiles 
SET role = 'Super Admin', is_approved = true, status = 'active'
WHERE email = 'nokib.10@smuct.ac.bd';

UPDATE public.profiles 
SET role = 'Advisor/Admin', is_approved = true, status = 'active'
WHERE email = 'shad.10@smuct.ac.bd';

UPDATE public.profiles 
SET role = 'Club Executive', is_approved = true, status = 'active'
WHERE email = 'emon.10@smuct.ac.bd';

UPDATE public.profiles 
SET role = 'Regular Student', is_approved = true, status = 'active'
WHERE email = 'ramim.10@smuct.ac.bd';
