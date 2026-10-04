with source as (
    select
        *
    from {{ ref('bronze_carrinho') }}
)

, renamed as (
    select
        cliente_id
        , produto_id
        , quantidade
        , data_adicionado
    from source
)

select
    *
from renamed
