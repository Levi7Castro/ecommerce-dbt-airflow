with source as (
    select
        *
    from {{ ref('bronze_pedidos') }}
)

, renamed as (
    select
        id as pedido_id
        , cliente_id
        , endereco_id
        , data_pedido
        , lower(trim(status)) as status_pedido
    from source
)

select
    *
from renamed
