with source as (
    select
        *
    from {{ ref('bronze_produtos') }}
)

, renamed as (
    select
        id as produto_id
        , categoria_id
        , trim(nome) as nome_produto
        , trim(descricao) as descricao_produto
        , trim(marca) as marca
        , cast(preco as numeric(12, 2)) as preco
        , estoque
        , data_cadastro
    from source
)

select
    *
from renamed
