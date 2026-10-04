with source as (
    select
        *
    from {{ ref('bronze_itens_pedidos') }}
)

, renamed as (
    select
        pedido_id || '-' || produto_id as item_pedido_id
        , pedido_id
        , produto_id
        , quantidade
        , cast(preco_unitario as numeric(12, 2)) as preco_unitario
        , cast(subtotal as numeric(12, 2)) as subtotal
    from source
)

select
    *
from renamed
