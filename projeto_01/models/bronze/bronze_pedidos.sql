{{ config(
    materialized='incremental',
    unique_key='id'
) }}

with source as (
    select
    *
    from {{ source('ecomerce','pedidos') }}
)

select
*
from source

{% if is_incremental() %}
    where data_pedido >= (select max(data_pedido) from {{ this }})
{% endif %}