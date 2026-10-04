{{
    config(
        tags=['vendas']
    )
}}

-- Grão: 1 linha por item vendido (pedido + produto)
-- Venda = pedido concluído com pagamento pago

with pedidos as (
    select
        *
    from {{ ref('silver_pedidos') }}
    where status_pedido = 'concluído'
)

, pagamentos as (
    select
        *
    from {{ ref('silver_pagamentos') }}
    where status_pagamento = 'pago'
)

, itens_pedidos as (
    select
        *
    from {{ ref('silver_itens_pedidos') }}
)

, clientes as (
    select
        *
    from {{ ref('silver_clientes') }}
)

, produtos as (
    select
        *
    from {{ ref('silver_produtos') }}
)

, categorias as (
    select
        *
    from {{ ref('silver_categorias') }}
)

, joined as (
    select
        itens_pedidos.item_pedido_id
        , pedidos.pedido_id
        , pedidos.data_pedido
        , pedidos.cliente_id
        , clientes.nome_cliente
        , clientes.email
        , itens_pedidos.produto_id
        , produtos.nome_produto
        , produtos.marca
        , produtos.categoria_id
        , categorias.nome_categoria
        , pagamentos.pagamento_id
        , pagamentos.metodo_pagamento
        , pagamentos.data_pagamento
        , itens_pedidos.quantidade
        , itens_pedidos.preco_unitario
        , itens_pedidos.subtotal as valor_venda
    from pedidos
    inner join pagamentos on pedidos.pedido_id = pagamentos.pedido_id
    inner join itens_pedidos on pedidos.pedido_id = itens_pedidos.pedido_id
    left join clientes on pedidos.cliente_id = clientes.cliente_id
    left join produtos on itens_pedidos.produto_id = produtos.produto_id
    left join categorias on produtos.categoria_id = categorias.categoria_id
)

select
    *
from joined
