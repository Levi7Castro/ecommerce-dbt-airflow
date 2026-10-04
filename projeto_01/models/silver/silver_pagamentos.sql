with source as (
    select
        *
    from {{ ref('bronze_pagamentos') }}
)

, renamed as (
    select
        id as pagamento_id
        , pedido_id
        , cast(valor as numeric(12, 2)) as valor_pagamento
        , trim(metodo) as metodo_pagamento
        , lower(trim(status)) as status_pagamento
        , data_pagamento
    from source
)

select
    *
from renamed
