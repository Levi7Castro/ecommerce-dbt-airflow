with source as (
    select
        *
    from {{ ref('bronze_avaliacoes') }}
)

, renamed as (
    select
        cliente_id
        , produto_id
        , nota
        , trim(comentario) as comentario
        , data_avaliacao
    from source
)

select
    *
from renamed
