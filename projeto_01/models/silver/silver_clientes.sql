with source as (
    select
        *
    from {{ ref('bronze_clientes') }}
)

, renamed as (
    select
        id as cliente_id
        , trim(nome) as nome_cliente
        , lower(trim(email)) as email
        , trim(telefone) as telefone
        , regexp_replace(telefone, '\D', '', 'g') as telefone_numeros
        , data_registro
    from source
)

select
    *
from renamed
