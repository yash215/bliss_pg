create user hkuser with password 'hkuser@dm1n';
create schema hkuser;
create role hkuserrole;
grant connect on database bliss to hkuserrole;
grant all privileges on all tables in schema hkuser to hkuserrole;
grant all privileges on all sequences in schema hkuser to hkuserrole;
grant all privileges on all functions in schema hkuser to hkuserrole;
grant create on schema hkuser to hkuserrole;
grant usage on schema hkuser to hkuserrole;
grant hkuserrole to hkuser;

grant hkuser to bliss_admin;

create user dfuser with password 'dfuser@dm1n';
create schema dfuser;
create role dfuserrole;
grant connect on database bliss to dfuserrole;
grant all privileges on all tables in schema dfuser to dfuserrole;
grant all privileges on all sequences in schema dfuser to dfuserrole;
grant all privileges on all functions in schema dfuser to dfuserrole;
grant create on schema dfuser to dfuserrole;
grant usage on schema dfuser to dfuserrole;
grant dfuserrole to dfuser;

grant dfuser to bliss_admin;

create user sguser with password 'sguser@dm1n';
create schema sguser;
create role sguserrole;
grant connect on database bliss to sguserrole;
grant all privileges on all tables in schema sguser to sguserrole;
grant all privileges on all sequences in schema sguser to sguserrole;
grant all privileges on all functions in schema sguser to sguserrole;
grant create on schema sguser to sguserrole;
grant usage on schema sguser to sguserrole;
grant sguserrole to sguser;

grant sguser to bliss_admin;



