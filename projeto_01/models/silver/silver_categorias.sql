with source as (
    select
        *
    from {{ ref('bronze_categorias') }}
)

, renamed as (
    select
        id as categoria_id
        , trim(nome) as nome_categoria
    from source
)

select
    *
from renamed
